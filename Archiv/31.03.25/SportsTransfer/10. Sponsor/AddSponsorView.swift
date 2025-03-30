import SwiftUI

struct AddSponsorView: View {
    @Binding var sponsor: Sponsor
    var onSave: (Sponsor) -> Void
    var onCancel: () -> Void

    @State private var contacts: [Sponsor.Contact] = []
    @State private var showingAddContact = false
    @State private var newContactName: String = ""
    @State private var newContactRegion: String? = nil
    @State private var newContactTelefon: String = ""
    @State private var newContactEmail: String = ""

    var body: some View {
        NavigationView {
            mainFormContent
                .navigationTitle("Sponsor anlegen")
                .foregroundColor(.white)
                .toolbar { toolbarItems }
                .sheet(isPresented: $showingAddContact) { addContactSheet }
                .onAppear { if let existingContacts = sponsor.contacts { contacts = existingContacts } }
        }
    }

    // Hauptformular-Inhalt
    private var mainFormContent: some View {
        Form {
            sponsorDataSection
            contactInfoSection
            contactsSection
        }
        .scrollContentBackground(.hidden)
        .background(Color.black)
    }

    // Toolbar-Items
    private var toolbarItems: some ToolbarContent {
        Group {
            ToolbarItem(placement: .cancellationAction) {
                Button("Abbrechen") { onCancel() }
                    .foregroundColor(.white)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Speichern") {
                    sponsor.contacts = contacts.isEmpty ? nil : contacts
                    onSave(sponsor)
                }
                .disabled(sponsor.name.isEmpty)
                .foregroundColor(.white)
            }
        }
    }

    // Sponsordaten Sektion
    private var sponsorDataSection: some View {
        Section(header: Text("Sponsordaten").foregroundColor(.white)) {
            TextField("Name", text: $sponsor.name)
                .foregroundColor(.white)
            Picker("Kategorie", selection: $sponsor.category) {
                Text("Keine Kategorie").tag(String?.none)
                ForEach(Constants.sponsorCategories, id: \.self) { category in
                    Text(category).tag(String?.some(category))
                }
            }
            .pickerStyle(.menu)
            .foregroundColor(.white)
            .accentColor(.white)
        }
    }

    // Kontaktinformationen Sektion
    private var contactInfoSection: some View {
        Section(header: Text("Kontaktinformationen").foregroundColor(.white)) {
            TextField("Telefon", text: Binding(
                get: { sponsor.kontaktTelefon ?? "" },
                set: { sponsor.kontaktTelefon = $0.isEmpty ? nil : $0 }
            ))
                .foregroundColor(.white)
            TextField("E-Mail", text: Binding(
                get: { sponsor.kontaktEmail ?? "" },
                set: { sponsor.kontaktEmail = $0.isEmpty ? nil : $0 }
            ))
                .foregroundColor(.white)
            TextField("Adresse", text: Binding(
                get: { sponsor.adresse ?? "" },
                set: { sponsor.adresse = $0.isEmpty ? nil : $0 }
            ))
                .foregroundColor(.white)
        }
    }

    // Ansprechpartner Sektion
    private var contactsSection: some View {
        Section(header: Text("Ansprechpartner").foregroundColor(.white)) {
            if contacts.isEmpty {
                Text("Keine Ansprechpartner vorhanden.")
                    .foregroundColor(.gray)
            } else {
                ForEach(contacts) { contact in
                    contactRow(contact: contact)
                }
            }
            Button("Ansprechpartner hinzufügen") {
                showingAddContact = true
                newContactName = ""
                newContactRegion = nil
                newContactTelefon = ""
                newContactEmail = ""
            }
            .foregroundColor(.white)
        }
    }

    // Ansprechpartner Zeile
    private func contactRow(contact: Sponsor.Contact) -> some View {
        VStack(alignment: .leading) {
            Text("\(contact.name) (\(contact.region))")
                .font(.subheadline)
                .foregroundColor(.white)
            if let telefon = contact.telefon {
                Text("Telefon: \(telefon)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            if let email = contact.email {
                Text("E-Mail: \(email)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .swipeActions {
            Button(role: .destructive) {
                contacts.removeAll { $0.id == contact.id }
            } label: {
                Label("Löschen", systemImage: "trash")
                    .foregroundColor(.white)
            }
        }
    }

    // Ansprechpartner Hinzufügen Sheet
    private var addContactSheet: some View {
        NavigationView {
            Form {
                Section(header: Text("Ansprechpartner").foregroundColor(.white)) {
                    TextField("Name", text: $newContactName)
                        .foregroundColor(.white)
                    Picker("Region", selection: $newContactRegion) {
                        Text("Keine Region").tag(String?.none)
                        ForEach(Constants.nationalities, id: \.self) { country in
                            Text(country).tag(String?.some(country))
                        }
                    }
                    .pickerStyle(.menu)
                    .foregroundColor(.white)
                    .accentColor(.white)
                    TextField("Telefon", text: $newContactTelefon)
                        .foregroundColor(.white)
                    TextField("E-Mail", text: $newContactEmail)
                        .foregroundColor(.white)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.black)
            .navigationTitle("Ansprechpartner hinzufügen")
            .foregroundColor(.white)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { showingAddContact = false }
                        .foregroundColor(.white)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Hinzufügen") {
                        let newContact = Sponsor.Contact(
                            id: UUID().uuidString,
                            name: newContactName,
                            region: newContactRegion ?? "Andere",
                            telefon: newContactTelefon.isEmpty ? nil : newContactTelefon,
                            email: newContactEmail.isEmpty ? nil : newContactEmail
                        )
                        contacts.append(newContact)
                        showingAddContact = false
                    }
                    .disabled(newContactName.isEmpty || newContactRegion == nil)
                    .foregroundColor(.white)
                }
            }
        }
    }
}

#Preview {
    AddSponsorView(
        sponsor: .constant(Sponsor(
            id: nil,
            name: "",
            category: nil,
            contacts: nil,
            kontaktTelefon: nil,
            kontaktEmail: nil,
            adresse: nil,
            gesponsorteVereine: nil
        )),
        onSave: { _ in },
        onCancel: {}
    )
}
