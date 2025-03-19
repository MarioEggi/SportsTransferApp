import SwiftUI
import FirebaseFirestore

struct SponsorListView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var sponsors: [Sponsor] = []
    @State private var showingAddSponsor = false
    @State private var isEditing = false
    @State private var errorMessage: String = ""
    @State private var newSponsor = Sponsor(
        id: nil,
        name: "",
        kontaktTelefon: nil,
        kontaktEmail: nil,
        adresse: nil,
        gesponsorteVereine: nil
    )

    var body: some View {
        NavigationStack {
            List {
                ForEach(sponsors) { sponsor in
                    VStack(alignment: .leading) {
                        Text(sponsor.name)
                            .font(.headline)
                        if let kontaktTelefon = sponsor.kontaktTelefon {
                            Text("Telefon: \(kontaktTelefon)")
                        }
                        if let kontaktEmail = sponsor.kontaktEmail {
                            Text("E-Mail: \(kontaktEmail)")
                        }
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            Task {
                                await deleteSponsor(sponsor)
                            }
                        } label: {
                            Label("Löschen", systemImage: "trash")
                        }
                        Button {
                            isEditing = true
                            newSponsor = sponsor
                            showingAddSponsor = true
                        } label: {
                            Label("Bearbeiten", systemImage: "pencil")
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Sponsor bearbeiten" : "Sponsorübersicht")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Neuen Sponsor anlegen") {
                        if authManager.isLoggedIn {
                            showingAddSponsor = true
                            isEditing = false
                            newSponsor = Sponsor(
                                id: nil,
                                name: "",
                                kontaktTelefon: nil,
                                kontaktEmail: nil,
                                adresse: nil,
                                gesponsorteVereine: nil
                            )
                        } else {
                            errorMessage = "Du musst angemeldet sein, um einen neuen Sponsor anzulegen."
                        }
                    }
                    .disabled(!authManager.isLoggedIn)
                }
            }
            .alert(isPresented: .constant(!errorMessage.isEmpty)) {
                Alert(title: Text("Fehler"), message: Text(errorMessage), dismissButton: .default(Text("OK")) {
                    errorMessage = ""
                })
            }
            .sheet(isPresented: $showingAddSponsor) {
                AddSponsorView(sponsor: $newSponsor, isEditing: isEditing, onSave: { sponsor in
                    Task {
                        if authManager.isLoggedIn {
                            if isEditing {
                                await updateSponsor(sponsor)
                            } else {
                                await createSponsor(sponsor)
                            }
                        } else {
                            await MainActor.run {
                                errorMessage = "Du musst angemeldet sein, um den Sponsor zu speichern."
                            }
                        }
                        await MainActor.run {
                            showingAddSponsor = false
                            isEditing = false
                            newSponsor = Sponsor(
                                id: nil,
                                name: "",
                                kontaktTelefon: nil,
                                kontaktEmail: nil,
                                adresse: nil,
                                gesponsorteVereine: nil
                            )
                        }
                    }
                }, onCancel: {
                    Task {
                        await MainActor.run {
                            showingAddSponsor = false
                            isEditing = false
                            newSponsor = Sponsor(
                                id: nil,
                                name: "",
                                kontaktTelefon: nil,
                                kontaktEmail: nil,
                                adresse: nil,
                                gesponsorteVereine: nil
                            )
                        }
                    }
                })
            }
            .task {
                await loadSponsors()
            }
        }
    }

    private func loadSponsors() async {
        do {
            let loadedSponsors = try await FirestoreManager.shared.getSponsors()
            await MainActor.run {
                sponsors = loadedSponsors
            }
        } catch {
            await MainActor.run {
                errorMessage = "Fehler beim Laden der Sponsoren: \(error.localizedDescription)"
            }
        }
    }

    private func createSponsor(_ sponsor: Sponsor) async {
        do {
            try await FirestoreManager.shared.createSponsor(sponsor: sponsor)
            await loadSponsors()
        } catch {
            await MainActor.run {
                errorMessage = "Fehler beim Hinzufügen des Sponsors: \(error.localizedDescription)"
            }
        }
    }

    private func updateSponsor(_ sponsor: Sponsor) async {
        do {
            try await FirestoreManager.shared.updateSponsor(sponsor: sponsor)
            await loadSponsors()
        } catch {
            await MainActor.run {
                errorMessage = "Fehler beim Aktualisieren des Sponsors: \(error.localizedDescription)"
            }
        }
    }

    private func deleteSponsor(_ sponsor: Sponsor) async {
        guard let id = sponsor.id else { return }
        do {
            try await FirestoreManager.shared.deleteSponsor(sponsorID: id)
            await loadSponsors()
        } catch {
            await MainActor.run {
                errorMessage = "Fehler beim Löschen des Sponsors: \(error.localizedDescription)"
            }
        }
    }
}

struct AddSponsorView: View {
    @Binding var sponsor: Sponsor
    var isEditing: Bool
    var onSave: (Sponsor) -> Void
    var onCancel: () -> Void

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Sponsordaten")) {
                    TextField("Name", text: $sponsor.name)
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
            }
            .navigationTitle(isEditing ? "Sponsor bearbeiten" : "Sponsor anlegen")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { onCancel() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        onSave(sponsor)
                    }
                }
            }
        }
    }
}

#Preview {
    SponsorListView()
        .environmentObject(AuthManager())
}
