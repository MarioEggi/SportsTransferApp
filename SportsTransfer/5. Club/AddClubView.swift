import SwiftUI
import FirebaseFirestore
import PhotosUI
import UniformTypeIdentifiers

struct AddClubView: View {
    @Binding var club: Club
    var onSave: (Club) -> Void
    var onCancel: () -> Void
    @Environment(\.dismiss) var dismiss

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
    @State private var clubDocumentData: Data? = nil
    @State private var clubDocumentURL: String? = nil
    @State private var isUploadingImage = false
    @State private var errorMessage: String = ""
    @State private var showingCountryPicker = false
    @State private var showingDocumentPicker = false

    // Farben für das helle Design
    private let backgroundColor = Color(hex: "#F5F5F5")
    private let cardBackgroundColor = Color(hex: "#E0E0E0")
    private let accentColor = Color(hex: "#00C4B4")
    private let textColor = Color(hex: "#333333")
    private let secondaryTextColor = Color(hex: "#666666")

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
        self._clubDocumentURL = State(initialValue: club.wrappedValue.sharedInfo?.clubDocumentURL)
    }

    var body: some View {
        NavigationView {
            ZStack {
                backgroundColor.edgesIgnoringSafeArea(.all)
                List {
                    Section(header: Text("Vereinsdaten").foregroundColor(textColor)) {
                        VStack(spacing: 10) {
                            TextField("Name", text: $name)
                                .foregroundColor(textColor)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                            countryPicker
                            TextField("Mitgliederzahl", text: $memberCount)
                                .keyboardType(.numberPad)
                                .foregroundColor(textColor)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                            TextField("Gegründet", text: $founded)
                                .foregroundColor(textColor)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                            profileImagePicker
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

                    Section(header: Text("Männerabteilung").foregroundColor(textColor)) {
                        VStack(spacing: 10) {
                            Picker("Liga", selection: $mensLeague) {
                                Text("Keine Liga").tag(String?.none)
                                ForEach(Constants.leaguesMale, id: \.self) { league in
                                    Text(league).tag(String?.some(league))
                                }
                            }
                            .pickerStyle(.menu)
                            .foregroundColor(textColor)
                            .tint(accentColor)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            TextField("Adresse", text: $mensAdresse)
                                .foregroundColor(textColor)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                            TextField("Telefon", text: $mensKontaktTelefon)
                                .foregroundColor(textColor)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                            TextField("E-Mail", text: $mensKontaktEmail)
                                .foregroundColor(textColor)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
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

                    Section(header: Text("Frauenabteilung").foregroundColor(textColor)) {
                        VStack(spacing: 10) {
                            Picker("Liga", selection: $womensLeague) {
                                Text("Keine Liga").tag(String?.none)
                                ForEach(Constants.leaguesFemale, id: \.self) { league in
                                    Text(league).tag(String?.some(league))
                                }
                            }
                            .pickerStyle(.menu)
                            .foregroundColor(textColor)
                            .tint(accentColor)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            TextField("Adresse", text: $womensAdresse)
                                .foregroundColor(textColor)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                            TextField("Telefon", text: $womensKontaktTelefon)
                                .foregroundColor(textColor)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                            TextField("E-Mail", text: $womensKontaktEmail)
                                .foregroundColor(textColor)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
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

                    Section(header: Text("Dokumente").foregroundColor(textColor)) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Vereinsdokument")
                                .font(.subheadline)
                                .foregroundColor(textColor)
                            Button(action: { showingDocumentPicker = true }) {
                                Label("Dokument auswählen", systemImage: "doc")
                                    .foregroundColor(accentColor)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                            }
                            if let clubDocumentURL = clubDocumentURL {
                                Text("Hochgeladen: \(clubDocumentURL.split(separator: "/").last ?? "")")
                                    .font(.caption)
                                    .foregroundColor(secondaryTextColor)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
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
                .tint(accentColor)
                .foregroundColor(textColor)
                .navigationTitle(club.id == nil ? "Verein anlegen" : "Verein bearbeiten")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Abbrechen") { onCancel() }
                            .foregroundColor(accentColor)
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Speichern") {
                            if validateInputs() {
                                Task { await saveClub() }
                            }
                        }
                        .disabled(name.isEmpty || (mensLeague == nil && womensLeague == nil))
                        .foregroundColor(accentColor)
                    }
                }
                .alert(isPresented: .constant(!errorMessage.isEmpty)) {
                    Alert(
                        title: Text("Fehler").foregroundColor(textColor),
                        message: Text(errorMessage).foregroundColor(secondaryTextColor),
                        dismissButton: .default(Text("OK").foregroundColor(accentColor)) { errorMessage = "" }
                    )
                }
                .onChange(of: selectedPhoto) { _ in Task { await loadSelectedImage() } }
                .sheet(isPresented: $showingDocumentPicker) {
                    DocumentPicker(
                        allowedContentTypes: [.pdf, .text],
                        onPick: { url in Task { await loadClubDocument(from: url) } }
                    )
                }
            }
        }
    }

    private var profileImagePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Logo")
                .font(.subheadline)
                .foregroundColor(textColor)
            PhotosPicker(
                selection: $selectedPhoto,
                matching: .images,
                photoLibrary: .shared()
            ) {
                Label("Bild auswählen", systemImage: "photo")
                    .foregroundColor(accentColor)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
            }
            TextField("Oder Logo-URL eingeben", text: $logoURL)
                .autocapitalization(.none)
                .keyboardType(.URL)
                .foregroundColor(textColor)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
            if isUploadingImage {
                ProgressView("Bild wird hochgeladen...")
                    .tint(accentColor)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
            } else if let image = logoImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(accentColor.opacity(0.3), lineWidth: 1)
                    )
            }
        }
        .padding(.vertical, 8)
    }

    private var countryPicker: some View {
        Button(action: { showingCountryPicker = true }) {
            Text(land ?? "Land auswählen")
                .foregroundColor(land == nil ? secondaryTextColor : textColor)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
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
                .foregroundColor(textColor)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Fertig") { showingCountryPicker = false }
                            .foregroundColor(accentColor)
                    }
                }
                .background(backgroundColor)
            }
        }
        .padding(.vertical, 8)
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
                let documentID = club.id ?? UUID().uuidString
                finalLogoURL = try await FirestoreManager.shared.uploadImage(
                    documentID: documentID,
                    image: image,
                    collection: "club_logos"
                )
            } else if !logoURL.isEmpty {
                let downloadedImage = try await downloadImage(from: logoURL)
                let documentID = club.id ?? UUID().uuidString
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
            var sharedInfo = Club.SharedInfo(
                land: land,
                memberCount: Int(memberCount) ?? nil,
                founded: founded.isEmpty ? nil : founded,
                logoURL: finalLogoURL.isEmpty ? nil : finalLogoURL,
                clubDocumentURL: clubDocumentURL
            )

            let documentID = club.id ?? UUID().uuidString
            if let docData = clubDocumentData {
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
                mensDepartment: mensLeague == nil && mensAdresse.isEmpty && mensKontaktTelefon.isEmpty && mensKontaktEmail.isEmpty ? nil : mensDepartment,
                womensDepartment: womensLeague == nil && womensAdresse.isEmpty && womensKontaktTelefon.isEmpty && womensKontaktEmail.isEmpty ? nil : womensDepartment,
                sharedInfo: sharedInfo
            )
            onSave(updatedClub)
            await MainActor.run {
                isUploadingImage = false
                dismiss()
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
    AddClubView(
        club: .constant(Club(name: "Bayern München", mensDepartment: nil, womensDepartment: nil, sharedInfo: nil)),
        onSave: { _ in },
        onCancel: {}
    )
}
