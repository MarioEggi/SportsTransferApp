import SwiftUI
import FirebaseFirestore
import PhotosUI

struct AddFunktionärView: View {
    @Binding var funktionär: Funktionär
    let onSave: (Funktionär) -> Void
    let onCancel: () -> Void

    @State private var name: String
    @State private var vorname: String
    @State private var vereinID: String?
    @State private var abteilung: String?
    @State private var positionImVerein: String?
    @State private var kontaktTelefon: String?
    @State private var kontaktEmail: String?
    @State private var adresse: String?
    @State private var geburtsdatum: Date?
    @State private var mannschaft: String?
    @State private var clubOptions: [Club] = []
    @State private var showingNationalityPicker = false
    @State private var selectedNationalities: [String]
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var profileImage: UIImage? = nil
    @State private var isUploadingImage = false
    @State private var imageURL: String = ""
    @State private var errorMessage: String = ""

    init(funktionär: Binding<Funktionär>, onSave: @escaping (Funktionär) -> Void, onCancel: @escaping () -> Void) {
        self._funktionär = funktionär
        self.onSave = onSave
        self.onCancel = onCancel
        self._name = State(initialValue: funktionär.wrappedValue.name)
        self._vorname = State(initialValue: funktionär.wrappedValue.vorname)
        self._vereinID = State(initialValue: funktionär.wrappedValue.vereinID)
        self._abteilung = State(initialValue: funktionär.wrappedValue.abteilung)
        self._positionImVerein = State(initialValue: funktionär.wrappedValue.positionImVerein)
        self._kontaktTelefon = State(initialValue: funktionär.wrappedValue.kontaktTelefon)
        self._kontaktEmail = State(initialValue: funktionär.wrappedValue.kontaktEmail)
        self._adresse = State(initialValue: funktionär.wrappedValue.adresse)
        self._geburtsdatum = State(initialValue: funktionär.wrappedValue.geburtsdatum)
        self._mannschaft = State(initialValue: funktionär.wrappedValue.mannschaft)
        self._selectedNationalities = State(initialValue: funktionär.wrappedValue.nationalitaet ?? [])
    }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Name", text: $name)
                        .foregroundColor(.white) // Weiße Schrift
                    TextField("Vorname", text: $vorname)
                        .foregroundColor(.white) // Weiße Schrift
                    Picker("Verein", selection: $vereinID) {
                        Text("Kein Verein").tag(String?.none)
                        ForEach(clubOptions) { club in
                            Text(club.name).tag(club.id as String?)
                        }
                    }
                    .pickerStyle(.menu)
                    .foregroundColor(.white) // Weiße Schrift
                    .accentColor(.white) // Weiße Akzente
                    .onChange(of: vereinID) { _ in abteilung = nil }

                    if let selectedVereinID = vereinID,
                       let selectedClub = clubOptions.first(where: { $0.id == selectedVereinID }) {
                        Picker("Abteilung", selection: $abteilung) {
                            Text("Keine Abteilung").tag(String?.none)
                            if selectedClub.mensDepartment != nil {
                                Text("Männer").tag("Männer" as String?)
                            }
                            if selectedClub.womensDepartment != nil {
                                Text("Frauen").tag("Frauen" as String?)
                            }
                        }
                        .pickerStyle(.menu)
                        .foregroundColor(.white) // Weiße Schrift
                        .accentColor(.white) // Weiße Akzente
                    }

                    Picker("Position im Verein", selection: $positionImVerein) {
                        Text("Keine Position").tag(String?.none)
                        ForEach(Constants.functionaryPositionOptions, id: \.self) { position in
                            Text(position).tag(String?.some(position))
                        }
                    }
                    .pickerStyle(.menu)
                    .foregroundColor(.white) // Weiße Schrift
                    .accentColor(.white) // Weiße Akzente

                    Button(action: { showingNationalityPicker = true }) {
                        Text(selectedNationalities.isEmpty ? "Nationalitäten auswählen" : selectedNationalities.joined(separator: ", "))
                            .foregroundColor(selectedNationalities.isEmpty ? .gray : .white) // Weiße Schrift
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .sheet(isPresented: $showingNationalityPicker) {
                        NavigationView {
                            MultiPicker(
                                title: "Nationalitäten auswählen",
                                selection: $selectedNationalities,
                                options: Constants.nationalities,
                                isNationalityPicker: true
                            )
                            .navigationTitle("Nationalitäten")
                            .foregroundColor(.white) // Weiße Schrift
                            .toolbar {
                                ToolbarItem(placement: .topBarTrailing) {
                                    Button("Fertig") {
                                        showingNationalityPicker = false
                                    }
                                    .foregroundColor(.white) // Weiße Schrift
                                }
                            }
                            .background(Color.black) // Schwarzer Hintergrund
                        }
                    }

                    TextField("Telefon", text: Binding(
                        get: { kontaktTelefon ?? "" },
                        set: { kontaktTelefon = $0.isEmpty ? nil : $0 }
                    ))
                        .foregroundColor(.white) // Weiße Schrift
                    TextField("E-Mail", text: Binding(
                        get: { kontaktEmail ?? "" },
                        set: { kontaktEmail = $0.isEmpty ? nil : $0 }
                    ))
                        .foregroundColor(.white) // Weiße Schrift
                    TextField("Adresse", text: Binding(
                        get: { adresse ?? "" },
                        set: { adresse = $0.isEmpty ? nil : $0 }
                    ))
                        .foregroundColor(.white) // Weiße Schrift
                    DatePicker("Geburtsdatum", selection: Binding(
                        get: { geburtsdatum ?? Date() },
                        set: { geburtsdatum = $0 }
                    ), displayedComponents: .date)
                        .foregroundColor(.white) // Weiße Schrift
                        .accentColor(.white) // Weiße Akzente
                    TextField("Mannschaft", text: Binding(
                        get: { mannschaft ?? "" },
                        set: { mannschaft = $0.isEmpty ? nil : $0 }
                    ))
                        .foregroundColor(.white) // Weiße Schrift
                } header: {
                    Text("Funktionär-Daten").foregroundColor(.white)
                }

                // Separate Section für den Bild-Upload
                Section(header: Text("Profilbild").foregroundColor(.white)) {
                    PhotosPicker(
                        selection: $selectedPhoto,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        Label("Bild aus Fotogalerie auswählen", systemImage: "photo")
                            .foregroundColor(.white) // Weiße Schrift und Symbol
                    }
                    
                    TextField("Oder Bild-URL eingeben", text: $imageURL)
                        .autocapitalization(.none)
                        .keyboardType(.URL)
                        .foregroundColor(.white) // Weiße Schrift
                        .background(Color.gray.opacity(0.2)) // Dunklerer Hintergrund
                        .cornerRadius(8)
                    
                    if isUploadingImage {
                        ProgressView("Bild wird hochgeladen...")
                            .tint(.white) // Weißer Ladeindikator
                    } else if let image = profileImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    } else if let urlString = funktionär.profilbildURL, !urlString.isEmpty, let url = URL(string: urlString) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 100)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            case .failure, .empty:
                                Image(systemName: "photo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 100)
                                    .foregroundColor(.gray)
                            @unknown default:
                                Image(systemName: "photo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 100)
                                    .foregroundColor(.gray)
                            }
                        }
                    } else {
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 100)
                            .foregroundColor(.gray)
                    }
                }
            }
            .scrollContentBackground(.hidden) // Standard-Hintergrund der Form ausblenden
            .background(Color.black) // Schwarzer Hintergrund für die Form
            .navigationTitle("Funktionär hinzufügen/bearbeiten")
            .foregroundColor(.white) // Weiße Schrift für den Titel
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { onCancel() }
                        .foregroundColor(.white) // Weiße Schrift
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        let updatedFunktionär = Funktionär(
                            id: funktionär.id,
                            name: name,
                            vorname: vorname,
                            abteilung: abteilung,
                            vereinID: vereinID,
                            kontaktTelefon: kontaktTelefon,
                            kontaktEmail: kontaktEmail,
                            adresse: adresse,
                            clients: funktionär.clients,
                            profilbildURL: funktionär.profilbildURL,
                            geburtsdatum: geburtsdatum,
                            positionImVerein: positionImVerein,
                            mannschaft: mannschaft,
                            nationalitaet: selectedNationalities.isEmpty ? nil : selectedNationalities
                        )
                        Task { await saveFunktionär(updatedFunktionär: updatedFunktionär) }
                    }
                    .disabled(name.isEmpty || vorname.isEmpty || (vereinID != nil && abteilung == nil))
                    .foregroundColor(.white) // Weiße Schrift
                }
            }
            .alert(isPresented: .constant(!errorMessage.isEmpty)) {
                Alert(
                    title: Text("Fehler").foregroundColor(.white),
                    message: Text(errorMessage).foregroundColor(.white),
                    dismissButton: .default(Text("OK").foregroundColor(.white)) { errorMessage = "" }
                )
            }
            .task {
                await loadClubOptions()
            }
            .onChange(of: selectedPhoto) { newValue in
                print("AddFunktionärView - SelectedPhoto geändert: \(newValue != nil ? "Foto ausgewählt" : "Kein Foto")")
                Task { await loadSelectedImage() }
            }
        }
    }

    private func loadClubOptions() async {
        do {
            let (clubs, _) = try await FirestoreManager.shared.getClubs(limit: 1000)
            await MainActor.run {
                self.clubOptions = clubs
            }
        } catch {
            print("Fehler beim Laden der Vereine: \(error.localizedDescription)")
            await MainActor.run {
                errorMessage = "Fehler beim Laden der Vereine: \(error.localizedDescription)"
            }
        }
    }

    private func loadSelectedImage() async {
        guard let photoItem = selectedPhoto else {
            print("AddFunktionärView - Kein Foto zum Laden ausgewählt")
            await MainActor.run {
                self.profileImage = nil
            }
            return
        }
        do {
            if let data = try await photoItem.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    self.profileImage = image
                    self.imageURL = "" // Bild-URL zurücksetzen, wenn ein lokales Bild ausgewählt wurde
                    self.funktionär.profilbildURL = nil
                    print("AddFunktionärView - Bild erfolgreich geladen: \(String(describing: image))")
                }
            } else {
                await MainActor.run {
                    self.profileImage = nil
                    errorMessage = "Fehler beim Laden des Bildes: Keine Bilddaten"
                }
            }
        } catch {
            await MainActor.run {
                self.profileImage = nil
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

    private func saveFunktionär(updatedFunktionär: Funktionär) async {
        do {
            var funktionärToSave = updatedFunktionär
            if let funktionärID = funktionärToSave.id {
                // Bearbeiten eines bestehenden Funktionärs
                await MainActor.run { isUploadingImage = true }
                if let image = profileImage {
                    // Bild aus Fotogalerie hochladen
                    let url = try await FirestoreManager.shared.uploadImage(
                        documentID: funktionärID,
                        image: image,
                        collection: "profile_images"
                    )
                    funktionärToSave.profilbildURL = url
                } else if !imageURL.isEmpty {
                    // Bild von URL herunterladen und hochladen
                    let downloadedImage = try await downloadImage(from: imageURL)
                    let url = try await FirestoreManager.shared.uploadImage(
                        documentID: funktionärID,
                        image: downloadedImage,
                        collection: "profile_images"
                    )
                    funktionärToSave.profilbildURL = url
                }
                try await FirestoreManager.shared.updateFunktionär(funktionär: funktionärToSave)
                await MainActor.run { isUploadingImage = false }
                onSave(funktionärToSave)
            } else {
                // Erstellen eines neuen Funktionärs
                let newFunktionärID = try await FirestoreManager.shared.createFunktionär(funktionär: funktionärToSave)
                var newFunktionär = funktionärToSave
                newFunktionär.id = newFunktionärID
                if let image = profileImage {
                    await MainActor.run { isUploadingImage = true }
                    let url = try await FirestoreManager.shared.uploadImage(
                        documentID: newFunktionärID,
                        image: image,
                        collection: "profile_images"
                    )
                    newFunktionär.profilbildURL = url
                    try await FirestoreManager.shared.updateFunktionär(funktionär: newFunktionär)
                    await MainActor.run { isUploadingImage = false }
                } else if !imageURL.isEmpty {
                    await MainActor.run { isUploadingImage = true }
                    let downloadedImage = try await downloadImage(from: imageURL)
                    let url = try await FirestoreManager.shared.uploadImage(
                        documentID: newFunktionärID,
                        image: downloadedImage,
                        collection: "profile_images"
                    )
                    newFunktionär.profilbildURL = url
                    try await FirestoreManager.shared.updateFunktionär(funktionär: newFunktionär)
                    await MainActor.run { isUploadingImage = false }
                }
                onSave(newFunktionär)
            }
        } catch {
            await MainActor.run {
                errorMessage = "Fehler beim Speichern: \(error.localizedDescription)"
                print("Fehler beim Speichern: \(error)")
                isUploadingImage = false
            }
        }
    }
}

#Preview {
    AddFunktionärView(
        funktionär: .constant(Funktionär(
            name: "Mustermann",
            vorname: "Max",
            abteilung: "Männer",
            positionImVerein: "Trainer"
        )),
        onSave: { _ in },
        onCancel: {}
    )
}
