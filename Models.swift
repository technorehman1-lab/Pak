import Foundation

// MARK: - Transactions

enum TransactionType: String, Codable {
    case sent, received, mobileLoad, billPayment, addMoney

    var label: String {
        switch self {
        case .sent: return "Money Sent"
        case .received: return "Money Received"
        case .mobileLoad: return "Mobile Load"
        case .billPayment: return "Bill Payment"
        case .addMoney: return "Money Added"
        }
    }

    var successText: String {
        switch self {
        case .sent: return "Transfer kamyab"
        case .received: return "Paisay mil gaye"
        case .mobileLoad: return "Load kamyab"
        case .billPayment: return "Bill ada ho gaya"
        case .addMoney: return "Paisay add ho gaye"
        }
    }

    var icon: String {
        switch self {
        case .sent: return "arrow.up.right"
        case .received: return "arrow.down.left"
        case .mobileLoad: return "iphone"
        case .billPayment: return "bolt.fill"
        case .addMoney: return "plus"
        }
    }

    var isCredit: Bool { self == .received || self == .addMoney }
}

struct Transaction: Identifiable, Codable, Hashable {
    var id = UUID()
    let type: TransactionType
    let amount: Double
    let fee: Double
    let title: String
    let detail: String
    let note: String
    let date: Date
    let reference: String

    var total: Double { type.isCredit ? amount : amount + fee }

    var shareText: String {
        """
        Pak Transfer Receipt
        \(type.label): \(amount.rs)
        \(title) • \(detail)
        Ref: \(reference)
        \(date.formatted(date: .abbreviated, time: .shortened))
        """
    }
}

// MARK: - Account & contacts

struct UserAccount: Codable {
    var name: String
    var phone: String
    var pinHash: String
    var balance: Double
}

struct Contact: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var phone: String
}

// MARK: - Options

enum Wallet: String, CaseIterable, Identifiable, Codable {
    case pakTransfer = "Pak Transfer"
    case jazzCash = "JazzCash"
    case easypaisa = "Easypaisa"

    var id: String { rawValue }
}

enum Telco: String, CaseIterable, Identifiable {
    case jazz = "Jazz"
    case zong = "Zong"
    case telenor = "Telenor"
    case ufone = "Ufone"

    var id: String { rawValue }
}

enum BillCategory: String, CaseIterable, Identifiable {
    case electricity = "Bijli"
    case gas = "Gas"
    case water = "Pani"
    case internet = "Internet"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .electricity: return "bolt.fill"
        case .gas: return "flame.fill"
        case .water: return "drop.fill"
        case .internet: return "wifi"
        }
    }

    var companies: [String] {
        switch self {
        case .electricity: return ["LESCO", "IESCO", "FESCO", "GEPCO", "MEPCO", "PESCO", "K-Electric"]
        case .gas: return ["SNGPL", "SSGC"]
        case .water: return ["WASA Lahore", "WASA Rawalpindi", "KWSB Karachi"]
        case .internet: return ["PTCL", "StormFiber", "Nayatel"]
        }
    }
}

enum FundingMethod: String, CaseIterable, Identifiable {
    case card = "Debit / Credit Card"
    case bank = "Bank Account"
    case agent = "Agent (Cash)"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .card: return "creditcard.fill"
        case .bank: return "building.columns.fill"
        case .agent: return "banknote.fill"
        }
    }
}

// MARK: - Rules

enum FeePolicy {
    // Demo fees. Asli fees apni API/backend se aayengi.
    static let otherWalletFee = 10.0

    static func fee(for wallet: Wallet) -> Double {
        wallet == .pakTransfer ? 0 : otherWalletFee
    }
}

enum Validators {
    static func isValidPhone(_ s: String) -> Bool {
        s.count == 11 && s.hasPrefix("03") && s.allSatisfy { $0.isNumber }
    }

    static func isValidPin(_ s: String) -> Bool {
        s.count == 4 && s.allSatisfy { $0.isNumber }
    }
}

enum Reference {
    static func make() -> String {
        "PT" + String((0..<10).map { _ in "0123456789".randomElement()! })
    }
}
