import SwiftUI
import FirebaseFirestore

struct SponsorListView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var viewModel = SponsorViewModel()
    @State private var showingAddSponsor = false
    @State private var newSponsor = Sponsor(
        id: nil,
        name: "",
        category: nil,
        contacts: nil,
        kontaktTelefon: nil,
        kontaktEmail: nil,
        adresse: nil,
        gesponsorteVereine: nil
    )

    var body: some View {
        NavigationStack {
            sponsorList
                .navigationTitle("Sponsorübersicht")
                .foregroundColor(.white) // Weiße Schrift für den Titel
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Neuen Sponsor anlegen") {
                            if authManager.isLoggedIn {
                                showingAddSponsor = true
                                newSponsor = Sponsor(
                                    id: nil,
                                    name: "",
                                    category: nil,
                                    contacts: nil,
                                    kontaktTelefon: nil,
                                    kontaktEmail: nil,
                                    adresse: nil,
                                    gesponsorteVereine: nil
                                )
                            } else {
                                viewModel.errorMessage = "Du musst angemeldet sein."
                            }
                        }
                        .foregroundColor(.white) // Weiße Schrift
                        .disabled(!authManager.isLoggedIn)
                    }
                }
                .sheet(isPresented: $showingAddSponsor) {
                    AddSponsorView(
                        sponsor: $newSponsor,
                        onSave: { sponsor in
                            Task {
                                await viewModel.saveSponsor(sponsor)
                                await MainActor.run {
                                    showingAddSponsor = false
                                    newSponsor = Sponsor(
                                        id: nil,
                                        name: "",
                                        category: nil,
                                        contacts: nil,
                                        kontaktTelefon: nil,
                                        kontaktEmail: nil,
                                        adresse: nil,
                                        gesponsorteVereine: nil
                                    )
                                }
                            }
                        },
                        onCancel: {
                            showingAddSponsor = false
                            newSponsor = Sponsor(
                                id: nil,
                                name: "",
                                category: nil,
                                contacts: nil,
                                kontaktTelefon: nil,
                                kontaktEmail: nil,
                                adresse: nil,
                                gesponsorteVereine: nil
                            )
                        }
                    )
                }
                .alert(isPresented: .constant(!viewModel.errorMessage.isEmpty)) {
                    Alert(
                        title: Text("Fehler").foregroundColor(.white),
                        message: Text(viewModel.errorMessage).foregroundColor(.white),
                        dismissButton: .default(Text("OK").foregroundColor(.white)) { viewModel.resetError() }
                    )
                }
                .task {
                    await viewModel.loadSponsors()
                }
                .background(Color.black) // Schwarzer Hintergrund für die gesamte View
        }
    }

    private var sponsorList: some View {
        List {
            ForEach(viewModel.sponsors) { sponsor in
                NavigationLink(destination: SponsorView(sponsor: sponsor)) {
                    SponsorRowView(
                        sponsor: sponsor,
                        viewModel: viewModel,
                        onDelete: {
                            Task { await viewModel.deleteSponsor(sponsor) }
                        },
                        isLast: sponsor == viewModel.sponsors.last
                    )
                }
                .listRowBackground(Color.gray.opacity(0.2)) // Dunklerer Hintergrund für Listenelemente
            }
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .tint(.white) // Weißer Ladeindikator
                    .listRowBackground(Color.black) // Schwarzer Hintergrund
            }
        }
        .scrollContentBackground(.hidden) // Standard-Hintergrund der Liste ausblenden
        .background(Color.black) // Schwarzer Hintergrund für die Liste
    }
}

struct SponsorRowView: View {
    let sponsor: Sponsor
    let viewModel: SponsorViewModel
    let onDelete: () -> Void
    let isLast: Bool

    var body: some View {
        VStack(alignment: .leading) {
            Text(sponsor.name)
                .font(.headline)
                .foregroundColor(.white) // Weiße Schrift
            if let category = sponsor.category {
                Text("Kategorie: \(category)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            if let kontaktTelefon = sponsor.kontaktTelefon {
                Text("Telefon: \(kontaktTelefon)")
                    .font(.subheadline)
                    .foregroundColor(.white) // Weiße Schrift
            }
            if let kontaktEmail = sponsor.kontaktEmail {
                Text("E-Mail: \(kontaktEmail)")
                    .font(.subheadline)
                    .foregroundColor(.white) // Weiße Schrift
            }
            if let contacts = sponsor.contacts, !contacts.isEmpty {
                Text("Ansprechpartner:")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                ForEach(contacts) { contact in
                    Text("\(contact.name) (\(contact.region))")
                        .font(.subheadline)
                        .foregroundColor(.white) // Weiße Schrift
                }
            }
        }
        .swipeActions {
            Button(role: .destructive, action: onDelete) {
                Label("Löschen", systemImage: "trash")
                    .foregroundColor(.white) // Weiße Schrift und Symbol
            }
        }
        .onAppear {
            if isLast {
                Task { await viewModel.loadSponsors(loadMore: true) }
            }
        }
    }
}

#Preview {
    SponsorListView()
        .environmentObject(AuthManager())
}
