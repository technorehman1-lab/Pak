import SwiftUI

@main
struct PakTransferApp: App {
    // Demo ke liye MockPaymentService. Asli API jorne ke baad yahan
    // RealPaymentService(...) laga dein (Services/PaymentService.swift dekhein).
    @StateObject private var store = AppStore(service: MockPaymentService())

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .tint(Color.brand)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        Group {
            if store.account == nil {
                RegisterView()
            } else if !store.isLoggedIn {
                LoginView()
            } else {
                MainTabView()
            }
        }
        .animation(.easeInOut, value: store.isLoggedIn)
        .animation(.easeInOut, value: store.account == nil)
    }
}
