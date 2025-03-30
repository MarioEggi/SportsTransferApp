import SwiftUI

struct EditSponsorView: View {
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
            Form {
                Section(header: Text("Sponsordaten")) {
                    TextField("Name", text: $sponsor.name)
                    Picker("Kategorie", selection: $sponsor.category) {
                        Text("Keine Kategorie").tag(String?.none)
                        ForEach(Constants.sponsorCategories, id: \.self) { category in
                            Text(category).tag(String?.some(category))
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section(header: Text("Kontaktinformationen")) {
                    TextField("Telefon", text: Binding(
                        get: { sponsor.kontaktTelefon ?? "" },
                        set: { sponsor.kontaktTelefon = $0.isEmpty ? nil : $0 }
                    ))
                    TextField("E-Mail", text: Binding(
                        get: { sponsor.kontaktEmail ?? "" },
                        set: { sponsor.kontaktEmail = $0.isEmpty ? nil : $0 }
                    ))
                    TextField("Adresse", text: Binding(
                        get: { sponsor.adresse ?? "" },
                        set: { sponsor.adresse = $0.isEmpty ? nil : $0 }
                    ))
                }

                Section(header: Text("Ansprechpartner")) {
                    if contacts.isEmpty {
                        Text("Keine Ansprechpartner vorhanden.")
                            .foregroundColor(.gray)
                    } else {
                        ForEach(contacts) { contact in
                            VStack(alignment: .leading) {
                                Text("\(contact.name) (\(contact.region))")
                                    .font(.subheadline)
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
                                }
                            }
                        }
                    }
                    Button("Ansprechpartner hinzufügen") {
                        showingAddContact = true
                        newContactName = ""
                        newContactRegion = nil
                        newContactTelefon = ""
                        newContactEmail = ""
                    }
                }
            }
            .navigationTitle("Sponsor bearbeiten")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { onCancel() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        sponsor.contacts = contacts.isEmpty ? nil : contacts
                        onSave(sponsor)
                    }
                    .disabled(sponsor.name.isEmpty)
                }
            }
            .sheet(isPresented: $showingAddContact) {
                NavigationView {
                    Form {
                        Section(header: Text("Ansprechpartner")) {
                            TextField("Name", text: $newContactName)
                            Picker("Region", selection: $newContactRegion) {
                                Text("Keine Region").tag(String?.none)
                                ForEach(Constants.nationalities, id: \.self) { country in
                                    Text(country).tag(String?.some(country))
                                }
                            }
                            .pickerStyle(.menu)
                            TextField("Telefon", text: $newContactTelefon)
                            TextField("E-Mail", text: $newContactEmail)
                        }
                    }
                    .navigationTitle("Ansprechpartner hinzufügen")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Abbrechen") {
                                showingAddContact = false
                            }
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
                        }
                    }
                }
            }
            .onAppear {
                if let existingContacts = sponsor.contacts {
                    contacts = existingContacts
                }
            }
        }
    }
}

#Preview {
    EditSponsorView(
        sponsor: .constant(Sponsor(
            id: "1",
            name: "Nike",
            category: "Sportartikelhersteller",
            contacts: [
                Sponsor.Contact(id: UUID().uuidString, name: "John Doe", region: "USA", telefon: "+123456789", email: "john.doe@nike.com")
            ],
            kontaktTelefon: "+123456789",
            kontaktEmail: "contact@nike.com",
            adresse: "123 Nike Street",
            gesponsorteVereine: ["Bayern München"]
        )),
        onSave: { _ in },
        onCancel: {}
    )
}
