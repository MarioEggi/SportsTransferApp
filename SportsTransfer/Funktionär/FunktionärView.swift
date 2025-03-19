import SwiftUI
import FirebaseFirestore

struct FunktionärView: View {
    @Binding var funktionär: Funktionär
    @State private var image: UIImage? = nil
    @State private var showingEditSheet = false

    var body: some View {
        // Entpacke den wrappedValue für einfacheren Zugriff
        let funktionärValue = $funktionär.wrappedValue

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

                Text("\(funktionärValue.vorname) \(funktionärValue.name)\(calculateAge().map { ", \($0) Jahre" } ?? "")")
                    .font(.title)
                    .padding()

                if let vereinID = funktionärValue.vereinID {
                    Text("Verein: \(vereinID)")
                        .font(.headline)
                } else {
                    Text("Ohne Verein")
                        .font(.headline)
                }

                if let position = funktionärValue.positionImVerein {
                    Text("Position: \(position)")
                        .font(.subheadline)
                }

                if let mannschaft = funktionärValue.mannschaft {
                    Text("Mannschaft: \(mannschaft)")
                        .font(.subheadline)
                }

                if let kontaktEmail = funktionärValue.kontaktEmail {
                    Text("E-Mail: \(kontaktEmail)")
                        .font(.subheadline)
                }
                if let kontaktTelefon = funktionärValue.kontaktTelefon {
                    Text("Telefon: \(kontaktTelefon)")
                        .font(.subheadline)
                }
                if let adresse = funktionärValue.adresse {
                    Text("Adresse: \(adresse)")
                        .font(.subheadline)
                }

                HStack {
                    Spacer()
                    Button(action: { showingEditSheet = true }) {
                        Image(systemName: "pencil")
                            .font(.system(size: 16))
                            .foregroundColor(.blue)
                    }
                    .sheet(isPresented: $showingEditSheet) {
                        AddFunktionärView(
                            funktionär: $funktionär,
                            onSave: { updatedFunktionär in
                                Task {
                                    do {
                                        try await FirestoreManager.shared.updateFunktionär(funktionär: updatedFunktionär)
                                        print("Funktionär erfolgreich aktualisiert")
                                    } catch {
                                        print("Fehler beim Aktualisieren: \(error.localizedDescription)")
                                    }
                                }
                                showingEditSheet = false
                            },
                            onCancel: {
                                showingEditSheet = false
                            }
                        )
                    }
                    Spacer()
                }
                .padding(.bottom)

                Spacer()
            }
            .navigationTitle("\(funktionärValue.vorname) \(funktionärValue.name)")
            .onAppear {
                loadImage()
            }
        }
    }

    private func loadImage() {
        let funktionärValue = $funktionär.wrappedValue
        if let profilbildURL = funktionärValue.profilbildURL, let url = URL(string: profilbildURL) {
            URLSession.shared.dataTask(with: url) { data, _, _ in
                if let data = data, let loadedImage = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self.image = loadedImage
                    }
                }
            }.resume()
        }
    }

    private func calculateAge() -> Int? {
        let funktionärValue = $funktionär.wrappedValue
        guard let birthDate = funktionärValue.geburtsdatum else { return nil }
        let calendar = Calendar.current
        let now = Date()
        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: now)
        return ageComponents.year
    }
}

#Preview {
    FunktionärView(funktionär: .constant(Funktionär(
        id: nil,
        name: "Mustermann",
        vorname: "Max",
        abteilung: "Männer",
        vereinID: nil,
        kontaktTelefon: nil,
        kontaktEmail: nil,
        adresse: nil,
        clients: nil,
        profilbildURL: nil,
        geburtsdatum: nil,
        positionImVerein: "Trainer",
        mannschaft: nil
    )))
}
