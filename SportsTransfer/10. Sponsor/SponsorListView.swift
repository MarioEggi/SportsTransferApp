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

    // Farben für das dunkle Design
    private let backgroundColor = Color(hex: "#1C2526")
    private let cardBackgroundColor = Color(hex: "#2A3439")
    private let accentColor = Color(hex: "#00C4B4")
    private let textColor = Color(hex: "#E0E0E0")
    private let secondaryTextColor = Color(hex: "#B0BEC5")

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundColor.edgesIgnoringSafeArea(.all)
                VStack(spacing: 0) {
                    HStack {
                        Text("Sponsoren")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(textColor)
                        Spacer()
                        Button(action: {
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
                        }) {
                            Image(systemName: "plus")
                                .foregroundColor(accentColor)
                        }
                        .disabled(!authManager.isLoggedIn)
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)

                    List {
                        if viewModel.sponsors.isEmpty && !viewModel.isLoading {
                            Text("Keine Sponsoren vorhanden.")
                                .foregroundColor(secondaryTextColor)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .listRowBackground(backgroundColor)
                        } else {
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
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 3, leading: 13, bottom: 3, trailing: 13))
                            }
                            if viewModel.isLoading {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                                    .tint(accentColor)
                                    .listRowBackground(backgroundColor)
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                    .scrollContentBackground(.hidden)
                    .background(backgroundColor)
                    .padding(.horizontal)
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
                        title: Text("Fehler").foregroundColor(textColor),
                        message: Text(viewModel.errorMessage).foregroundColor(secondaryTextColor),
                        dismissButton: .default(Text("OK").foregroundColor(accentColor)) { viewModel.resetError() }
                    )
                }
                .task {
                    await viewModel.loadSponsors()
                }
            }
        }
    }
}

struct SponsorRowView: View {
    let sponsor: Sponsor
    let viewModel: SponsorViewModel
    let onDelete: () -> Void
    let isLast: Bool

    // Farben für das dunkle Design
    private let textColor = Color(hex: "#E0E0E0")
    private let secondaryTextColor = Color(hex: "#B0BEC5")
    private let accentColor = Color(hex: "#00C4B4")

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(sponsor.name)
                    .font(.headline)
                    .foregroundColor(textColor)
                if let category = sponsor.category {
                    Text("Kategorie: \(category)")
                        .font(.caption)
                        .foregroundColor(secondaryTextColor)
                }
                if let kontaktTelefon = sponsor.kontaktTelefon {
                    Text("Telefon: \(kontaktTelefon)")
                        .font(.caption)
                        .foregroundColor(secondaryTextColor)
                }
            }
            Spacer()
        }
        .swipeActions {
            Button(role: .destructive, action: onDelete) {
                Label("Löschen", systemImage: "trash")
                    .foregroundColor(.white)
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
