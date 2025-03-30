import SwiftUI
import FirebaseFirestore
import PhotosUI
import UniformTypeIdentifiers

struct EditFunktionärView: View {
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
    @State private var funktionärDocumentData: Data? = nil
    @State private var funktionärDocumentURL: String? = nil
    @State private var showingDocumentPicker = false
    @State private var errorMessage: String = ""

    init(funktionär: Binding<Funktionär>, onSave: @escaping (Funktionär) -> Void, onCancel: @escaping () -> Void) {
        self._funktionär = funktionär
        self.onSave = onSave
        self.onCancel = onCancel
        let wrappedValue = funktionär.wrappedValue
        self._name = State(initialValue: wrappedValue.name)
        self._vorname = State(initialValue: wrappedValue.vorname)
        self._vereinID = State(initialValue: wrappedValue.vereinID)
        self._abteilung = State(initialValue: wrappedValue.abteilung)
        self._positionImVerein = State(initialValue: wrappedValue.positionImVerein)
        self._kontaktTelefon = State(initialValue: wrappedValue.kontaktTelefon)
        self._kontaktEmail = State(initialValue: wrappedValue.kontaktEmail)
        self._adresse = State(initialValue: wrappedValue.adresse)
        self._geburtsdatum = State(initialValue: wrappedValue.geburtsdatum)
        self._mannschaft = State(initialValue: wrappedValue.mannschaft)
        self._selectedNationalities = State(initialValue: wrappedValue.nationalitaet ?? [])
        self._funktionärDocumentURL = State(initialValue: wrappedValue.functionaryDocumentURL)
    }

    var body: some View {
        NavigationView {
            mainFormContent
                .navigationTitle("Funktionär bearbeiten")
                .foregroundColor(.white)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Abbrechen") { onCancel() }
                            .foregroundColor(.white)
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
                                nationalitaet: selectedNationalities.isEmpty ? nil : selectedNationalities,
                                functionaryDocumentURL: funktionärDocumentURL
                            )
                            Task { await saveFunktionär(updatedFunktionär: updatedFunktionär) }
                        }
                        .disabled(name.isEmpty || vorname.isEmpty || (vereinID != nil && abteilung == nil))
                        .foregroundColor(.white)
                    }
                }
                .alert(isPresented: .constant(!errorMessage.isEmpty)) {
                    Alert(
                        title: Text("Fehler").foregroundColor(.white),
                        message: Text(errorMessage).foregroundColor(.white),
                        dismissButton: .default(Text("OK").foregroundColor(.white)) { errorMessage = "" }
                    )
                }
        }
    }

    // Hauptformular-Inhalt
    private var mainFormContent: some View {
        Form {
            funktionärDataSection
            profileImageSection
            documentsSection
        }
        .scrollContentBackground(.hidden)
        .background(Color.black)
        .onChange(of: selectedPhoto) { _ in Task { await loadSelectedImage() } }
        .sheet(isPresented: $showingDocumentPicker) { documentPickerSheet }
        .sheet(isPresented: $showingNationalityPicker) { nationalityPickerSheet }
        .task { await loadClubOptions() }
    }

    // Funktionär-Daten Sektion
    private var funktionärDataSection: some View {
        Section(header: Text("Funktionär-Daten").foregroundColor(.white)) {
            TextField("Name", text: $name)
                .foregroundColor(.white)
            TextField("Vorname", text: $vorname)
                .foregroundColor(.white)
            vereinPicker
            abteilungPicker
            positionPicker
            nationalityButton
            contactFields
            datePicker
            TextField("Mannschaft", text: Binding(
                get: { mannschaft ?? "" },
                set: { mannschaft = $0.isEmpty ? nil : $0 }
            ))
                .foregroundColor(.white)
        }
    }

    // Verein Picker
    private var vereinPicker: some View {
        Picker("Verein", selection: $vereinID) {
            Text("Kein Verein").tag(String?.none)
            ForEach(clubOptions) { club in
                Text(club.name).tag(club.id as String?)
            }
        }
        .pickerStyle(.menu)
        .foregroundColor(.white)
        .accentColor(.white)
        .onChange(of: vereinID) { _ in abteilung = nil }
    }

    // Abteilung Picker
    private var abteilungPicker: some View {
        Group {
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
                .foregroundColor(.white)
                .accentColor(.white)
            }
        }
    }

    // Position Picker
    private var positionPicker: some View {
        Picker("Position im Verein", selection: $positionImVerein) {
            Text("Keine Position").tag(String?.none)
            ForEach(Constants.functionaryPositionOptions, id: \.self) { position in
                Text(position).tag(String?.some(position))
            }
        }
        .pickerStyle(.menu)
        .foregroundColor(.white)
        .accentColor(.white)
    }

    // Nationalitäten Button
    private var nationalityButton: some View {
        Button(action: { showingNationalityPicker = true }) {
            Text(selectedNationalities.isEmpty ? "Nationalitäten auswählen" : selectedNationalities.joined(separator: ", "))
                .foregroundColor(selectedNationalities.isEmpty ? .gray : .white)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // Kontaktfelder
    private var contactFields: some View {
        Group {
            TextField("Telefon", text: Binding(
                get: { kontaktTelefon ?? "" },
                set: { kontaktTelefon = $0.isEmpty ? nil : $0 }
            ))
                .foregroundColor(.white)
            TextField("E-Mail", text: Binding(
                get: { kontaktEmail ?? "" },
                set: { kontaktEmail = $0.isEmpty ? nil : $0 }
            ))
                .foregroundColor(.white)
            TextField("Adresse", text: Binding(
                get: { adresse ?? "" },
                set: { adresse = $0.isEmpty ? nil : $0 }
            ))
                .foregroundColor(.white)
        }
    }

    // Geburtsdatum Picker
    private var datePicker: some View {
        DatePicker("Geburtsdatum", selection: Binding(
            get: { geburtsdatum ?? Date() },
            set: { geburtsdatum = $0 }
        ), displayedComponents: .date)
            .foregroundColor(.white)
            .accentColor(.white)
    }

    // Profilbild Sektion
    private var profileImageSection: some View {
        Section(header: Text("Profilbild").foregroundColor(.white)) {
            PhotosPicker(
                selection: $selectedPhoto,
                matching: .images,
                photoLibrary: .shared()
            ) {
                Label("Bild aus Fotogalerie auswählen", systemImage: "photo")
                    .foregroundColor(.white)
            }
            TextField("Oder Bild-URL eingeben", text: $imageURL)
                .autocapitalization(.none)
                .keyboardType(.URL)
                .foregroundColor(.white)
            imagePreview
        }
    }

    // Bildvorschau
    private var imagePreview: some View {
        Group {
            if isUploadingImage {
                ProgressView("Bild wird hochgeladen...")
                    .tint(.white)
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
                        image.resizable().scaledToFit().frame(height: 100).clipShape(RoundedRectangle(cornerRadius: 10))
                    case .failure, .empty:
                        Image(systemName: "photo").resizable().scaledToFit().frame(height: 100).foregroundColor(.gray)
                    @unknown default:
                        Image(systemName: "photo").resizable().scaledToFit().frame(height: 100).foregroundColor(.gray)
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

    // Dokumente Sektion
    private var documentsSection: some View {
        Section(header: Text("Dokumente").foregroundColor(.white)) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Funktionär-Dokument")
                    .font(.subheadline)
                    .foregroundColor(.white)
                Button(action: { showingDocumentPicker = true }) {
                    Label("Dokument auswählen", systemImage: "doc")
                        .foregroundColor(.white)
                }
                if let funktionärDocumentURL = funktionärDocumentURL {
                    Text("Aktuell: \(funktionärDocumentURL.split(separator: "/").last ?? "")")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
    }

    // Nationalitäten-Picker Sheet
    private var nationalityPickerSheet: some View {
        NavigationView {
            MultiPicker(
                title: "Nationalitäten auswählen",
                selection: $selectedNationalities,
                options: Constants.nationalities,
                isNationalityPicker: true
            )
            .navigationTitle("Nationalitäten")
            .foregroundColor(.white)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fertig") { showingNationalityPicker = false }
                        .foregroundColor(.white)
                }
            }
            .background(Color.black)
        }
    }

    // Dokumenten-Picker Sheet
    private var documentPickerSheet: some View {
        DocumentPicker(
            allowedContentTypes: [.pdf, .text],
            onPick: { url in Task { await loadFunktionärDocument(from: url) } }
        )
    }

    private func loadClubOptions() async {
        do {
            let (clubs, _) = try await FirestoreManager.shared.getClubs(limit: 1000)
            await MainActor.run { self.clubOptions = clubs }
        } catch {
            print("Fehler beim Laden der Vereine: \(error.localizedDescription)")
            await MainActor.run { errorMessage = "Fehler beim Laden der Vereine: \(error.localizedDescription)" }
        }
    }

    private func loadSelectedImage() async {
        guard let photoItem = selectedPhoto else {
            await MainActor.run { self.profileImage = nil }
            return
        }
        do {
            if let data = try await photoItem.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    self.profileImage = image
                    self.imageURL = ""
                    self.funktionär.profilbildURL = nil
                }
            }
        } catch {
            await MainActor.run { errorMessage = "Fehler beim Laden des Bildes: \(error.localizedDescription)" }
        }
    }

    private func loadFunktionärDocument(from url: URL) async {
        do {
            let data = try Data(contentsOf: url)
            await MainActor.run { self.funktionärDocumentData = data }
        } catch {
            await MainActor.run { errorMessage = "Fehler beim Laden des Dokuments: \(error.localizedDescription)" }
        }
    }

    private func downloadImage(from urlString: String) async throws -> UIImage {
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { throw URLError(.badServerResponse) }
        guard let image = UIImage(data: data) else { throw URLError(.cannotDecodeContentData) }
        return image
    }

    private func saveFunktionär(updatedFunktionär: Funktionär) async {
        do {
            var funktionärToSave = updatedFunktionär
            if let funktionärID = funktionärToSave.id {
                await MainActor.run { isUploadingImage = true }
                if let image = profileImage {
                    let url = try await FirestoreManager.shared.uploadImage(
                        documentID: funktionärID,
                        image: image,
                        collection: "profile_images"
                    )
                    funktionärToSave.profilbildURL = url
                } else if !imageURL.isEmpty {
                    let downloadedImage = try await downloadImage(from: imageURL)
                    let url = try await FirestoreManager.shared.uploadImage(
                        documentID: funktionärID,
                        image: downloadedImage,
                        collection: "profile_images"
                    )
                    funktionärToSave.profilbildURL = url
                }

                if let docData = funktionärDocumentData {
                    let url = try await FirestoreManager.shared.uploadFile(
                        documentID: funktionärID,
                        data: docData,
                        collection: "functionary_documents",
                        fileName: "doc_\(funktionärID)"
                    )
                    funktionärToSave.functionaryDocumentURL = url
                }

                try await FirestoreManager.shared.updateFunktionär(funktionär: funktionärToSave)
                await MainActor.run { isUploadingImage = false }
                onSave(funktionärToSave)
            }
        } catch {
            await MainActor.run {
                errorMessage = "Fehler beim Speichern: \(error.localizedDescription)"
                isUploadingImage = false
            }
        }
    }
}

#Preview {
    EditFunktionärView(
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
