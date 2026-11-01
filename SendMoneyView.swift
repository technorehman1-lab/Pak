import SwiftUI

struct SendMoneyView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var wallet: Wallet = .pakTransfer
    @State private var phone: String
    @State private var name: String
    @State private var amountText = ""
    @State private var note = ""
    @State private var formError: String?
    @State private var showConfirm = false

    init(phone: String = "", name: String = "") {
        _phone = State(initialValue: phone)
        _name = State(initialValue: name)
    }

    private var amount: Double { Double(amountText) ?? 0 }
    private var fee: Double { FeePolicy.fee(for: wallet) }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Card {
                    Text("Available balance").font(.footnote).foregroundStyle(Color.secondary)
                    Text(store.balance.rs).font(.title2.bold())
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Kis wallet mein bhejna hai").font(.footnote).foregroundStyle(Color.secondary)
                    Picker("Wallet", selection: $wallet) {
                        ForEach(Wallet.allCases) { item in
                            Text(item.rawValue).tag(item)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                FormField(title: "Receiver ka number", placeholder: "03XXXXXXXXX", text: $phone, kind: .digits, maxLength: 11)

                if !store.contacts.isEmpty {
                    Menu {
                        ForEach(store.contacts) { contact in
                            Button("\(contact.name) • \(contact.phone)") {
                                phone = contact.phone
                                name = contact.name
                            }
                        }
                    } label: {
                        Label("Saved contacts se chunein", systemImage: "person.crop.circle.badge.plus")
                            .font(.subheadline)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                FormField(title: "Naam (optional)", placeholder: "Receiver ka naam", text: $name)
                FormField(title: "Amount (Rs)", placeholder: "0", text: $amountText, kind: .digits, maxLength: 6)
                AmountChips(values: [500, 1000, 2000, 5000], text: $amountText)
                FormField(title: "Note (optional)", placeholder: "Kis liye?", text: $note)

                Card {
                    DetailRow(label: "Amount", value: amount.rs)
                    DetailRow(label: "Fee", value: fee == 0 ? "Free" : fee.rs)
                    Divider()
                    DetailRow(label: "Kul", value: (amount + fee).rs)
                }

                if let formError {
                    Text(formError).font(.footnote).foregroundStyle(Color.red)
                }

                PrimaryButton(title: "Aage barhein") { validate() }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Send Money")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showConfirm) {
            ConfirmPaymentSheet(
                title: "Confirm Transfer",
                rows: confirmRows,
                total: amount + fee,
                action: {
                    try await store.sendMoney(wallet: wallet, phone: phone, name: name.trimmingCharacters(in: .whitespaces),
                                              amount: amount, note: note.trimmingCharacters(in: .whitespaces))
                },
                onFinish: { dismiss() }
            )
        }
    }

    private var confirmRows: [(String, String)] {
        var rows: [(String, String)] = [("Wallet", wallet.rawValue), ("Number", phone)]
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty { rows.append(("Naam", trimmed)) }
        rows.append(("Amount", amount.rs))
        rows.append(("Fee", fee == 0 ? "Free" : fee.rs))
        return rows
    }

    private func validate() {
        guard Validators.isValidPhone(phone) else { formError = "Number 03XXXXXXXXX format mein likhein."; return }
        if wallet == .pakTransfer && phone == store.account?.phone {
            formError = "Apne aap ko paisay nahi bhej sakte."
            return
        }
        guard amount >= 1 else { formError = "Amount likhein."; return }
        guard amount <= AppStore.maxPerTransaction else {
            formError = "Ek transaction ki limit \(AppStore.maxPerTransaction.rs) hai."
            return
        }
        guard store.balance >= amount + fee else { formError = "Balance kam hai. Pehle Add Money karein."; return }
        formError = nil
        showConfirm = true
    }
}
