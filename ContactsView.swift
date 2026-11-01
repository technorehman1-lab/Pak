import SwiftUI

struct ContactsView: View {
    @EnvironmentObject var store: AppStore
    @State private var showAdd = false

    var body: some View {
        List {
            if store.contacts.isEmpty {
                ContentUnavailableView {
                    Label("Koi contact nahi", systemImage: "person.2")
                } description: {
                    Text("Baar baar paisay bhejne walon ko yahan save karein.")
                } actions: {
                    Button("Contact add karein") { showAdd = true }
                }
                .listRowBackground(Color.clear)
            }

            ForEach(store.contacts) { contact in
                NavigationLink {
                    SendMoneyView(phone: contact.phone, name: contact.name)
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(contact.name).fontWeight(.medium)
                        Text(contact.phone).font(.caption).foregroundStyle(Color.secondary)
                    }
                }
            }
            .onDelete { offsets in
                store.deleteContacts(at: offsets)
            }
        }
        .navigationTitle("Contacts")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAdd = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAdd) {
            AddContactSheet()
        }
    }
}

struct AddContactSheet: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var phone = ""
    @State private var error: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    FormField(title: "Naam", placeholder: "Contact ka naam", text: $name)
                    FormField(title: "Mobile number", placeholder: "03XXXXXXXXX", text: $phone, kind: .digits, maxLength: 11)
                    if let error {
                        Text(error).font(.footnote).foregroundStyle(Color.red)
                    }
                    PrimaryButton(title: "Save karein") {
                        if let message = store.addContact(name: name, phone: phone) {
                            error = message
                        } else {
                            dismiss()
                        }
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Naya Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
