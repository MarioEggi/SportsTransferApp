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

    // Farben für das helle Design
    private let backgroundColor = Color(hex: "#F5F5F5")
    private let cardBackgroundColor = Color(hex: "#E0E0E0")
    private let accentColor = Color(hex: "#00C4B4")
    private let textColor = Color(hex: "#333333")
    private let secondaryTextColor = Color(hex: "#666666")

    init(clubID: String) {
        self.clubID = clubID
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 15) {
                    if let club = club {
                        VStack(spacing: 10) {
                            if isLoadingImage {
                                ProgressView("Lade Logo...")
                                    .tint(accentColor)
                                    .frame(width: 100, height: 100)
                            } else if let image = logoImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(accentColor.opacity(0.3), lineWidth: 1))
                            } else {
                                Image(systemName: "building.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 100, height: 100)
                                    .foregroundColor(secondaryTextColor)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(accentColor.opacity(0.3), lineWidth: 1))
                            }

                            Text(club.name)
                                .font(.title2)
                                .bold()
                                .foregroundColor(textColor)
                        }
                        .padding()

                        List {
                            Section(header: Text("Allgemeine Informationen").foregroundColor(textColor)) {
                                VStack(spacing: 10) {
                                    if let land = club.sharedInfo?.land {
                                        labeledField(label: "Land", value: land)
                                    }
                                    if let memberCount = club.sharedInfo?.memberCount {
                                        labeledField(label: "Mitglieder", value: "\(memberCount)")
                                    }
                                    if let founded = club.sharedInfo?.founded {
                                        labeledField(label: "Gegründet", value: founded)
                                    }
                                    if let clubDocumentURL = club.sharedInfo?.clubDocumentURL {
                                        labeledField(label: "Dokument", value: clubDocumentURL.split(separator: "/").last.map(String.init) ?? "")
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

                            if let mensDepartment = club.mensDepartment {
                                Section(header: Text("Männerabteilung").foregroundColor(textColor)) {
                                    VStack(spacing: 10) {
                                        if let league = mensDepartment.league {
                                            labeledField(label: "Liga", value: league)
                                        }
                                        if let adresse = mensDepartment.adresse {
                                            labeledField(label: "Adresse", value: adresse)
                                        }
                                        if let kontaktTelefon = mensDepartment.kontaktTelefon {
                                            labeledField(label: "Telefon", value: kontaktTelefon)
                                        }
                                        if let kontaktEmail = mensDepartment.kontaktEmail {
                                            labeledField(label: "E-Mail", value: kontaktEmail)
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

                            if let womensDepartment = club.womensDepartment {
                                Section(header: Text("Frauenabteilung").foregroundColor(textColor)) {
                                    VStack(spacing: 10) {
                                        if let league = womensDepartment.league {
                                            labeledField(label: "Liga", value: league)
                                        }
                                        if let adresse = womensDepartment.adresse {
                                            labeledField(label: "Adresse", value: adresse)
                                        }
                                        if let kontaktTelefon = womensDepartment.kontaktTelefon {
                                            labeledField(label: "Telefon", value: kontaktTelefon)
                                        }
                                        if let kontaktEmail = womensDepartment.kontaktEmail {
                                            labeledField(label: "E-Mail", value: kontaktEmail)
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

                            Section(header: Text("Funktionäre").foregroundColor(textColor)) {
                                if funktionäre.isEmpty {
                                    Text("Keine Funktionäre vorhanden.")
                                        .foregroundColor(secondaryTextColor)
                                        .padding(.vertical, 8)
                                } else {
                                    ForEach(funktionäre) { funktionär in
                                        VStack(alignment: .leading, spacing: 5) {
                                            Text("\(funktionär.vorname) \(funktionär.name)")
                                                .font(.subheadline)
                                                .foregroundColor(textColor)
                                            if let abteilung = funktionär.abteilung {
                                                Text("Abteilung: \(abteilung)")
                                                    .font(.caption)
                                                    .foregroundColor(secondaryTextColor)
                                            }
                                            if let position = funktionär.positionImVerein {
                                                Text("Position: \(position)")
                                                    .font(.caption)
                                                    .foregroundColor(secondaryTextColor)
                                            }
                                        }
                                        .padding(.vertical, 8)
                                    }
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
                        .listStyle(PlainListStyle())
                        .listRowInsets(EdgeInsets(top: 3, leading: 13, bottom: 3, trailing: 13))
                        .scrollContentBackground(.hidden)
                        .background(backgroundColor)
                        .foregroundColor(textColor)

                        Button(action: { showingEditSheet = true }) {
                            Text("Bearbeiten")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(accentColor)
                                .foregroundColor(textColor)
                                .cornerRadius(10)
                        }
                        .padding()
                    } else {
                        Text("Lade Verein...")
                            .foregroundColor(secondaryTextColor)
                            .padding()
                    }
                }
                .background(backgroundColor)
                .navigationTitle(club?.name ?? "Verein")
                .navigationBarTitleDisplayMode(.inline)
                .foregroundColor(textColor)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { showingEditSheet = true }) {
                            Image(systemName: "pencil")
                                .foregroundColor(accentColor)
                        }
                    }
                }
                .sheet(isPresented: $showingEditSheet) {
                    EditClubView(
                        club: Binding(
                            get: { club ?? Club(id: clubID, name: "", mensDepartment: nil, womensDepartment: nil, sharedInfo: nil) },
                            set: { newClub in self.club = newClub }
                        ),
                        onSave: { updatedClub in
                            Task {
                                do {
                                    try await FirestoreManager.shared.updateClub(club: updatedClub)
                                    await MainActor.run {
                                        self.club = updatedClub
                                        showingEditSheet = false
                                    }
                                    await loadLogoImage()
                                } catch {
                                    errorMessage = "Fehler beim Aktualisieren des Vereins: \(error.localizedDescription)"
                                }
                            }
                        },
                        onCancel: { showingEditSheet = false }
                    )
                }
                .alert(isPresented: .constant(!errorMessage.isEmpty)) {
                    Alert(
                        title: Text("Fehler").foregroundColor(textColor),
                        message: Text(errorMessage).foregroundColor(secondaryTextColor),
                        dismissButton: .default(Text("OK").foregroundColor(accentColor)) { errorMessage = "" }
                    )
                }
                .task {
                    await loadClub()
                    await loadFunktionäre()
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
            let (loadedFunktionäre, _) = try await FirestoreManager.shared.getFunktionäre(lastDocument: nil, limit: 1000)
            await MainActor.run {
                self.funktionäre = loadedFunktionäre.filter { $0.vereinID == clubID }
            }
        } catch {
            await MainActor.run {
                errorMessage = "Fehler beim Laden der Funktionäre: \(error.localizedDescription)"
            }
        }
    }
}

#Preview {
    ClubView(clubID: "exampleClubID")
}
