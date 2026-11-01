import SwiftUI

struct BillPaymentView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var category: BillCategory = .electricity
    @State private var company = BillCategory.electricity.companies[0]
    @State private var consumerNumber = ""
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

                VStack(alignment: .leading, spacing: 6) {
                    Text("Bill ki qism").font(.footnote).foregroundStyle(Color.secondary)
                    Picker("Qism", selection: $category) {
                        ForEach(BillCategory.allCases) { item in
                            Text(item.rawValue).tag(item)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .onChange(of: category) { _, newValue in
                    company = newValue.companies[0]
                }

                HStack {
                    Label("Company", systemImage: category.icon)
                    Spacer()
                    Picker("Company", selection: $company) {
                        ForEach(category.companies, id: \.self) { item in
                            Text(item).tag(item)
                        }
                    }
                    .pickerStyle(.menu)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                FormField(title: "Consumer / Reference number", placeholder: "Bill par likha number",
                          text: $consumerNumber, kind: .digits, maxLength: 14)
                FormField(title: "Bill amount (Rs)", placeholder: "0", text: $amountText, kind: .digits, maxLength: 6)

                if let formError {
                    Text(formError).font(.footnote).foregroundStyle(Color.red)
                }

                PrimaryButton(title: "Aage barhein") { validate() }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Bill Payment")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showConfirm) {
            ConfirmPaymentSheet(
                title: "Confirm Bill",
                rows: [("Qism", category.rawValue), ("Company", company),
                       ("Consumer #", consumerNumber), ("Amount", amount.rs), ("Fee", "Free")],
                total: amount,
                action: {
                    try await store.payBill(category: category, company: company,
                                            consumerNumber: consumerNumber, amount: amount)
                },
                onFinish: { dismiss() }
            )
        }
    }

    private func validate() {
        guard consumerNumber.count >= 8 else { formError = "Consumer number kam az kam 8 digits ka ho."; return }
        guard amount >= 1 else { formError = "Bill ki amount likhein."; return }
        guard amount <= AppStore.maxPerTransaction else {
            formError = "Ek transaction ki limit \(AppStore.maxPerTransaction.rs) hai."
            return
        }
        guard store.balance >= amount else { formError = "Balance kam hai. Pehle Add Money karein."; return }
        formError = nil
        showConfirm = true
    }
}
