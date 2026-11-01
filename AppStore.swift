import Foundation
import CryptoKit

final class AppStore: ObservableObject {
    static let maxPerTransaction = 25_000.0
    static let maxBalance = 200_000.0

    @Published private(set) var account: UserAccount?
    @Published private(set) var transactions: [Transaction] = []
    @Published private(set) var contacts: [Contact] = []
    @Published private(set) var isLoggedIn = false
    @Published var hideBalance = false {
        didSet { defaults.set(hideBalance, forKey: Key.hide) }
    }

    private let service: PaymentService
    private let defaults = UserDefaults.standard

    private enum Key {
        static let account = "pt.account"
        static let transactions = "pt.transactions"
        static let contacts = "pt.contacts"
        static let hide = "pt.hideBalance"
    }

    init(service: PaymentService) {
        self.service = service
        let decoder = JSONDecoder()
        if let data = defaults.data(forKey: Key.account),
           let value = try? decoder.decode(UserAccount.self, from: data) {
            account = value
        }
        if let data = defaults.data(forKey: Key.transactions),
           let value = try? decoder.decode([Transaction].self, from: data) {
            transactions = value
        }
        if let data = defaults.data(forKey: Key.contacts),
           let value = try? decoder.decode([Contact].self, from: data) {
            contacts = value
        }
        hideBalance = defaults.bool(forKey: Key.hide)
    }

    // MARK: Derived

    var balance: Double { account?.balance ?? 0 }

    var spentThisMonth: Double {
        let calendar = Calendar.current
        return transactions
            .filter { !$0.type.isCredit && calendar.isDate($0.date, equalTo: Date(), toGranularity: .month) }
            .reduce(0) { $0 + $1.total }
    }

    // MARK: Account

    private static func hash(_ pin: String, salt: String) -> String {
        let digest = SHA256.hash(data: Data((salt + pin).utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    func register(name: String, phone: String, pin: String) {
        account = UserAccount(name: name, phone: phone, pinHash: Self.hash(pin, salt: phone), balance: 0)
        transactions = []
        contacts = []
        persist()
        isLoggedIn = true
    }

    func verify(pin: String) -> Bool {
        guard let account else { return false }
        return account.pinHash == Self.hash(pin, salt: account.phone)
    }

    func login(pin: String) -> Bool {
        guard verify(pin: pin) else { return false }
        isLoggedIn = true
        return true
    }

    func logout() {
        isLoggedIn = false
    }

    func changePin(old: String, new: String) -> Bool {
        guard verify(pin: old), var current = account else { return false }
        current.pinHash = Self.hash(new, salt: current.phone)
        account = current
        persist()
        return true
    }

    func resetEverything() {
        account = nil
        transactions = []
        contacts = []
        isLoggedIn = false
        defaults.removeObject(forKey: Key.account)
        defaults.removeObject(forKey: Key.transactions)
        defaults.removeObject(forKey: Key.contacts)
    }

    // MARK: Contacts

    /// Error message wapas karta hai, kamyab ho to nil.
    func addContact(name: String, phone: String) -> String? {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard trimmed.count >= 2 else { return "Naam likhein." }
        guard Validators.isValidPhone(phone) else { return "Number 03XXXXXXXXX format mein likhein." }
        guard !contacts.contains(where: { $0.phone == phone }) else { return "Ye number pehle se saved hai." }
        contacts.append(Contact(name: trimmed, phone: phone))
        contacts.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        persist()
        return nil
    }

    func deleteContacts(at offsets: IndexSet) {
        contacts.remove(atOffsets: offsets)
        persist()
    }

    // MARK: Payments

    private func checkAmount(_ amount: Double) throws {
        guard amount >= 1 else { throw PaymentError.invalidAmount }
        guard amount <= Self.maxPerTransaction else { throw PaymentError.limitExceeded(Self.maxPerTransaction) }
    }

    @MainActor
    func sendMoney(wallet: Wallet, phone: String, name: String, amount: Double, note: String) async throws -> Transaction {
        guard let current = account else { throw PaymentError.notLoggedIn }
        try checkAmount(amount)
        guard Validators.isValidPhone(phone) else { throw PaymentError.invalidNumber }
        if wallet == .pakTransfer && phone == current.phone { throw PaymentError.selfTransfer }
        guard current.balance >= amount + FeePolicy.fee(for: wallet) else { throw PaymentError.insufficientBalance }

        let result = try await service.sendMoney(from: current.phone, to: phone, wallet: wallet, amount: amount, note: note)
        return record(type: .sent, amount: amount, fee: result.fee,
                      title: name.isEmpty ? phone : name,
                      detail: "\(phone) • \(wallet.rawValue)",
                      note: note, reference: result.reference)
    }

    @MainActor
    func mobileLoad(network: Telco, number: String, amount: Double) async throws -> Transaction {
        guard let current = account else { throw PaymentError.notLoggedIn }
        try checkAmount(amount)
        guard Validators.isValidPhone(number) else { throw PaymentError.invalidNumber }
        guard current.balance >= amount else { throw PaymentError.insufficientBalance }

        let result = try await service.mobileLoad(from: current.phone, network: network, number: number, amount: amount)
        return record(type: .mobileLoad, amount: amount, fee: result.fee,
                      title: "\(network.rawValue) Load",
                      detail: number, note: "", reference: result.reference)
    }

    @MainActor
    func payBill(category: BillCategory, company: String, consumerNumber: String, amount: Double) async throws -> Transaction {
        guard let current = account else { throw PaymentError.notLoggedIn }
        try checkAmount(amount)
        guard current.balance >= amount else { throw PaymentError.insufficientBalance }

        let result = try await service.payBill(from: current.phone, company: company, consumerNumber: consumerNumber, amount: amount)
        return record(type: .billPayment, amount: amount, fee: result.fee,
                      title: "\(company) \(category.rawValue) Bill",
                      detail: "Consumer #\(consumerNumber)", note: "", reference: result.reference)
    }

    @MainActor
    func addMoney(method: FundingMethod, amount: Double) async throws -> Transaction {
        guard let current = account else { throw PaymentError.notLoggedIn }
        try checkAmount(amount)
        guard current.balance + amount <= Self.maxBalance else { throw PaymentError.balanceLimit(Self.maxBalance) }

        let result = try await service.addMoney(to: current.phone, method: method, amount: amount)
        return record(type: .addMoney, amount: amount, fee: result.fee,
                      title: "Wallet Top-up",
                      detail: method.rawValue, note: "", reference: result.reference)
    }

    @MainActor
    private func record(type: TransactionType, amount: Double, fee: Double,
                        title: String, detail: String, note: String, reference: String) -> Transaction {
        let tx = Transaction(type: type, amount: amount, fee: fee, title: title,
                             detail: detail, note: note, date: Date(), reference: reference)
        if var current = account {
            current.balance += type.isCredit ? amount : -(amount + fee)
            account = current
        }
        transactions.insert(tx, at: 0)
        persist()
        return tx
    }

    // MARK: Storage

    private func persist() {
        let encoder = JSONEncoder()
        if let account, let data = try? encoder.encode(account) { defaults.set(data, forKey: Key.account) }
        if let data = try? encoder.encode(transactions) { defaults.set(data, forKey: Key.transactions) }
        if let data = try? encoder.encode(contacts) { defaults.set(data, forKey: Key.contacts) }
    }
}
