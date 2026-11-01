import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var store: AppStore
    @State private var name = ""
    @State private var phone = ""
    @State private var pin = ""
    @State private var confirmPin = ""
    @State private var error: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Image(systemName: "paperplane.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(Color.brand)
                        .padding(.top, 20)
                    Text("Pak Transfer").font(.largeTitle.bold())
                    Text("Naya account banayein").foregroundStyle(Color.secondary)

                    FormField(title: "Poora naam", placeholder: "Ali Khan", text: $name)
                    FormField(title: "Mobile number", placeholder: "03XXXXXXXXX", text: $phone, kind: .digits, maxLength: 11)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("4-digit PIN").font(.footnote).foregroundStyle(Color.secondary)
                        PinField(title: "PIN", text: $pin)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text("PIN dobara likhein").font(.footnote).foregroundStyle(Color.secondary)
                        PinField(title: "PIN confirm", text: $confirmPin)
                    }

                    if let error {
                        Text(error).font(.footnote).foregroundStyle(Color.red)
                    }

                    PrimaryButton(title: "Account banayein") { submit() }

                    Text("Ye demo version hai: asli paisa nahi hilta.")
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .scrollDismissesKeyboard(.interactively)
        }
    }

    private func submit() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard trimmed.count >= 3 else { error = "Naam kam az kam 3 huroof ka ho."; return }
        guard Validators.isValidPhone(phone) else { error = "Number 03XXXXXXXXX format mein likhein."; return }
        guard Validators.isValidPin(pin) else { error = "PIN 4 digits ka ho."; return }
        guard pin == confirmPin else { error = "Dono PIN match nahi karte."; return }
        store.register(name: trimmed, phone: phone, pin: pin)
    }
}

struct LoginView: View {
    @EnvironmentObject var store: AppStore
    @State private var pin = ""
    @State private var error: String?
    @State private var failed = 0
    @State private var lockedUntil: Date?
    @State private var showReset = false

    var body: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 64))
                .foregroundStyle(Color.brand)
            Text("Salam, \(store.account?.name ?? "")").font(.title2.bold())
            Text("Apna 4-digit PIN daalein").foregroundStyle(Color.secondary)

            PinField(title: "PIN", text: $pin)

            if let error {
                Text(error).font(.footnote).foregroundStyle(Color.red)
            }

            PrimaryButton(title: "Login", disabled: pin.count != 4) { attempt() }

            Button("PIN bhool gaye?") { showReset = true }
                .font(.footnote)
            Spacer()
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .confirmationDialog("Saara data delete ho jayega", isPresented: $showReset, titleVisibility: .visible) {
            Button("App reset karein", role: .destructive) { store.resetEverything() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Account, balance aur history sab mit jayegi.")
        }
    }

    private func attempt() {
        if let until = lockedUntil, until > Date() {
            error = "Kuch der baad dobara koshish karein."
            pin = ""
            return
        }
        if store.login(pin: pin) { return }
        failed += 1
        pin = ""
        if failed >= 5 {
            lockedUntil = Date().addingTimeInterval(30)
            failed = 0
            error = "5 ghalat koshishen. 30 second intezar karein."
        } else {
            error = "PIN ghalat hai (\(5 - failed) koshishen baqi)."
        }
    }
}
