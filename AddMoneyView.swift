import SwiftUI

struct AddMoneyView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var method: FundingMethod = .card
    @State private var amountText = ""
    @State private var formError: String?
    @State private var showConfirm = false

    private var amount: Double { Double(amountText) ?? 0 }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Card {
                    Text("Available balance").font(.footnote).foregroundStyle(Color.secondary)
                    Text(store.balance.rs).font(.title2.bold())
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Paisay kahan se add karne hain").font(.footnote).foregroundStyle(Color.secondary)
                    ForEach(FundingMethod.allCases) { item in
                        Button {
                            method = item
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: item.icon).frame(width: 28).foregroundStyle(Color.brand)
                                Text(item.rawValue).foregroundStyle(Color.primary)
                                Spacer()
                                Image(systemName: method == item ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(method == item ? Color.brand : Color.secondary)
                            }
                            .padding(14)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }

                FormField(title: "Amount (Rs)", placeholder: "0", text: $amountText, kind: .digits, maxLength: 6)
                AmountChips(values: [500, 1000, 2000, 5000, 10000], text: $amountText)

                if let formError {
                    Text(formError).font(.footnote).foregroundStyle(Color.red)
                }

                PrimaryButton(title: "Aage barhein") { validate() }

                Text("Demo version: yahan se asli bank/card se paisa nahi katta.")
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Add Money")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showConfirm) {
            ConfirmPaymentSheet(
                title: "Confirm Top-up",
                rows: [("Zariya", method.rawValue), ("Amount", amount.rs), ("Fee", "Free")],
                total: amount,
                action: { try await store.addMoney(method: method, amount: amount) },
                onFinish: { dismiss() }
            )
        }
    }

    private func validate() {
        guard amount >= 1 else { formError = "Amount likhein."; return }
        guard amount <= AppStore.maxPerTransaction else {
            formError = "Ek baar mein \(AppStore.maxPerTransaction.rs) tak add ho sakte hain."
            return
        }
        guard store.balance + amount <= AppStore.maxBalance else {
            formError = "Wallet mein \(AppStore.maxBalance.rs) se zyada balance nahi ho sakta."
            return
        }
        formError = nil
        showConfirm = true
    }
}
