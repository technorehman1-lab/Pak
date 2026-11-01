import SwiftUI

struct MobileLoadView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var network: Telco = .jazz
    @State private var number = ""
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
                    Text("Network").font(.footnote).foregroundStyle(Color.secondary)
                    Picker("Network", selection: $network) {
                        ForEach(Telco.allCases) { item in
                            Text(item.rawValue).tag(item)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                FormField(title: "Mobile number", placeholder: "03XXXXXXXXX", text: $number, kind: .digits, maxLength: 11)

                if let own = store.account?.phone {
                    Button {
                        number = own
                    } label: {
                        Label("Apna number istemal karein", systemImage: "person.fill")
                            .font(.subheadline)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                FormField(title: "Load amount (Rs)", placeholder: "0", text: $amountText, kind: .digits, maxLength: 5)
                AmountChips(values: [50, 100, 200, 500, 1000], text: $amountText)

                if let formError {
                    Text(formError).font(.footnote).foregroundStyle(Color.red)
                }

                PrimaryButton(title: "Aage barhein") { validate() }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Mobile Load")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showConfirm) {
            ConfirmPaymentSheet(
                title: "Confirm Load",
                rows: [("Network", network.rawValue), ("Number", number), ("Amount", amount.rs), ("Fee", "Free")],
                total: amount,
                action: { try await store.mobileLoad(network: network, number: number, amount: amount) },
                onFinish: { dismiss() }
            )
        }
    }

    private func validate() {
        guard Validators.isValidPhone(number) else { formError = "Number 03XXXXXXXXX format mein likhein."; return }
        guard amount >= 10 else { formError = "Kam az kam Rs 10 ka load hota hai."; return }
        guard amount <= 5000 else { formError = "Ek baar mein zyada se zyada Rs 5,000 ka load."; return }
        guard store.balance >= amount else { formError = "Balance kam hai. Pehle Add Money karein."; return }
        formError = nil
        showConfirm = true
    }
}
