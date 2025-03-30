import SwiftUI
import FirebaseFirestore
import PhotosUI

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
    @State private var isUploadingImage = false
    @State private var errorMessage: String = ""

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
        self._mensClients = State(initialValue: club.wrappedValue.mensDepartment?.clients?.joined(separator: ", ") ?? "")
        self._womensClients = State(initialValue: club.wrappedValue.womensDepartment?.clients?.joined(separator: ", ") ?? "")
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
                    Picker("Land", selection: $land) {
                        Text("Kein Land").tag(String?.none)
                        ForEach(Constants.nationalities, id: \.self) { country in
                            Text(country).tag(String?.some(country))
                        }
                    }
                    .pickerStyle(.menu)
                    TextField("Mitgliederzahl", text: $memberCount)
                        .keyboardType(.numberPad)
                    TextField("Gegründet", text: $founded)

                    // Bildauswahl und Vorschau
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Vereinslogo")
                            .font(.subheadline)
                        PhotosPicker(
                            selection: $selectedPhoto,
                            matching: .images,
                            photoLibrary: .shared()
                        ) {
                            Label("Bild auswählen", systemImage: "photo")
                                .foregroundColor(.blue)
                        }
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
                    TextField("Klienten (durch Komma getrennt)", text: $mensClients)
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
                    TextField("Klienten (durch Komma getrennt)", text: $womensClients)
                }
            }
            .navigationTitle("Verein bearbeiten")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { onCancel() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        Task {
                            await saveClub()
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
                await MainActor.run { isUploadingImage = false }
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
            let sharedInfo = Club.SharedInfo(
                land: land,
                memberCount: Int(memberCount) ?? nil,
                founded: founded.isEmpty ? nil : founded,
                logoURL: finalLogoURL.isEmpty ? nil : finalLogoURL
            )
            let updatedClub = Club(
                id: club.id,
                name: name,
                mensDepartment: mensLeague == nil && mensAdresse.isEmpty && mensKontaktTelefon.isEmpty && mensKontaktEmail.isEmpty && mensClients.isEmpty ? nil : mensDepartment,
                womensDepartment: womensLeague == nil && womensAdresse.isEmpty && womensKontaktTelefon.isEmpty && womensKontaktEmail.isEmpty && womensClients.isEmpty ? nil : womensDepartment,
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
