import SwiftUI

/// Har payment ke liye PIN confirmation + receipt, ek hi sheet mein.
struct ConfirmPaymentSheet: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss

    let title: String
    let rows: [(String, String)]
    let total: Double
    let action: () async throws -> Transaction
    let onFinish: () -> Void

    @State private var pin = ""
    @State private var errorText: String?
    @State private var busy = false
    @State private var attempts = 0
    @State private var receipt: Transaction?

    var body: some View {
        NavigationStack {
            Group {
                if let receipt {
                    ReceiptView(tx: receipt)
                } else {
                    form
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(receipt == nil ? title : "Receipt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if receipt == nil {
                        Button("Cancel") { dismiss() }.disabled(busy)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if receipt != nil {
                        Button("Done") {
                            dismiss()
                            onFinish()
                        }
                    }
                }
            }
        }
        .interactiveDismissDisabled(busy || receipt != nil)
    }

    private var form: some View {
        ScrollView {
            VStack(spacing: 16) {
                Card {
                    ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                        DetailRow(label: row.0, value: row.1)
                    }
                    Divider()
                    HStack {
                        Text("Kul rakam").fontWeight(.semibold)
                        Spacer()
                        Text(total.rs).font(.title3.bold()).foregroundStyle(Color.brand)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Confirm karne ke liye PIN likhein")
                        .font(.footnote)
                        .foregroundStyle(Color.secondary)
                    PinField(title: "4-digit PIN", text: $pin)
                }

                if let errorText {
                    Text(errorText).font(.footnote).foregroundStyle(Color.red)
                }

                PrimaryButton(title: "Confirm & Pay", isLoading: busy, disabled: pin.count != 4) {
                    confirm()
                }
            }
            .padding()
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private func confirm() {
        guard store.verify(pin: pin) else {
            attempts += 1
            pin = ""
            if attempts >= 3 {
                dismiss()
                store.logout()
            } else {
                errorText = "PIN ghalat hai (\(3 - attempts) koshishen baqi)."
            }
            return
        }
        errorText = nil
        busy = true
        Task { @MainActor in
            do {
                receipt = try await action()
            } catch {
                errorText = error.localizedDescription
            }
            busy = false
        }
    }
}

struct ReceiptView: View {
    let tx: Transaction

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(Color.brand)
                    .padding(.top, 8)
                Text(tx.type.successText).font(.title3.bold())
                Text(tx.amount.rs).font(.system(size: 36, weight: .bold))

                Card {
                    DetailRow(label: tx.type.isCredit ? "Source" : "Receiver", value: tx.title)
                    DetailRow(label: "Detail", value: tx.detail)
                    if !tx.note.isEmpty {
                        DetailRow(label: "Note", value: tx.note)
                    }
                    DetailRow(label: "Fee", value: tx.fee.rs)
                    DetailRow(label: "Kul", value: tx.total.rs)
                    Divider()
                    DetailRow(label: "Reference", value: tx.reference)
                    DetailRow(label: "Waqt", value: tx.date.formatted(date: .abbreviated, time: .shortened))
                }

                ShareLink(item: tx.shareText) {
                    Label("Receipt share karein", systemImage: "square.and.arrow.up")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.brand.opacity(0.12))
                        .foregroundStyle(Color.brand)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding()
        }
    }
}

struct ReceiptScreen: View {
    let tx: Transaction

    var body: some View {
        ReceiptView(tx: tx)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Receipt")
            .navigationBarTitleDisplayMode(.inline)
    }
}
