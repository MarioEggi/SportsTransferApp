import SwiftUI

struct EditSponsorView: View {
    @Binding var sponsor: Sponsor
    var onSave: (Sponsor) -> Void
    var onCancel: () -> Void
    @Environment(\.dismiss) var dismiss

    @State private var contacts: [Sponsor.Contact] = []
    @State private var showingAddContact = false
    @State private var newContactName: String = ""
    @State private var newContactRegion: String? = nil
    @State private var newContactTelefon: String = ""
    @State private var newContactEmail: String = ""

    // Farben für das helle Design
    private let backgroundColor = Color(hex: "#F5F5F5")
    private let cardBackgroundColor = Color(hex: "#E0E0E0")
    private let accentColor = Color(hex: "#00C4B4")
    private let textColor = Color(hex: "#333333")
    private let secondaryTextColor = Color(hex: "#666666")

    var body: some View {
        NavigationView {
            ZStack {
                backgroundColor.edgesIgnoringSafeArea(.all)
                List {
                    Section(header: Text("Sponsordaten").foregroundColor(textColor)) {
                        VStack(spacing: 10) {
                            TextField("Name", text: $sponsor.name)
                                .foregroundColor(textColor)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                            Picker("Kategorie", selection: $sponsor.category) {
                                Text("Keine Kategorie").tag(String?.none)
                                ForEach(Constants.sponsorCategories, id: \.self) { category in
                                    Text(category).tag(String?.some(category))
                                }
                            }
                            .pickerStyle(.menu)
                            .foregroundColor(textColor)
                            .tint(accentColor)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                        }
                        .padding(.vertical, 8)
                    }
                    .listRowBackground(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(cardBackgroundColor)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(accentColor.opacity(0.3), lineWidth: 1)
                            )
                            .padding(.vertical, 2)
                    )

                    Section(header: Text("Kontaktinformationen").foregroundColor(textColor)) {
                        VStack(spacing: 10) {
                            TextField("Telefon", text: Binding(
                                get: { sponsor.kontaktTelefon ?? "" },
                                set: { sponsor.kontaktTelefon = $0.isEmpty ? nil : $0 }
                            ))
                                .foregroundColor(textColor)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                            TextField("E-Mail", text: Binding(
                                get: { sponsor.kontaktEmail ?? "" },
                                set: { sponsor.kontaktEmail = $0.isEmpty ? nil : $0 }
                            ))
                                .foregroundColor(textColor)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                            TextField("Adresse", text: Binding(
                                get: { sponsor.adresse ?? "" },
                                set: { sponsor.adresse = $0.isEmpty ? nil : $0 }
                            ))
                                .foregroundColor(textColor)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                        }
                        .padding(.vertical, 8)
                    }
                    .listRowBackground(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(cardBackgroundColor)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(accentColor.opacity(0.3), lineWidth: 1)
                            )
                            .padding(.vertical, 2)
                    )

                    Section(header: Text("Ansprechpartner").foregroundColor(textColor)) {
                        VStack(spacing: 10) {
                            if contacts.isEmpty {
                                Text("Keine Ansprechpartner vorhanden.")
                                    .foregroundColor(secondaryTextColor)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                            } else {
                                ForEach(contacts) { contact in
                                    contactRow(contact: contact)
                                        .swipeActions {
                                            Button(role: .destructive) {
                                                contacts.removeAll { $0.id == contact.id }
                                            } label: {
                                                Label("Löschen", systemImage: "trash")
                                                    .foregroundColor(.white)
                                            }
                                        }
                                }
                            }
                            Button(action: {
                                showingAddContact = true
                                newContactName = ""
                                newContactRegion = nil
                                newContactTelefon = ""
                                newContactEmail = ""
                            }) {
                                Label("Ansprechpartner hinzufügen", systemImage: "plus.circle")
                                    .foregroundColor(accentColor)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                        }
                        .padding(.vertical, 8)
                    }
                    .listRowBackground(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(cardBackgroundColor)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(accentColor.opacity(0.3), lineWidth: 1)
                            )
                            .padding(.vertical, 2)
                    )
                }
                .listStyle(PlainListStyle())
                .listRowInsets(EdgeInsets(top: 3, leading: 13, bottom: 3, trailing: 13))
                .scrollContentBackground(.hidden)
                .background(backgroundColor)
                .tint(accentColor)
                .foregroundColor(textColor)
                .navigationTitle("Sponsor bearbeiten")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Abbrechen") { onCancel() }
                            .foregroundColor(accentColor)
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Speichern") {
                            sponsor.contacts = contacts.isEmpty ? nil : contacts
                            onSave(sponsor)
                            dismiss()
                        }
                        .disabled(sponsor.name.isEmpty)
                        .foregroundColor(accentColor)
                    }
                }
                .sheet(isPresented: $showingAddContact) { addContactSheet }
                .onAppear { if let existingContacts = sponsor.contacts { contacts = existingContacts } }
            }
        }
    }

    private func contactRow(contact: Sponsor.Contact) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(contact.name) (\(contact.region))")
                .font(.subheadline)
                .foregroundColor(textColor)
            if let telefon = contact.telefon {
                Text("Telefon: \(telefon)")
                    .font(.caption)
                    .foregroundColor(secondaryTextColor)
            }
            if let email = contact.email {
                Text("E-Mail: \(email)")
                    .font(.caption)
                    .foregroundColor(secondaryTextColor)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
    }

    private var addContactSheet: some View {
        NavigationView {
            List {
                Section(header: Text("Ansprechpartner").foregroundColor(textColor)) {
                    VStack(spacing: 10) {
                        TextField("Name", text: $newContactName)
                            .foregroundColor(textColor)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                        Picker("Region", selection: $newContactRegion) {
                            Text("Keine Region").tag(String?.none)
                            ForEach(Constants.nationalities, id: \.self) { country in
                                Text(country).tag(String?.some(country))
                            }
                        }
                        .pickerStyle(.menu)
                        .foregroundColor(textColor)
                        .tint(accentColor)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        TextField("Telefon", text: $newContactTelefon)
                            .foregroundColor(textColor)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                        TextField("E-Mail", text: $newContactEmail)
                            .foregroundColor(textColor)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                    }
                    .padding(.vertical, 8)
                }
                .listRowBackground(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(cardBackgroundColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(accentColor.opacity(0.3), lineWidth: 1)
                        )
                        .padding(.vertical, 2)
                )
            }
            .listStyle(PlainListStyle())
            .listRowInsets(EdgeInsets(top: 3, leading: 13, bottom: 3, trailing: 13))
            .scrollContentBackground(.hidden)
            .background(backgroundColor)
            .navigationTitle("Ansprechpartner hinzufügen")
            .foregroundColor(textColor)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { showingAddContact = false }
                        .foregroundColor(accentColor)
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
                    .foregroundColor(accentColor)
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
            contacts: [Sponsor.Contact(id: UUID().uuidString, name: "John Doe", region: "USA", telefon: "+123456789", email: "john.doe@nike.com")],
            kontaktTelefon: "+123456789",
            kontaktEmail: "contact@nike.com",
            adresse: "123 Nike Street",
            gesponsorteVereine: ["Bayern München"]
        )),
        onSave: { _ in },
        onCancel: {}
    )
}
