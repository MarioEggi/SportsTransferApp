import SwiftUI
import FirebaseFirestore
import PhotosUI
import UniformTypeIdentifiers

struct EditFunktionärView: View {
    @Binding var funktionär: Funktionär
    let onSave: (Funktionär) -> Void
    let onCancel: () -> Void
    @Environment(\.dismiss) var dismiss

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

    // Farben für das helle Design
    private let backgroundColor = Color(hex: "#F5F5F5")
    private let cardBackgroundColor = Color(hex: "#E0E0E0")
    private let accentColor = Color(hex: "#00C4B4")
    private let textColor = Color(hex: "#333333")
    private let secondaryTextColor = Color(hex: "#666666")

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
            ZStack {
                backgroundColor.edgesIgnoringSafeArea(.all)
                List {
                    Section(header: Text("Funktionär-Daten").foregroundColor(textColor)) {
                        VStack(spacing: 10) {
                            TextField("Name", text: $name)
                                .foregroundColor(textColor)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                            TextField("Vorname", text: $vorname)
                                .foregroundColor(textColor)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                            Picker("Verein", selection: $vereinID) {
                                Text("Kein Verein").tag(String?.none)
                                ForEach(clubOptions) { club in
                                    Text(club.name).tag(club.id as String?)
                                }
                            }
                            .pickerStyle(.menu)
                            .foregroundColor(textColor)
                            .tint(accentColor)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .onChange(of: vereinID) { _ in abteilung = nil }
                            abteilungPicker
                            Picker("Position im Verein", selection: $positionImVerein) {
                                Text("Keine Position").tag(String?.none)
                                ForEach(Constants.functionaryPositionOptions, id: \.self) { position in
                                    Text(position).tag(String?.some(position))
                                }
                            }
                            .pickerStyle(.menu)
                            .foregroundColor(textColor)
                            .tint(accentColor)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            nationalityButton
                            TextField("Telefon", text: Binding(
                                get: { kontaktTelefon ?? "" },
                                set: { kontaktTelefon = $0.isEmpty ? nil : $0 }
                            ))
                                .foregroundColor(textColor)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                            TextField("E-Mail", text: Binding(
                                get: { kontaktEmail ?? "" },
                                set: { kontaktEmail = $0.isEmpty ? nil : $0 }
                            ))
                                .foregroundColor(textColor)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                            TextField("Adresse", text: Binding(
                                get: { adresse ?? "" },
                                set: { adresse = $0.isEmpty ? nil : $0 }
                            ))
                                .foregroundColor(textColor)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                            DatePicker("Geburtsdatum", selection: Binding(
                                get: { geburtsdatum ?? Date() },
                                set: { geburtsdatum = $0 }
                            ), displayedComponents: .date)
                                .foregroundColor(textColor)
                                .tint(accentColor)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                            TextField("Mannschaft", text: Binding(
                                get: { mannschaft ?? "" },
                                set: { mannschaft = $0.isEmpty ? nil : $0 }
                            ))
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

                    Section(header: Text("Profilbild").foregroundColor(textColor)) {
                        profileImageSection
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
                            Text("Funktionär-Dokument")
                                .font(.subheadline)
                                .foregroundColor(textColor)
                            Button(action: { showingDocumentPicker = true }) {
                                Label("Dokument auswählen", systemImage: "doc")
                                    .foregroundColor(accentColor)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                            }
                            if let funktionärDocumentURL = funktionärDocumentURL {
                                Text("Aktuell: \(funktionärDocumentURL.split(separator: "/").last ?? "")")
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
                .navigationTitle("Funktionär bearbeiten")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Abbrechen") { onCancel() }
                            .foregroundColor(accentColor)
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
                .sheet(isPresented: $showingDocumentPicker) { documentPickerSheet }
                .sheet(isPresented: $showingNationalityPicker) { nationalityPickerSheet }
                .task { await loadClubOptions() }
            }
        }
    }

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
                .foregroundColor(textColor)
                .tint(accentColor)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
            }
        }
    }

    private var nationalityButton: some View {
        Button(action: { showingNationalityPicker = true }) {
            Text(selectedNationalities.isEmpty ? "Nationalitäten auswählen" : selectedNationalities.joined(separator: ", "))
                .foregroundColor(selectedNationalities.isEmpty ? secondaryTextColor : textColor)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
        }
    }

    private var profileImageSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Profilbild")
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
            TextField("Oder Bild-URL eingeben", text: $imageURL)
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
            } else if let image = profileImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(accentColor.opacity(0.3), lineWidth: 1)
                    )
            } else if let urlString = funktionär.profilbildURL, !urlString.isEmpty, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(accentColor.opacity(0.3), lineWidth: 1)
                            )
                    case .failure, .empty:
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 100)
                            .foregroundColor(secondaryTextColor)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(accentColor.opacity(0.3), lineWidth: 1)
                            )
                    @unknown default:
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 100)
                            .foregroundColor(secondaryTextColor)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(accentColor.opacity(0.3), lineWidth: 1)
                            )
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }

    private var nationalityPickerSheet: some View {
        NavigationView {
            MultiPicker(
                title: "Nationalitäten auswählen",
                selection: $selectedNationalities,
                options: Constants.nationalities,
                isNationalityPicker: true
            )
            .navigationTitle("Nationalitäten")
            .foregroundColor(textColor)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fertig") { showingNationalityPicker = false }
                        .foregroundColor(accentColor)
                }
            }
            .background(backgroundColor)
        }
    }

    private var documentPickerSheet: some View {
        DocumentPicker(
            allowedContentTypes: [.pdf, .text],
            onPick: { url in Task { await loadFunktionärDocument(from: url) } }
        )
    }

    private func loadClubOptions() async {
        do {
            let (clubs, _) = try await FirestoreManager.shared.getClubs(lastDocument: nil, limit: 1000)
            await MainActor.run { self.clubOptions = clubs }
        } catch {
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
                await MainActor.run {
                    isUploadingImage = false
                    onSave(funktionärToSave)
                    dismiss()
                }
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
        funktionär: .constant(Funktionär(name: "Mustermann", vorname: "Max", abteilung: "Männer", positionImVerein: "Trainer")),
        onSave: { _ in },
        onCancel: {}
    )
}
