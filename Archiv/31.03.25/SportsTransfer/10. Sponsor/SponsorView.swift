import SwiftUI
import FirebaseFirestore

struct SponsorView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var viewModel = SponsorViewModel()
    @State var sponsor: Sponsor
    @State private var showingEditSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 15) {
                    VStack(spacing: 10) {
                        Text(sponsor.name)
                            .font(.title2)
                            .bold()
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white) // Weiße Schrift

                        if let category = sponsor.category {
                            Text("Kategorie: \(category)")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }

                        if let kontaktTelefon = sponsor.kontaktTelefon {
                            HStack {
                                Text("Telefon: \(kontaktTelefon)")
                                    .font(.subheadline)
                                    .foregroundColor(.white) // Weiße Schrift
                                Spacer()
                                Button(action: { openURL("tel:\(kontaktTelefon)") }) {
                                    Image(systemName: "phone.fill")
                                        .foregroundColor(.white) // Weißes Symbol
                                }
                            }
                        }

                        if let kontaktEmail = sponsor.kontaktEmail {
                            HStack {
                                Text("E-Mail: \(kontaktEmail)")
                                    .font(.subheadline)
                                    .foregroundColor(.white) // Weiße Schrift
                                Spacer()
                                Button(action: { openURL("mailto:\(kontaktEmail)") }) {
                                    Image(systemName: "envelope.fill")
                                        .foregroundColor(.white) // Weißes Symbol
                                }
                            }
                        }

                        if let adresse = sponsor.adresse {
                            Text("Adresse: \(adresse)")
                                .font(.subheadline)
                                .foregroundColor(.white) // Weiße Schrift
                        }

                        if let gesponsorteVereine = sponsor.gesponsorteVereine, !gesponsorteVereine.isEmpty {
                            Text("Gesponsorte Vereine:")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            ForEach(gesponsorteVereine, id: \.self) { verein in
                                Text(verein)
                                    .font(.subheadline)
                                    .foregroundColor(.white) // Weiße Schrift
                            }
                        }

                        if let contacts = sponsor.contacts, !contacts.isEmpty {
                            Text("Ansprechpartner:")
                                .font(.subheadline)
                                .foregroundColor(.gray)
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
                            }
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.2)) // Dunklerer Hintergrund
                    .cornerRadius(10)
                }
                .padding()
                .background(Color.black) // Schwarzer Hintergrund für die gesamte View
                .navigationTitle(sponsor.name)
                .navigationBarTitleDisplayMode(.inline)
                .foregroundColor(.white) // Weiße Schrift für den Titel
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { showingEditSheet = true }) {
                            Image(systemName: "pencil")
                                .foregroundColor(.white) // Weißes Symbol
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
                        onCancel: {
                            showingEditSheet = false
                        }
                    )
                }
            }
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
