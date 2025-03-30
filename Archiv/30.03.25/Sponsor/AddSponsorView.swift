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
            Form {
                Section(header: Text("Sponsordaten").foregroundColor(.white)) {
                    TextField("Name", text: $sponsor.name)
                        .foregroundColor(.white) // Weiße Schrift
                    Picker("Kategorie", selection: $sponsor.category) {
                        Text("Keine Kategorie").tag(String?.none)
                        ForEach(Constants.sponsorCategories, id: \.self) { category in
                            Text(category).tag(String?.some(category))
                        }
                    }
                    .pickerStyle(.menu)
                    .foregroundColor(.white) // Weiße Schrift
                    .accentColor(.white) // Weiße Akzente
                }

                Section(header: Text("Kontaktinformationen").foregroundColor(.white)) {
                    TextField("Telefon", text: Binding(
                        get: { sponsor.kontaktTelefon ?? "" },
                        set: { sponsor.kontaktTelefon = $0.isEmpty ? nil : $0 }
                    ))
                        .foregroundColor(.white) // Weiße Schrift
                    TextField("E-Mail", text: Binding(
                        get: { sponsor.kontaktEmail ?? "" },
                        set: { sponsor.kontaktEmail = $0.isEmpty ? nil : $0 }
                    ))
                        .foregroundColor(.white) // Weiße Schrift
                    TextField("Adresse", text: Binding(
                        get: { sponsor.adresse ?? "" },
                        set: { sponsor.adresse = $0.isEmpty ? nil : $0 }
                    ))
                        .foregroundColor(.white) // Weiße Schrift
                }

                Section(header: Text("Ansprechpartner").foregroundColor(.white)) {
                    if contacts.isEmpty {
                        Text("Keine Ansprechpartner vorhanden.")
                            .foregroundColor(.gray)
                    } else {
                        ForEach(contacts) { contact in
                            VStack(alignment: .leading) {
                                Text("\(contact.name) (\(contact.region))")
                                    .font(.subheadline)
                                    .foregroundColor(.white) // Weiße Schrift
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
                                        .foregroundColor(.white) // Weiße Schrift und Symbol
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
                    .foregroundColor(.white) // Weiße Schrift
                }
            }
            .scrollContentBackground(.hidden) // Standard-Hintergrund der Form ausblenden
            .background(Color.black) // Schwarzer Hintergrund für die Form
            .navigationTitle("Sponsor anlegen")
            .foregroundColor(.white) // Weiße Schrift für den Titel
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { onCancel() }
                        .foregroundColor(.white) // Weiße Schrift
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        sponsor.contacts = contacts.isEmpty ? nil : contacts
                        onSave(sponsor)
                    }
                    .disabled(sponsor.name.isEmpty)
                    .foregroundColor(.white) // Weiße Schrift
                }
            }
            .sheet(isPresented: $showingAddContact) {
                NavigationView {
                    Form {
                        Section(header: Text("Ansprechpartner").foregroundColor(.white)) {
                            TextField("Name", text: $newContactName)
                                .foregroundColor(.white) // Weiße Schrift
                            Picker("Region", selection: $newContactRegion) {
                                Text("Keine Region").tag(String?.none)
                                ForEach(Constants.nationalities, id: \.self) { country in
                                    Text(country).tag(String?.some(country))
                                }
                            }
                            .pickerStyle(.menu)
                            .foregroundColor(.white) // Weiße Schrift
                            .accentColor(.white) // Weiße Akzente
                            TextField("Telefon", text: $newContactTelefon)
                                .foregroundColor(.white) // Weiße Schrift
                            TextField("E-Mail", text: $newContactEmail)
                                .foregroundColor(.white) // Weiße Schrift
                        }
                    }
                    .scrollContentBackground(.hidden) // Standard-Hintergrund der Form ausblenden
                    .background(Color.black) // Schwarzer Hintergrund für die Form
                    .navigationTitle("Ansprechpartner hinzufügen")
                    .foregroundColor(.white) // Weiße Schrift für den Titel
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Abbrechen") {
                                showingAddContact = false
                            }
                            .foregroundColor(.white) // Weiße Schrift
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
                            .foregroundColor(.white) // Weiße Schrift
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
