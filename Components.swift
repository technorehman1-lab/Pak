import SwiftUI

extension Color {
    static let brand = Color(red: 0.05, green: 0.50, blue: 0.40)
    static let brandDark = Color(red: 0.02, green: 0.30, blue: 0.26)
}

extension Double {
    var rs: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return "Rs " + (formatter.string(from: NSNumber(value: self)) ?? String(self))
    }
}

struct Card<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) { content }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(label).foregroundStyle(Color.secondary)
            Spacer(minLength: 16)
            Text(value).fontWeight(.medium).multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
    }
}

struct PrimaryButton: View {
    let title: String
    var isLoading = false
    var disabled = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading { ProgressView().tint(.white) }
                Text(title).fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(disabled ? Color.gray.opacity(0.4) : Color.brand)
            .foregroundStyle(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(disabled || isLoading)
    }
}

struct FormField: View {
    enum Kind { case text, digits }

    let title: String
    let placeholder: String
    @Binding var text: String
    var kind: Kind = .text
    var maxLength: Int? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.footnote).foregroundStyle(Color.secondary)
            TextField(placeholder, text: $text)
                .keyboardType(kind == .digits ? .numberPad : .default)
                .padding(14)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .onChange(of: text) { _, newValue in
                    var value = newValue
                    if kind == .digits { value = value.filter { $0.isNumber } }
                    if let maxLength, value.count > maxLength { value = String(value.prefix(maxLength)) }
                    if value != text { text = value }
                }
        }
    }
}

struct PinField: View {
    let title: String
    @Binding var text: String

    var body: some View {
        SecureField(title, text: $text)
            .keyboardType(.numberPad)
            .textContentType(.oneTimeCode)
            .padding(14)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .onChange(of: text) { _, newValue in
                let value = String(newValue.filter { $0.isNumber }.prefix(4))
                if value != text { text = value }
            }
    }
}

struct AmountChips: View {
    let values: [Int]
    @Binding var text: String

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(values, id: \.self) { value in
                    Button {
                        text = String(value)
                    } label: {
                        Text(Double(value).rs)
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.brand.opacity(0.12))
                            .foregroundStyle(Color.brand)
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }
}

struct TransactionRow: View {
    let tx: Transaction

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill((tx.type.isCredit ? Color.green : Color.brand).opacity(0.15))
                Image(systemName: tx.type.icon)
                    .foregroundStyle(tx.type.isCredit ? Color.green : Color.brand)
            }
            .frame(width: 42, height: 42)

            VStack(alignment: .leading, spacing: 2) {
                Text(tx.title).fontWeight(.medium).lineLimit(1)
                Text(tx.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
            }
            Spacer()
            Text((tx.type.isCredit ? "+" : "-") + tx.amount.rs)
                .fontWeight(.semibold)
                .foregroundStyle(tx.type.isCredit ? Color.green : Color.primary)
        }
        .contentShape(Rectangle())
    }
}

struct ActionTile: View {
    let title: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 16).fill(Color.brand.opacity(0.12))
                Image(systemName: icon).font(.title2).foregroundStyle(Color.brand)
            }
            .frame(width: 58, height: 58)
            Text(title)
                .font(.caption)
                .foregroundStyle(Color.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
    }
}
