import SwiftUI
import FirebaseFirestore

struct ClubView: View {
    let clubID: String
    @State private var club: Club?
    @State private var logoImage: UIImage? = nil
    @State private var isLoadingImage = false
    @State private var funktionäre: [Funktionär] = []
    @State private var errorMessage: String = ""
    @State private var showingEditSheet = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let club = club {
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

                    Section(header: Text("Allgemeine Informationen").font(.headline)) {
                        if let land = club.sharedInfo?.land {
                            Label(land, systemImage: "globe")
                                .font(.subheadline)
                        }
                        if let memberCount = club.sharedInfo?.memberCount {
                            Label("Mitglieder: \(memberCount)", systemImage: "person.2")
                                .font(.subheadline)
                        }
                        if let founded = club.sharedInfo?.founded {
                            Label("Gegründet: \(founded)", systemImage: "calendar")
                                .font(.subheadline)
                        }
                    }

                    if let mensDepartment = club.mensDepartment {
                        Section(header: Text("Männerabteilung").font(.headline)) {
                            if let league = mensDepartment.league {
                                Label("Liga: \(league)", systemImage: "sportscourt")
                                    .font(.subheadline)
                            }
                            if let adresse = mensDepartment.adresse {
                                Label("Adresse: \(adresse)", systemImage: "mappin.and.ellipse")
                                    .font(.subheadline)
                            }
                            if let kontaktTelefon = mensDepartment.kontaktTelefon {
                                Label("Telefon: \(kontaktTelefon)", systemImage: "phone")
                                    .font(.subheadline)
                            }
                            if let kontaktEmail = mensDepartment.kontaktEmail {
                                Label("E-Mail: \(kontaktEmail)", systemImage: "envelope")
                                    .font(.subheadline)
                            }
                        }
                    }

                    if let womensDepartment = club.womensDepartment {
                        Section(header: Text("Frauenabteilung").font(.headline)) {
                            if let league = womensDepartment.league {
                                Label("Liga: \(league)", systemImage: "sportscourt")
                                    .font(.subheadline)
                            }
                            if let adresse = womensDepartment.adresse {
                                Label("Adresse: \(adresse)", systemImage: "mappin.and.ellipse")
                                    .font(.subheadline)
                            }
                            if let kontaktTelefon = womensDepartment.kontaktTelefon {
                                Label("Telefon: \(kontaktTelefon)", systemImage: "phone")
                                    .font(.subheadline)
                            }
                            if let kontaktEmail = womensDepartment.kontaktEmail {
                                Label("E-Mail: \(kontaktEmail)", systemImage: "envelope")
                                    .font(.subheadline)
                            }
                        }
                    }

                    Section(header: Text("Funktionäre").font(.headline)) {
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
                                    if let position = funktionär.positionImVerein {
                                        Text("Position: \(position)")
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
                        AddClubView(club: Binding(
                            get: { club },
                            set: { newClub in self.club = newClub }
                        ), onSave: { updatedClub in
                            Task {
                                do {
                                    try await FirestoreManager.shared.updateClub(club: updatedClub)
                                    await MainActor.run {
                                        self.club = updatedClub
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
                } else {
                    Text("Lade Verein...")
                }
            }
            .padding()
        }
        .navigationTitle(club?.name ?? "Verein")
        .alert(isPresented: .constant(!errorMessage.isEmpty)) {
            Alert(title: Text("Fehler"), message: Text(errorMessage), dismissButton: .default(Text("OK")) {
                errorMessage = ""
            })
        }
        .task {
            await loadClub()
            await loadFunktionäre()
        }
    }

    private func loadClub() async {
        do {
            let (clubs, _) = try await FirestoreManager.shared.getClubs(lastDocument: nil, limit: 1000)
            await MainActor.run {
                self.club = clubs.first { $0.id == clubID }
            }
            await loadLogoImage()
        } catch {
            await MainActor.run {
                errorMessage = "Fehler beim Laden des Vereins: \(error.localizedDescription)"
            }
        }
    }

    private func loadLogoImage() async {
        guard let club = club else { return }
        await MainActor.run { isLoadingImage = true }
        if let logoURL = club.sharedInfo?.logoURL, let url = URL(string: logoURL) {
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
                        self.errorMessage = "Kein gültiges Bild gefunden."
                    }
                }
            } catch {
                await MainActor.run {
                    self.logoImage = nil
                    self.isLoadingImage = false
                    self.errorMessage = "Fehler beim Laden des Logos: \(error.localizedDescription)"
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
            let (loadedFunktionäre, _) = try await FirestoreManager.shared.getFunktionäre(lastDocument: nil, limit: 1000)
            await MainActor.run {
                self.funktionäre = loadedFunktionäre.filter { $0.vereinID == clubID }
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Fehler beim Laden der Funktionäre: \(error.localizedDescription)"
            }
        }
    }
}

#Preview {
    ClubView(clubID: "exampleClubID")
}
