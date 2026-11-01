import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var store: AppStore
    @State private var showChangePin = false
    @State private var showLogout = false
    @State private var showReset = false

    private var initials: String {
        let parts = (store.account?.name ?? "").split(separator: " ")
        return parts.prefix(2).compactMap { $0.first }.map { String($0) }.joined().uppercased()
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle().fill(Color.brand)
                            Text(initials).font(.title2.bold()).foregroundStyle(Color.white)
                        }
                        .frame(width: 56, height: 56)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(store.account?.name ?? "").font(.headline)
                            Text(store.account?.phone ?? "").foregroundStyle(Color.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Security") {
                    Button {
                        showChangePin = true
                    } label: {
                        Label("PIN badlein", systemImage: "key.fill")
                    }
                    Toggle(isOn: $store.hideBalance) {
                        Label("Balance chupayein", systemImage: "eye.slash.fill")
                    }
                }

                Section("Limits") {
                    LabeledContent("Ek transaction", value: AppStore.maxPerTransaction.rs)
                    LabeledContent("Wallet balance", value: AppStore.maxBalance.rs)
                }

                Section("Fees (demo)") {
                    LabeledContent("Pak Transfer ko", value: "Free")
                    LabeledContent("JazzCash / Easypaisa ko", value: FeePolicy.otherWalletFee.rs)
                    LabeledContent("Load / Bills / Top-up", value: "Free")
                }

                Section {
                    Button("Logout") { showLogout = true }
                    Button("Account delete karein", role: .destructive) { showReset = true }
                }

                Section {
                    LabeledContent("Version", value: "1.0 (demo)")
                } footer: {
                    Text("Demo mode: koi asli paisa nahi hilta.")
                }
            }
            .navigationTitle("Profile")
            .sheet(isPresented: $showChangePin) { ChangePinSheet() }
            .confirmationDialog("Logout karna hai?", isPresented: $showLogout, titleVisibility: .visible) {
                Button("Logout", role: .destructive) { store.logout() }
                Button("Cancel", role: .cancel) {}
            }
            .confirmationDialog("Account delete karna hai?", isPresented: $showReset, titleVisibility: .visible) {
                Button("Delete karein", role: .destructive) { store.resetEverything() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Balance, contacts aur history sab mit jayegi.")
            }
        }
    }
}

struct ChangePinSheet: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var oldPin = ""
    @State private var newPin = ""
    @State private var confirmPin = ""
    @State private var error: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Purana PIN").font(.footnote).foregroundStyle(Color.secondary)
                        PinField(title: "Purana PIN", text: $oldPin)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Naya PIN").font(.footnote).foregroundStyle(Color.secondary)
                        PinField(title: "Naya PIN", text: $newPin)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Naya PIN dobara").font(.footnote).foregroundStyle(Color.secondary)
                        PinField(title: "Naya PIN confirm", text: $confirmPin)
                    }
                    if let error {
                        Text(error).font(.footnote).foregroundStyle(Color.red)
                    }
                    PrimaryButton(title: "PIN badlein") { submit() }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("PIN badlein")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
    }

    private func submit() {
        guard Validators.isValidPin(newPin) else { error = "Naya PIN 4 digits ka ho."; return }
        guard newPin == confirmPin else { error = "Naye PIN match nahi karte."; return }
        guard store.changePin(old: oldPin, new: newPin) else { error = "Purana PIN ghalat hai."; return }
        dismiss()
    }
}
