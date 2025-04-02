import SwiftUI

struct FunktionärView: View {
    @Binding var funktionär: Funktionär
    @State private var image: UIImage? = nil
    @State private var showingEditSheet = false
    @State private var clubName: String? = nil
    @State private var clubLogoURL: String? = nil

    // Farben für das helle Design
    private let backgroundColor = Color(hex: "#F5F5F5")
    private let cardBackgroundColor = Color(hex: "#E0E0E0")
    private let accentColor = Color(hex: "#00C4B4")
    private let textColor = Color(hex: "#333333")
    private let secondaryTextColor = Color(hex: "#666666")

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 15) {
                    VStack(spacing: 10) {
                        if let image = image {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(accentColor.opacity(0.3), lineWidth: 1))
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .foregroundColor(secondaryTextColor)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(accentColor.opacity(0.3), lineWidth: 1))
                        }

                        Text("\(funktionär.vorname) \(funktionär.name)\(calculateAge().map { ", \($0) Jahre" } ?? "")")
                            .font(.title2)
                            .bold()
                            .foregroundColor(textColor)

                        if let vereinID = funktionär.vereinID {
                            HStack(spacing: 10) {
                                if let logoURL = clubLogoURL, let url = URL(string: logoURL) {
                                    AsyncImage(url: url) { phase in
                                        switch phase {
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 20, height: 20)
                                                .clipShape(Circle())
                                        case .failure, .empty:
                                            Image(systemName: "building.fill")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 20, height: 20)
                                                .foregroundColor(secondaryTextColor)
                                                .clipShape(Circle())
                                        @unknown default:
                                            Image(systemName: "building.fill")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 20, height: 20)
                                                .foregroundColor(secondaryTextColor)
                                                .clipShape(Circle())
                                        }
                                    }
                                } else {
                                    Image(systemName: "building.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 20, height: 20)
                                        .foregroundColor(secondaryTextColor)
                                        .clipShape(Circle())
                                }
                                Text(clubName ?? vereinID)
                                    .font(.headline)
                                    .foregroundColor(textColor)
                            }
                        } else {
                            Text("Ohne Verein")
                                .font(.headline)
                                .foregroundColor(textColor)
                        }
                    }
                    .padding()

                    List {
                        Section(header: Text("Details").foregroundColor(textColor)) {
                            VStack(spacing: 10) {
                                if let position = funktionär.positionImVerein {
                                    labeledField(label: "Position", value: position)
                                }
                                if let abteilung = funktionär.abteilung {
                                    labeledField(label: "Abteilung", value: abteilung)
                                }
                                if let mannschaft = funktionär.mannschaft {
                                    labeledField(label: "Mannschaft", value: mannschaft)
                                }
                                if let nationalitaet = funktionär.nationalitaet, !nationalitaet.isEmpty {
                                    labeledField(label: "Nationalität", value: nationalitaet.joined(separator: ", "))
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

                        Section(header: Text("Kontaktdaten").foregroundColor(textColor)) {
                            VStack(spacing: 10) {
                                if let kontaktEmail = funktionär.kontaktEmail {
                                    labeledField(label: "E-Mail", value: kontaktEmail)
                                }
                                if let kontaktTelefon = funktionär.kontaktTelefon {
                                    labeledField(label: "Telefon", value: kontaktTelefon)
                                }
                                if let adresse = funktionär.adresse {
                                    labeledField(label: "Adresse", value: adresse)
                                }
                                if let documentURL = funktionär.functionaryDocumentURL {
                                    labeledField(label: "Dokument", value: documentURL.split(separator: "/").last.map(String.init) ?? "")
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
                }
                .background(backgroundColor)
                .navigationTitle("\(funktionär.vorname) \(funktionär.name)")
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
                    EditFunktionärView(
                        funktionär: $funktionär,
                        onSave: { updatedFunktionär in
                            Task {
                                do {
                                    try await FirestoreManager.shared.updateFunktionär(funktionär: updatedFunktionär)
                                    await loadClubDetails()
                                    loadImage()
                                    showingEditSheet = false
                                } catch {
                                    print("Fehler beim Aktualisieren: \(error.localizedDescription)")
                                }
                            }
                        },
                        onCancel: { showingEditSheet = false }
                    )
                }
                .task {
                    loadImage()
                    await loadClubDetails()
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

    private func loadImage() {
        if let profilbildURL = funktionär.profilbildURL, let url = URL(string: profilbildURL) {
            URLSession.shared.dataTask(with: url) { data, _, _ in
                if let data = data, let loadedImage = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self.image = loadedImage
                    }
                }
            }.resume()
        }
    }

    private func loadClubDetails() async {
        guard let vereinID = funktionär.vereinID else { return }
        do {
            let (clubs, _) = try await FirestoreManager.shared.getClubs(lastDocument: nil, limit: 1000)
            if let club = clubs.first(where: { $0.id == vereinID }) {
                await MainActor.run {
                    clubName = club.name
                    clubLogoURL = club.sharedInfo?.logoURL
                }
            }
        } catch {
            print("Fehler beim Laden der Vereinsdetails: \(error.localizedDescription)")
        }
    }

    private func calculateAge() -> Int? {
        guard let birthDate = funktionär.geburtsdatum else { return nil }
        let calendar = Calendar.current
        let now = Date()
        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: now)
        return ageComponents.year
    }
}

#Preview {
    FunktionärView(funktionär: .constant(Funktionär(name: "Mustermann", vorname: "Max", abteilung: "Männer", positionImVerein: "Trainer")))
}
