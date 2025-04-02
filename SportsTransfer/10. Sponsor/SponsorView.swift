import SwiftUI
import FirebaseFirestore

struct SponsorView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var viewModel = SponsorViewModel()
    @State var sponsor: Sponsor
    @State private var showingEditSheet = false

    // Farben für das helle Design
    private let backgroundColor = Color(hex: "#F5F5F5")
    private let cardBackgroundColor = Color(hex: "#E0E0E0")
    private let accentColor = Color(hex: "#00C4B4")
    private let textColor = Color(hex: "#333333")
    private let secondaryTextColor = Color(hex: "#666666")

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 15) {
                    Text(sponsor.name)
                        .font(.title2)
                        .bold()
                        .multilineTextAlignment(.center)
                        .foregroundColor(textColor)
                        .padding(.top)

                    List {
                        Section(header: Text("Details").foregroundColor(textColor)) {
                            VStack(spacing: 10) {
                                if let category = sponsor.category {
                                    labeledField(label: "Kategorie", value: category)
                                }
                                if let kontaktTelefon = sponsor.kontaktTelefon {
                                    HStack {
                                        labeledField(label: "Telefon", value: kontaktTelefon)
                                        Spacer()
                                        Button(action: { openURL("tel:\(kontaktTelefon)") }) {
                                            Image(systemName: "phone.fill")
                                                .foregroundColor(accentColor)
                                        }
                                    }
                                }
                                if let kontaktEmail = sponsor.kontaktEmail {
                                    HStack {
                                        labeledField(label: "E-Mail", value: kontaktEmail)
                                        Spacer()
                                        Button(action: { openURL("mailto:\(kontaktEmail)") }) {
                                            Image(systemName: "envelope.fill")
                                                .foregroundColor(accentColor)
                                        }
                                    }
                                }
                                if let adresse = sponsor.adresse {
                                    labeledField(label: "Adresse", value: adresse)
                                }
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

                        if let gesponsorteVereine = sponsor.gesponsorteVereine, !gesponsorteVereine.isEmpty {
                            Section(header: Text("Gesponsorte Vereine").foregroundColor(textColor)) {
                                VStack(spacing: 10) {
                                    ForEach(gesponsorteVereine, id: \.self) { verein in
                                        Text(verein)
                                            .foregroundColor(textColor)
                                            .padding(.vertical, 4)
                                            .padding(.horizontal, 8)
                                    }
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

                        if let contacts = sponsor.contacts, !contacts.isEmpty {
                            Section(header: Text("Ansprechpartner").foregroundColor(textColor)) {
                                ForEach(contacts) { contact in
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
                    }
                    .listStyle(PlainListStyle())
                    .listRowInsets(EdgeInsets(top: 3, leading: 13, bottom: 3, trailing: 13))
                    .scrollContentBackground(.hidden)
                    .background(backgroundColor)
                    .foregroundColor(textColor)

                    if authManager.userRole == .mitarbeiter {
                        Button(action: { showingEditSheet = true }) {
                            Text("Bearbeiten")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(accentColor)
                                .foregroundColor(textColor)
                                .cornerRadius(10)
                        }
                        .padding()
                    }
                }
                .background(backgroundColor)
                .navigationTitle(sponsor.name)
                .navigationBarTitleDisplayMode(.inline)
                .foregroundColor(textColor)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        if authManager.userRole == .mitarbeiter {
                            Button(action: { showingEditSheet = true }) {
                                Image(systemName: "pencil")
                                    .foregroundColor(accentColor)
                            }
                        }
                    }
                }
                .sheet(isPresented: $showingEditSheet) {
                    EditSponsorView(
                        sponsor: $sponsor,
                        onSave: { updatedSponsor in
                            Task {
                                await viewModel.saveSponsor(updatedSponsor)
                                await MainActor.run {
                                    sponsor = updatedSponsor
                                    showingEditSheet = false
                                }
                            }
                        },
                        onCancel: { showingEditSheet = false }
                    )
                }
            }
        }
    }

    private func labeledField(label: String, value: String?) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(secondaryTextColor)
            Spacer()
            Text(value ?? "Nicht angegeben")
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .foregroundColor(textColor)
        }
    }

    private func openURL(_ urlString: String) {
        if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}

#Preview {
    SponsorView(sponsor: Sponsor(
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
    ))
    .environmentObject(AuthManager())
}
