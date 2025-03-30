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
                        title: Text("Fehler"),
                        message: Text(viewModel.errorMessage),
                        dismissButton: .default(Text("OK")) { viewModel.resetError() }
                    )
                }
                .task {
                    await viewModel.loadSponsors()
                }
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
            }
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
            }
        }
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
            if let category = sponsor.category {
                Text("Kategorie: \(category)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            if let kontaktTelefon = sponsor.kontaktTelefon {
                Text("Telefon: \(kontaktTelefon)")
                    .font(.subheadline)
            }
            if let kontaktEmail = sponsor.kontaktEmail {
                Text("E-Mail: \(kontaktEmail)")
                    .font(.subheadline)
            }
            if let contacts = sponsor.contacts, !contacts.isEmpty {
                Text("Ansprechpartner:")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                ForEach(contacts) { contact in
                    Text("\(contact.name) (\(contact.region))")
                        .font(.subheadline)
                }
            }
        }
        .swipeActions {
            Button(role: .destructive, action: onDelete) {
                Label("Löschen", systemImage: "trash")
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
