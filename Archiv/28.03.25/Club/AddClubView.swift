import SwiftUI
import FirebaseFirestore
import PhotosUI

struct AddClubView: View {
    @Binding var club: Club
    var onSave: (Club) -> Void
    var onCancel: () -> Void

    @State private var name: String
    @State private var mensLeague: String?
    @State private var womensLeague: String?
    @State private var mensAdresse: String = ""
    @State private var womensAdresse: String = ""
    @State private var mensKontaktTelefon: String = ""
    @State private var womensKontaktTelefon: String = ""
    @State private var mensKontaktEmail: String = ""
    @State private var womensKontaktEmail: String = ""
    @State private var land: String?
    @State private var memberCount: String = ""
    @State private var founded: String = ""
    @State private var logoURL: String = ""
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var logoImage: UIImage? = nil
    @State private var isUploadingImage = false
    @State private var errorMessage: String = ""
    @State private var showingCountryPicker = false

    init(club: Binding<Club>, onSave: @escaping (Club) -> Void, onCancel: @escaping () -> Void) {
        self._club = club
        self.onSave = onSave
        self.onCancel = onCancel
        self._name = State(initialValue: club.wrappedValue.name)
        self._mensLeague = State(initialValue: club.wrappedValue.mensDepartment?.league)
        self._womensLeague = State(initialValue: club.wrappedValue.womensDepartment?.league)
        self._mensAdresse = State(initialValue: club.wrappedValue.mensDepartment?.adresse ?? "")
        self._womensAdresse = State(initialValue: club.wrappedValue.womensDepartment?.adresse ?? "")
        self._mensKontaktTelefon = State(initialValue: club.wrappedValue.mensDepartment?.kontaktTelefon ?? "")
        self._womensKontaktTelefon = State(initialValue: club.wrappedValue.womensDepartment?.kontaktTelefon ?? "")
        self._mensKontaktEmail = State(initialValue: club.wrappedValue.mensDepartment?.kontaktEmail ?? "")
        self._womensKontaktEmail = State(initialValue: club.wrappedValue.womensDepartment?.kontaktEmail ?? "")
        self._land = State(initialValue: club.wrappedValue.sharedInfo?.land)
        self._memberCount = State(initialValue: club.wrappedValue.sharedInfo?.memberCount.map(String.init) ?? "")
        self._founded = State(initialValue: club.wrappedValue.sharedInfo?.founded ?? "")
        self._logoURL = State(initialValue: club.wrappedValue.sharedInfo?.logoURL ?? "")
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Vereinsdaten")) {
                    TextField("Name", text: $name)
                    countryPicker
                    TextField("Mitgliederzahl", text: $memberCount)
                        .keyboardType(.numberPad)
                    TextField("Gegründet", text: $founded)

                    // Bildauswahl und Vorschau
                    PhotosPicker(
                        selection: $selectedPhoto,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        Label("Bild auswählen", systemImage: "photo")
                            .foregroundColor(.blue)
                    }
                    
                    TextField("Oder Bild-URL eingeben", text: $logoURL)
                        .autocapitalization(.none)
                        .keyboardType(.URL)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    if isUploadingImage {
                        ProgressView("Bild wird hochgeladen...")
                    } else if let image = logoImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    } else if !logoURL.isEmpty {
                        AsyncImage(url: URL(string: logoURL)) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 100)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            case .failure:
                                Image(systemName: "photo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 100)
                                    .foregroundColor(.gray)
                            case .empty:
                                ProgressView()
                            @unknown default:
                                Image(systemName: "photo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 100)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                Section(header: Text("Männerabteilung")) {
                    Picker("Liga", selection: $mensLeague) {
                        Text("Keine Liga").tag(String?.none)
                        ForEach(Constants.leaguesMale, id: \.self) { league in
                            Text(league).tag(String?.some(league))
                        }
                    }
                    .pickerStyle(.menu)
                    TextField("Adresse", text: $mensAdresse)
                    TextField("Telefon", text: $mensKontaktTelefon)
                    TextField("E-Mail", text: $mensKontaktEmail)
                }
                Section(header: Text("Frauenabteilung")) {
                    Picker("Liga", selection: $womensLeague) {
                        Text("Keine Liga").tag(String?.none)
                        ForEach(Constants.leaguesFemale, id: \.self) { league in
                            Text(league).tag(String?.some(league))
                        }
                    }
                    .pickerStyle(.menu)
                    TextField("Adresse", text: $womensAdresse)
                    TextField("Telefon", text: $womensKontaktTelefon)
                    TextField("E-Mail", text: $womensKontaktEmail)
                }
            }
            .navigationTitle(club.id == nil ? "Verein anlegen" : "Verein bearbeiten")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { onCancel() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        if validateInputs() {
                            Task {
                                await saveClub()
                            }
                        }
                    }
                    .disabled(name.isEmpty || (mensLeague == nil && womensLeague == nil))
                }
            }
            .alert(isPresented: .constant(!errorMessage.isEmpty)) {
                Alert(title: Text("Fehler"), message: Text(errorMessage), dismissButton: .default(Text("OK")) {
                    errorMessage = ""
                })
            }
            .onChange(of: selectedPhoto) { newPhoto in
                Task {
                    await loadSelectedImage()
                }
            }
        }
    }

    private var countryPicker: some View {
        Button(action: { showingCountryPicker = true }) {
            Text(land ?? "Land auswählen")
                .foregroundColor(land == nil ? .gray : .black)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .sheet(isPresented: $showingCountryPicker) {
            NavigationView {
                MultiPicker(
                    title: "Land auswählen",
                    selection: Binding(
                        get: { [land].compactMap { $0 } },
                        set: { newValue in land = newValue.first }
                    ),
                    options: Constants.nationalities, // Verwende Constants.nationalities
                    isNationalityPicker: false
                )
                .navigationTitle("Land")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Fertig") { showingCountryPicker = false }
                    }
                }
            }
        }
    }

    private func validateInputs() -> Bool {
        if name.isEmpty {
            errorMessage = "Der Vereinsname darf nicht leer sein."
            return false
        }
        if let memberCountInt = Int(memberCount), memberCountInt < 0 {
            errorMessage = "Die Mitgliederzahl darf nicht negativ sein."
            return false
        }
        return true
    }

    private func loadSelectedImage() async {
        guard let photoItem = selectedPhoto else { return }
        do {
            if let data = try await photoItem.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    self.logoImage = image
                    self.logoURL = "" // Reset URL, da ein neues Bild hochgeladen wird
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = "Fehler beim Laden des Bildes: \(error.localizedDescription)"
            }
        }
    }

    private func downloadImage(from urlString: String) async throws -> UIImage {
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        guard let image = UIImage(data: data) else {
            throw URLError(.cannotDecodeContentData)
        }
        return image
    }

    private func saveClub() async {
        do {
            var finalLogoURL = logoURL
            if let image = logoImage {
                await MainActor.run { isUploadingImage = true }
                let documentID = club.id ?? UUID().uuidString // Temporäre ID für neue Vereine
                finalLogoURL = try await FirestoreManager.shared.uploadImage(
                    documentID: documentID,
                    image: image,
                    collection: "club_logos"
                )
            } else if !logoURL.isEmpty {
                // Bild von URL herunterladen und hochladen
                let downloadedImage = try await downloadImage(from: logoURL)
                let documentID = club.id ?? UUID().uuidString
                finalLogoURL = try await FirestoreManager.shared.uploadImage(
                    documentID: documentID,
                    image: downloadedImage,
                    collection: "club_logos"
                )
            }
            await MainActor.run { isUploadingImage = false }

            let mensDepartment = Club.Department(
                league: mensLeague,
                adresse: mensAdresse.isEmpty ? nil : mensAdresse,
                kontaktTelefon: mensKontaktTelefon.isEmpty ? nil : mensKontaktTelefon,
                kontaktEmail: mensKontaktEmail.isEmpty ? nil : mensKontaktEmail,
                funktionäre: club.mensDepartment?.funktionäre ?? [],
                clients: club.mensDepartment?.clients ?? []
            )
            let womensDepartment = Club.Department(
                league: womensLeague,
                adresse: womensAdresse.isEmpty ? nil : womensAdresse,
                kontaktTelefon: womensKontaktTelefon.isEmpty ? nil : womensKontaktTelefon,
                kontaktEmail: womensKontaktEmail.isEmpty ? nil : womensKontaktEmail,
                funktionäre: club.womensDepartment?.funktionäre ?? [],
                clients: club.womensDepartment?.clients ?? []
            )
            let sharedInfo = Club.SharedInfo(
                land: land,
                memberCount: Int(memberCount) ?? nil,
                founded: founded.isEmpty ? nil : founded,
                logoURL: finalLogoURL.isEmpty ? nil : finalLogoURL
            )
            let updatedClub = Club(
                id: club.id,
                name: name,
                mensDepartment: mensLeague == nil && mensAdresse.isEmpty && mensKontaktTelefon.isEmpty && mensKontaktEmail.isEmpty ? nil : mensDepartment,
                womensDepartment: womensLeague == nil && womensAdresse.isEmpty && womensKontaktTelefon.isEmpty && womensKontaktEmail.isEmpty ? nil : womensDepartment,
                sharedInfo: sharedInfo
            )
            onSave(updatedClub)
        } catch {
            await MainActor.run {
                errorMessage = "Fehler beim Speichern: \(error.localizedDescription)"
                isUploadingImage = false
            }
        }
    }
}

#Preview {
    AddClubView(
        club: .constant(Club(name: "Bayern München", mensDepartment: nil, womensDepartment: nil, sharedInfo: nil)),
        onSave: { _ in },
        onCancel: {}
    )
}
