import SwiftUI

struct ClubView: View {
    @Binding var club: Club
    @State private var showingEditSheet = false
    @State private var logoImage: UIImage? = nil // Zustand für das geladene Bild
    @State private var isLoadingImage = false // Zustand für den Ladevorgang
    @State private var funktionäre: [Funktionär] = [] // Zustand für Funktionäre
    @State private var errorMessage: String = "" // Neue Variable für Fehlerbehandlung

    var body: some View {
        VStack(spacing: 10) {
            if isLoadingImage {
                ProgressView("Lade Logo...")
                    .frame(width: 100, height: 100)
            } else if let image = logoImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
            } else {
                Image(systemName: "building.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.gray)
                    .clipShape(Circle())
            }

            Text(club.name)
                .font(.title)
                .bold()

            if let league = club.league {
                Text("Liga: \(league)")
                    .font(.headline)
            }
            if let memberCount = club.memberCount {
                Text("Mitglieder: \(memberCount)")
                    .font(.headline)
            }
            if let founded = club.founded {
                Text("Gegründet: \(founded)")
                    .font(.headline)
            }
            if let kontaktTelefon = club.kontaktTelefon {
                Text("Telefon: \(kontaktTelefon)")
                    .font(.headline)
            }
            if let kontaktEmail = club.kontaktEmail {
                Text("E-Mail: \(kontaktEmail)")
                    .font(.headline)
            }
            if let adresse = club.adresse {
                Text("Adresse: \(adresse)")
                    .font(.headline)
            }
            if let land = club.land {
                Text("Land: \(land)")
                    .font(.headline)
            }

            // Anzeige der Funktionäre
            Section(header: Text("Funktionäre")) {
                if funktionäre.isEmpty {
                    Text("Keine Funktionäre vorhanden.")
                        .foregroundColor(.gray)
                } else {
                    ForEach(funktionäre) { funktionär in
                        VStack(alignment: .leading) {
                            Text("\(funktionär.vorname) \(funktionär.name)")
                            if let abteilung = funktionär.abteilung {
                                Text("Abteilung: \(abteilung)")
                            }
                        }
                        .padding(.vertical, 5)
                    }
                }
            }

            Button(action: { showingEditSheet = true }) {
                Text("Bearbeiten")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .sheet(isPresented: $showingEditSheet) {
                EditClubView(club: $club, onSave: { updatedClub in
                    Task {
                        do {
                            try await FirestoreManager.shared.updateClub(club: updatedClub)
                            await MainActor.run {
                                club = updatedClub
                                print("Verein erfolgreich aktualisiert")
                            }
                        } catch {
                            await MainActor.run {
                                errorMessage = "Fehler beim Aktualisieren des Vereins: \(error.localizedDescription)"
                            }
                        }
                        await MainActor.run {
                            showingEditSheet = false
                        }
                    }
                }, onCancel: {
                    showingEditSheet = false
                })
            }

            Spacer()
        }
        .padding()
        .navigationTitle(club.name)
        .alert(isPresented: .constant(!errorMessage.isEmpty)) { // Alert für Fehleranzeige
            Alert(title: Text("Fehler"), message: Text(errorMessage), dismissButton: .default(Text("OK")) {
                errorMessage = ""
            })
        }
        .task {
            await loadLogoImage()
            await loadFunktionäre()
        }
    }

    init(club: Binding<Club>) {
        self._club = club
    }

    private func loadLogoImage() async {
        await MainActor.run {
            isLoadingImage = true
        }
        if let logoURL = club.logoURL, let url = URL(string: logoURL) {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let image = UIImage(data: data) {
                    await MainActor.run {
                        self.logoImage = image
                        self.isLoadingImage = false
                    }
                } else {
                    await MainActor.run {
                        self.logoImage = nil
                        self.isLoadingImage = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.logoImage = nil
                    self.isLoadingImage = false
                }
            }
        } else {
            await MainActor.run {
                self.logoImage = nil
                self.isLoadingImage = false
            }
        }
    }

    private func loadFunktionäre() async {
        do {
            let loadedFunktionäre = try await FirestoreManager.shared.getFunktionäre()
            await MainActor.run {
                self.funktionäre = loadedFunktionäre.filter {
                    $0.vereinID == club.name && $0.abteilung == club.abteilung
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = "Fehler beim Laden der Funktionäre: \(error.localizedDescription)"
            }
        }
    }
}

#Preview {
    let club = Club(name: "Bayern München", league: "1. Bundesliga", memberCount: 400000, founded: "1900")
    ClubView(club: .constant(club))
}
