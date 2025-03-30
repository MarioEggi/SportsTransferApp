import SwiftUI
import FirebaseFirestore
import PhotosUI
import UniformTypeIdentifiers

struct EditClubView: View {
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
    @State private var mensClients: String = ""
    @State private var womensClients: String = ""
    @State private var land: String?
    @State private var memberCount: String = ""
    @State private var founded: String = ""
    @State private var logoURL: String = ""
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var logoImage: UIImage? = nil
    @State private var clubDocumentData: Data? = nil
    @State private var clubDocumentURL: String? = nil
    @State private var isUploadingImage = false
    @State private var errorMessage: String = ""
    @State private var showingCountryPicker = false
    @State private var showingDocumentPicker = false

    init(club: Binding<Club>, onSave: @escaping (Club) -> Void, onCancel: @escaping () -> Void) {
        self._club = club
        self.onSave = onSave
        self.onCancel = onCancel
        let wrappedClub = club.wrappedValue
        self._name = State(initialValue: wrappedClub.name)
        self._mensLeague = State(initialValue: wrappedClub.mensDepartment?.league)
        self._womensLeague = State(initialValue: wrappedClub.womensDepartment?.league)
        self._mensAdresse = State(initialValue: wrappedClub.mensDepartment?.adresse ?? "")
        self._womensAdresse = State(initialValue: wrappedClub.womensDepartment?.adresse ?? "")
        self._mensKontaktTelefon = State(initialValue: wrappedClub.mensDepartment?.kontaktTelefon ?? "")
        self._womensKontaktTelefon = State(initialValue: wrappedClub.womensDepartment?.kontaktTelefon ?? "")
        self._mensKontaktEmail = State(initialValue: wrappedClub.mensDepartment?.kontaktEmail ?? "")
        self._womensKontaktEmail = State(initialValue: wrappedClub.womensDepartment?.kontaktEmail ?? "")
        self._mensClients = State(initialValue: wrappedClub.mensDepartment?.clients?.joined(separator: ", ") ?? "")
        self._womensClients = State(initialValue: wrappedClub.womensDepartment?.clients?.joined(separator: ", ") ?? "")
        self._land = State(initialValue: wrappedClub.sharedInfo?.land)
        self._memberCount = State(initialValue: wrappedClub.sharedInfo?.memberCount.map(String.init) ?? "")
        self._founded = State(initialValue: wrappedClub.sharedInfo?.founded ?? "")
        self._logoURL = State(initialValue: wrappedClub.sharedInfo?.logoURL ?? "")
        self._clubDocumentURL = State(initialValue: wrappedClub.sharedInfo?.clubDocumentURL ?? nil)
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Vereinsdaten").foregroundColor(.white)) {
                    TextField("Name", text: $name)
                        .foregroundColor(.white)
                    countryPicker
                    TextField("Mitgliederzahl", text: $memberCount)
                        .keyboardType(.numberPad)
                        .foregroundColor(.white)
                    TextField("Gegründet", text: $founded)
                        .foregroundColor(.white)

                    PhotosPicker(
                        selection: $selectedPhoto,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        Label("Logo auswählen", systemImage: "photo")
                            .foregroundColor(.white)
                    }
                    TextField("Oder Logo-URL eingeben", text: $logoURL)
                        .autocapitalization(.none)
                        .keyboardType(.URL)
                        .foregroundColor(.white)
                    if isUploadingImage {
                        ProgressView("Logo wird hochgeladen...")
                            .tint(.white)
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
                                image.resizable().scaledToFit().frame(height: 100).clipShape(RoundedRectangle(cornerRadius: 10))
                            case .failure:
                                Image(systemName: "photo").resizable().scaledToFit().frame(height: 100).foregroundColor(.gray)
                            case .empty:
                                ProgressView().tint(.white)
                            @unknown default:
                                Image(systemName: "photo").resizable().scaledToFit().frame(height: 100).foregroundColor(.gray)
                            }
                        }
                    }
                }
                Section(header: Text("Männerabteilung").foregroundColor(.white)) {
                    Picker("Liga", selection: $mensLeague) {
                        Text("Keine Liga").tag(String?.none)
                        ForEach(Constants.leaguesMale, id: \.self) { league in
                            Text(league).tag(String?.some(league))
                        }
                    }
                    .pickerStyle(.menu)
                    .foregroundColor(.white)
                    .accentColor(.white)
                    TextField("Adresse", text: $mensAdresse)
                        .foregroundColor(.white)
                    TextField("Telefon", text: $mensKontaktTelefon)
                        .foregroundColor(.white)
                    TextField("E-Mail", text: $mensKontaktEmail)
                        .foregroundColor(.white)
                    TextField("Klienten (durch Komma getrennt)", text: $mensClients)
                        .foregroundColor(.white)
                }
                Section(header: Text("Frauenabteilung").foregroundColor(.white)) {
                    Picker("Liga", selection: $womensLeague) {
                        Text("Keine Liga").tag(String?.none)
                        ForEach(Constants.leaguesFemale, id: \.self) { league in
                            Text(league).tag(String?.some(league))
                        }
                    }
                    .pickerStyle(.menu)
                    .foregroundColor(.white)
                    .accentColor(.white)
                    TextField("Adresse", text: $womensAdresse)
                        .foregroundColor(.white)
                    TextField("Telefon", text: $womensKontaktTelefon)
                        .foregroundColor(.white)
                    TextField("E-Mail", text: $womensKontaktEmail)
                        .foregroundColor(.white)
                    TextField("Klienten (durch Komma getrennt)", text: $womensClients)
                        .foregroundColor(.white)
                }
                Section(header: Text("Dokumente").foregroundColor(.white)) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Vereinsdokument")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        Button(action: { showingDocumentPicker = true }) {
                            Label("Dokument auswählen", systemImage: "doc")
                                .foregroundColor(.white)
                        }
                        if let clubDocumentURL = clubDocumentURL {
                            Text("Aktuell: \(clubDocumentURL.split(separator: "/").last ?? "")")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.black)
            .navigationTitle("Verein bearbeiten")
            .foregroundColor(.white)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { onCancel() }
                        .foregroundColor(.white)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        Task { await saveClub() }
                    }
                    .disabled(name.isEmpty || (mensLeague == nil && womensLeague == nil))
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
            .onChange(of: selectedPhoto) { _ in Task { await loadSelectedImage() } }
            .sheet(isPresented: $showingDocumentPicker) {
                DocumentPicker(
                    allowedContentTypes: [.pdf, .text],
                    onPick: { url in
                        Task { await loadClubDocument(from: url) }
                    }
                )
            }
        }
    }

    private var countryPicker: some View {
        Button(action: { showingCountryPicker = true }) {
            Text(land ?? "Land auswählen")
                .foregroundColor(land == nil ? .gray : .white)
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
                    options: Constants.nationalities,
                    isNationalityPicker: false
                )
                .navigationTitle("Land")
                .foregroundColor(.white)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Fertig") { showingCountryPicker = false }
                            .foregroundColor(.white)
                    }
                }
                .background(Color.black)
            }
        }
    }

    private func loadSelectedImage() async {
        guard let photoItem = selectedPhoto else { return }
        do {
            if let data = try await photoItem.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    self.logoImage = image
                    self.logoURL = ""
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = "Fehler beim Laden des Bildes: \(error.localizedDescription)"
            }
        }
    }

    private func loadClubDocument(from url: URL) async {
        do {
            let data = try Data(contentsOf: url)
            await MainActor.run {
                self.clubDocumentData = data
            }
        } catch {
            await MainActor.run {
                errorMessage = "Fehler beim Laden des Dokuments: \(error.localizedDescription)"
            }
        }
    }

    private func downloadImage(from urlString: String) async throws -> UIImage {
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { throw URLError(.badServerResponse) }
        guard let image = UIImage(data: data) else { throw URLError(.cannotDecodeContentData) }
        return image
    }

    private func saveClub() async {
        do {
            var finalLogoURL = logoURL
            if let image = logoImage {
                await MainActor.run { isUploadingImage = true }
                guard let documentID = club.id else {
                    throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Keine Club-ID verfügbar"])
                }
                finalLogoURL = try await FirestoreManager.shared.uploadImage(
                    documentID: documentID,
                    image: image,
                    collection: "club_logos"
                )
            } else if !logoURL.isEmpty {
                let downloadedImage = try await downloadImage(from: logoURL)
                guard let documentID = club.id else {
                    throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Keine Club-ID verfügbar"])
                }
                finalLogoURL = try await FirestoreManager.shared.uploadImage(
                    documentID: documentID,
                    image: downloadedImage,
                    collection: "club_logos"
                )
            }

            let mensDepartment = Club.Department(
                league: mensLeague,
                adresse: mensAdresse.isEmpty ? nil : mensAdresse,
                kontaktTelefon: mensKontaktTelefon.isEmpty ? nil : mensKontaktTelefon,
                kontaktEmail: mensKontaktEmail.isEmpty ? nil : mensKontaktEmail,
                funktionäre: club.mensDepartment?.funktionäre ?? [],
                clients: mensClients.isEmpty ? nil : mensClients.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            )
            let womensDepartment = Club.Department(
                league: womensLeague,
                adresse: womensAdresse.isEmpty ? nil : womensAdresse,
                kontaktTelefon: womensKontaktTelefon.isEmpty ? nil : womensKontaktTelefon,
                kontaktEmail: womensKontaktEmail.isEmpty ? nil : womensKontaktEmail,
                funktionäre: club.womensDepartment?.funktionäre ?? [],
                clients: womensClients.isEmpty ? nil : womensClients.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            )
            var sharedInfo = Club.SharedInfo(
                land: land,
                memberCount: Int(memberCount) ?? nil,
                founded: founded.isEmpty ? nil : founded,
                logoURL: finalLogoURL.isEmpty ? nil : finalLogoURL,
                clubDocumentURL: clubDocumentURL // Jetzt korrekt definiert
            )

            if let docData = clubDocumentData {
                guard let documentID = club.id else {
                    throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Keine Club-ID verfügbar"])
                }
                let url = try await FirestoreManager.shared.uploadFile(
                    documentID: documentID,
                    data: docData,
                    collection: "club_documents",
                    fileName: "doc_\(documentID)"
                )
                sharedInfo.clubDocumentURL = url
            }

            let updatedClub = Club(
                id: club.id,
                name: name,
                mensDepartment: mensLeague == nil && mensAdresse.isEmpty && mensKontaktTelefon.isEmpty && mensKontaktEmail.isEmpty && mensClients.isEmpty ? nil : mensDepartment,
                womensDepartment: womensLeague == nil && womensAdresse.isEmpty && womensKontaktTelefon.isEmpty && womensKontaktEmail.isEmpty && womensClients.isEmpty ? nil : womensDepartment,
                sharedInfo: sharedInfo
            )
            onSave(updatedClub)
            await MainActor.run { isUploadingImage = false }
        } catch {
            await MainActor.run {
                errorMessage = "Fehler beim Speichern: \(error.localizedDescription)"
                isUploadingImage = false
            }
        }
    }
}

#Preview {
    EditClubView(
        club: .constant(Club(
            name: "Bayern München",
            mensDepartment: nil,
            womensDepartment: nil,
            sharedInfo: nil
        )),
        onSave: { _ in },
        onCancel: {}
    )
}
