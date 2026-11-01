import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }
            HistoryView()
                .tabItem { Label("History", systemImage: "clock.fill") }
            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.fill") }
        }
    }
}

struct HomeView: View {
    @EnvironmentObject var store: AppStore

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    balanceCard
                    actions
                    recent
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Pak Transfer")
        }
    }

    private var balanceCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Salam, \(store.account?.name ?? "")")
                .font(.subheadline)
                .foregroundStyle(Color.white.opacity(0.85))
            HStack {
                Text(store.hideBalance ? "Rs ••••••" : store.balance.rs)
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(Color.white)
                Spacer()
                Button {
                    store.hideBalance.toggle()
                } label: {
                    Image(systemName: store.hideBalance ? "eye.slash" : "eye")
                        .font(.title3)
                        .foregroundStyle(Color.white)
                }
            }
            Text("Is mahine kharcha: \(store.spentThisMonth.rs)")
                .font(.footnote)
                .foregroundStyle(Color.white.opacity(0.85))
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(colors: [Color.brand, Color.brandDark], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var actions: some View {
        LazyVGrid(columns: columns, spacing: 18) {
            tile("Send Money", "paperplane.fill") { SendMoneyView() }
            tile("Add Money", "plus.circle.fill") { AddMoneyView() }
            tile("Mobile Load", "iphone") { MobileLoadView() }
            tile("Bills", "bolt.fill") { BillPaymentView() }
            tile("My QR", "qrcode") { MyQRView() }
            tile("Scan QR", "qrcode.viewfinder") { ScanQRView() }
            tile("Contacts", "person.2.fill") { ContactsView() }
            tile("History", "clock.arrow.circlepath") { HistoryContent() }
        }
    }

    private func tile<Destination: View>(_ title: String, _ icon: String,
                                         @ViewBuilder destination: () -> Destination) -> some View {
        NavigationLink {
            destination()
        } label: {
            ActionTile(title: title, icon: icon)
        }
        .buttonStyle(.plain)
    }

    private var recent: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Recent").font(.headline)
                Spacer()
                if !store.transactions.isEmpty {
                    NavigationLink("Sab dekhein") { HistoryContent() }
                        .font(.subheadline)
                }
            }
            Card {
                if store.transactions.isEmpty {
                    Text("Abhi koi transaction nahi. \"Add Money\" se shuru karein.")
                        .font(.subheadline)
                        .foregroundStyle(Color.secondary)
                } else {
                    ForEach(Array(store.transactions.prefix(5))) { tx in
                        NavigationLink {
                            ReceiptScreen(tx: tx)
                        } label: {
                            TransactionRow(tx: tx)
                        }
                        .buttonStyle(.plain)
                        if tx.id != store.transactions.prefix(5).last?.id { Divider() }
                    }
                }
            }
        }
    }
}
