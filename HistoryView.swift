import SwiftUI

enum HistoryFilter: String, CaseIterable, Identifiable {
    case all = "Sab"
    case sent = "Sent"
    case services = "Load/Bills"
    case added = "Added"

    var id: String { rawValue }

    func matches(_ tx: Transaction) -> Bool {
        switch self {
        case .all: return true
        case .sent: return tx.type == .sent
        case .services: return tx.type == .mobileLoad || tx.type == .billPayment
        case .added: return tx.type == .addMoney || tx.type == .received
        }
    }
}

/// Tab ke liye (apna NavigationStack).
struct HistoryView: View {
    var body: some View {
        NavigationStack {
            HistoryContent()
        }
    }
}

/// Home se push karne ke liye bhi yahi istemal hota hai.
struct HistoryContent: View {
    @EnvironmentObject var store: AppStore
    @State private var filter: HistoryFilter = .all
    @State private var search = ""

    private var items: [Transaction] {
        store.transactions.filter { tx in
            filter.matches(tx) && (
                search.isEmpty
                || tx.title.localizedCaseInsensitiveContains(search)
                || tx.detail.localizedCaseInsensitiveContains(search)
                || tx.reference.localizedCaseInsensitiveContains(search)
            )
        }
    }

    var body: some View {
        List {
            Section {
                Picker("Filter", selection: $filter) {
                    ForEach(HistoryFilter.allCases) { item in
                        Text(item.rawValue).tag(item)
                    }
                }
                .pickerStyle(.segmented)
            }
            .listRowBackground(Color.clear)

            if items.isEmpty {
                ContentUnavailableView("Koi transaction nahi", systemImage: "tray",
                                       description: Text("Jab aap paisay bhejenge ya add karenge to yahan nazar aayega."))
                    .listRowBackground(Color.clear)
            } else {
                Section {
                    ForEach(items) { tx in
                        NavigationLink {
                            ReceiptScreen(tx: tx)
                        } label: {
                            TransactionRow(tx: tx)
                        }
                    }
                }
            }
        }
        .searchable(text: $search, prompt: "Naam, number ya reference")
        .navigationTitle("History")
    }
}
