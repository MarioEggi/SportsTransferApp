import SwiftUI

struct FunktionärView: View {
    @Binding var funktionär: Funktionär
    @State private var image: UIImage? = nil
    @State private var showingEditSheet = false
    @State private var clubName: String? = nil
    @State private var clubLogoURL: String? = nil

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    var body: some View {
        NavigationStack {
            VStack {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.gray)
                        .clipShape(Circle())
                }

                Text("\(funktionär.vorname) \(funktionär.name)\(calculateAge().map { ", \($0) Jahre" } ?? "")")
                    .font(.title)
                    .padding()
                    .foregroundColor(.white)

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
                                        .foregroundColor(.gray)
                                        .clipShape(Circle())
                                @unknown default:
                                    Image(systemName: "building.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 20, height: 20)
                                        .foregroundColor(.gray)
                                        .clipShape(Circle())
                                }
                            }
                        } else {
                            Image(systemName: "building.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                                .foregroundColor(.gray)
                                .clipShape(Circle())
                        }
                        Text(clubName ?? vereinID)
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                } else {
                    Text("Ohne Verein")
                        .font(.headline)
                        .foregroundColor(.white)
                }

                if let position = funktionär.positionImVerein {
                    Text("Position: \(position)")
                        .font(.subheadline)
                        .foregroundColor(.white)
                }

                if let abteilung = funktionär.abteilung {
                    Text("Abteilung: \(abteilung)")
                        .font(.subheadline)
                        .foregroundColor(.white)
                }

                if let mannschaft = funktionär.mannschaft {
                    Text("Mannschaft: \(mannschaft)")
                        .font(.subheadline)
                        .foregroundColor(.white)
                }

                if let nationalitaet = funktionär.nationalitaet, !nationalitaet.isEmpty {
                    Text("Nationalität: \(nationalitaet.joined(separator: ", "))")
                        .font(.subheadline)
                        .foregroundColor(.white)
                }

                if let kontaktEmail = funktionär.kontaktEmail {
                    Text("E-Mail: \(kontaktEmail)")
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
                if let kontaktTelefon = funktionär.kontaktTelefon {
                    Text("Telefon: \(kontaktTelefon)")
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
                if let adresse = funktionär.adresse {
                    Text("Adresse: \(adresse)")
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
                if let documentURL = funktionär.functionaryDocumentURL {
                    Text("Dokument: \(documentURL.split(separator: "/").last ?? "")")
                        .font(.subheadline)
                        .foregroundColor(.white)
                }

                HStack {
                    Spacer()
                    Button(action: { showingEditSheet = true }) {
                        Image(systemName: "pencil")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                    }
                    .sheet(isPresented: $showingEditSheet) {
                        EditFunktionärView(
                            funktionär: $funktionär,
                            onSave: { updatedFunktionär in
                                Task {
                                    do {
                                        try await FirestoreManager.shared.updateFunktionär(funktionär: updatedFunktionär)
                                        await loadClubDetails()
                                        print("Funktionär erfolgreich aktualisiert")
                                    } catch {
                                        print("Fehler beim Aktualisieren: \(error.localizedDescription)")
                                    }
                                }
                                showingEditSheet = false
                            },
                            onCancel: { showingEditSheet = false }
                        )
                    }
                    Spacer()
                }
                .padding(.bottom)

                Spacer()
            }
            .padding()
            .background(Color.black)
            .navigationTitle("\(funktionär.vorname) \(funktionär.name)")
            .foregroundColor(.white)
            .task {
                loadImage()
                await loadClubDetails()
            }
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
            let (clubs, _) = try await FirestoreManager.shared.getClubs(limit: 1000)
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
