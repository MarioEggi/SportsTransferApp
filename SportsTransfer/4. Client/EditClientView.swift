import SwiftUI
import FirebaseFirestore
import PhotosUI
import UniformTypeIdentifiers

struct EditClientView: View {
    @Binding var client: Client
    var onSave: (Client) -> Void
    var onCancel: () -> Void
    @EnvironmentObject var authManager: AuthManager

    @State private var showingPositionPicker = false
    @State private var showingNationalityPicker = false
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var profileImage: UIImage? = nil
    @State private var isUploadingImage = false
    @State private var isLoadingTransfermarkt = false
    @State private var transfermarktError = ""
    @State private var clubOptions: [Club] = []
    @State private var sponsorOptions: [Sponsor] = []
    @State private var errorMessage: String = ""
    @StateObject private var contractViewModel = ContractViewModel()
    @State private var isLoadingClubs = true

    @State private var name: String
    @State private var vorname: String
    @State private var vereinID: String?
    @State private var abteilung: String?
    @State private var geburtsdatum: Date?
    @State private var vertragBis: Date?
    @State private var vertragsOptionen: String?
    @State private var gehalt: Double?
    @State private var groesse: Int?
    @State private var selectedNationalities: [String]
    @State private var nationalmannschaft: String?
    @State private var selectedPositions: [String]
    @State private var schuhmarke: String?
    @State private var starkerFuss: String?
    @State private var kontaktTelefon: String?
    @State private var kontaktEmail: String?
    @State private var adresse: String?
    @State private var transfermarktID: String?
    @State private var liga: String?
    @State private var imageURL: String = ""
    @State private var konditionen: String?
    @State private var art: String?
    @State private var spielerCVData: Data? = nil
    @State private var spielerCVURL: String?
    @State private var videoData: Data? = nil
    @State private var videoURL: String?
    @State private var showingCVPicker = false
    @State private var showingVideoPicker = false

    init(client: Binding<Client>, onSave: @escaping (Client) -> Void, onCancel: @escaping () -> Void) {
        self._client = client
        self.onSave = onSave
        self.onCancel = onCancel
        
        let wrappedClient = client.wrappedValue
        _name = State(initialValue: wrappedClient.name)
        _vorname = State(initialValue: wrappedClient.vorname)
        _vereinID = State(initialValue: wrappedClient.vereinID)
        _abteilung = State(initialValue: wrappedClient.abteilung)
        _geburtsdatum = State(initialValue: wrappedClient.geburtsdatum)
        _vertragBis = State(initialValue: wrappedClient.vertragBis)
        _vertragsOptionen = State(initialValue: wrappedClient.vertragsOptionen)
        _gehalt = State(initialValue: wrappedClient.gehalt)
        _groesse = State(initialValue: wrappedClient.groesse)
        _selectedNationalities = State(initialValue: wrappedClient.nationalitaet ?? [])
        _nationalmannschaft = State(initialValue: wrappedClient.nationalmannschaft)
        _selectedPositions = State(initialValue: wrappedClient.positionFeld ?? [])
        _schuhmarke = State(initialValue: wrappedClient.schuhmarke)
        _starkerFuss = State(initialValue: wrappedClient.starkerFuss)
        _kontaktTelefon = State(initialValue: wrappedClient.kontaktTelefon)
        _kontaktEmail = State(initialValue: wrappedClient.kontaktEmail)
        _adresse = State(initialValue: wrappedClient.adresse)
        _transfermarktID = State(initialValue: wrappedClient.transfermarktID)
        _liga = State(initialValue: wrappedClient.liga)
        _konditionen = State(initialValue: wrappedClient.konditionen)
        _art = State(initialValue: wrappedClient.art)
        _spielerCVURL = State(initialValue: wrappedClient.spielerCV)
        _videoURL = State(initialValue: wrappedClient.video)
    }

    var body: some View {
        NavigationView {
            Form {
                clientDataSection
                if client.typ == "Spieler" || client.typ == "Spielerin" {
                    positionSection
                }
                contactInfoSection
                transfermarktSection
                additionalInfoSection
            }
            .scrollContentBackground(.hidden)
            .background(Color.black)
            .navigationTitle("Profil bearbeiten")
            .foregroundColor(.white)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { onCancel() }
                        .foregroundColor(.white)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        let updatedClient = createUpdatedClient()
                        print("EditClientView - Client vor dem Speichern: \(updatedClient)")
                        print("EditClientView - ProfileImage vor dem Speichern: \(profileImage != nil ? "Bild vorhanden" : "Kein Bild")")
                        print("EditClientView - ImageURL vor dem Speichern: \(imageURL)")
                        Task { await saveClient(updatedClient: updatedClient) }
                    }
                    .disabled(!isValidClient())
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
            .onChange(of: selectedPhoto) { newValue in
                print("EditClientView - SelectedPhoto geändert: \(newValue != nil ? "Foto ausgewählt" : "Kein Foto")")
                Task { await loadSelectedImage() }
            }
            .onChange(of: vereinID) { _ in
                Task { await updateLeagueAndAbteilung() }
            }
            .sheet(isPresented: $showingCVPicker) {
                DocumentPicker(
                    allowedContentTypes: [.pdf, .text],
                    onPick: { url in
                        Task { await loadSpielerCV(from: url) }
                    }
                )
            }
            .sheet(isPresented: $showingVideoPicker) {
                DocumentPicker(
                    allowedContentTypes: [.movie],
                    onPick: { url in
                        Task { await loadVideo(from: url) }
                    }
                )
            }
            .task {
                await loadClubOptions()
                await loadSponsors()
                await loadContractData()
            }
        }
    }

    private func createUpdatedClient() -> Client {
        Client(
            id: client.id,
            typ: client.typ,
            name: name,
            vorname: vorname,
            geschlecht: client.geschlecht,
            abteilung: abteilung,
            vereinID: vereinID,
            nationalitaet: selectedNationalities.isEmpty ? nil : selectedNationalities,
            geburtsdatum: geburtsdatum,
            kontaktTelefon: kontaktTelefon,
            kontaktEmail: kontaktEmail,
            adresse: adresse,
            liga: liga,
            vertragBis: vertragBis,
            vertragsOptionen: vertragsOptionen,
            gehalt: gehalt,
            schuhgroesse: client.schuhgroesse,
            schuhmarke: schuhmarke,
            starkerFuss: starkerFuss,
            groesse: groesse,
            gewicht: client.gewicht,
            positionFeld: selectedPositions.isEmpty ? nil : selectedPositions,
            sprachen: client.sprachen,
            lizenz: client.lizenz,
            nationalmannschaft: nationalmannschaft,
            profilbildURL: client.profilbildURL,
            transfermarktID: transfermarktID,
            userID: client.userID,
            createdBy: client.createdBy,
            konditionen: konditionen,
            art: art,
            spielerCV: spielerCVURL,
            video: videoURL
        )
    }

    private var clientDataSection: some View {
        Section(header: Text("Klientendaten").foregroundColor(.white)) {
            TextField("Vorname", text: $vorname)
                .foregroundColor(.white)
            TextField("Name", text: $name)
                .foregroundColor(.white)
            DatePicker("Geburtsdatum", selection: Binding(
                get: { geburtsdatum ?? Date() },
                set: { geburtsdatum = $0 }
            ), displayedComponents: .date)
                .datePickerStyle(.compact)
                .foregroundColor(.white)
                .accentColor(.white)
            if isLoadingClubs {
                ProgressView("Lade Vereine...")
                    .tint(.white)
            } else {
                Picker("Verein", selection: $vereinID) {
                    Text("Kein Verein").tag(String?.none)
                    ForEach(clubOptions.filter { $0.abteilungForGender(client.geschlecht) != nil }) { club in
                        Text(club.name).tag(club.id as String?)
                    }
                }
                .pickerStyle(.menu)
                .foregroundColor(.white)
                .accentColor(.white)
            }
            Text("Liga: \(liga ?? "Keine")")
                .foregroundColor(.gray)
            DatePicker("Vertragslaufzeit", selection: Binding(
                get: { vertragBis ?? Date() },
                set: { vertragBis = $0 }
            ), displayedComponents: .date)
                .foregroundColor(.white)
                .accentColor(.white)
            TextField("Vertragsoptionen", text: Binding(
                get: { vertragsOptionen ?? "" },
                set: { vertragsOptionen = $0.isEmpty ? nil : $0 }
            ))
                .foregroundColor(.white)
            TextField("Gehalt (€)", text: Binding(
                get: { gehalt != nil ? String(gehalt!) : "" },
                set: { gehalt = Double($0) }
            ))
                .keyboardType(.decimalPad)
                .foregroundColor(.white)
            TextField("Größe (cm)", text: Binding(
                get: { groesse != nil ? String(groesse!) : "" },
                set: { groesse = Int($0) }
            ))
                .keyboardType(.numberPad)
                .foregroundColor(.white)
            profileImagePicker
            nationalityPicker
            TextField("Nationalmannschaft", text: Binding(
                get: { nationalmannschaft ?? "" },
                set: { nationalmannschaft = $0.isEmpty ? nil : $0 }
            ))
                .foregroundColor(.white)
        }
    }

    private var positionSection: some View {
        Section(header: Text("Positionen").foregroundColor(.white)) {
            Button(action: {
                print("EditClientView - PositionPicker geöffnet")
                showingPositionPicker = true
            }) {
                Text(selectedPositions.isEmpty ? "Positionen auswählen" : selectedPositions.joined(separator: ", "))
                    .foregroundColor(selectedPositions.isEmpty ? .gray : .white)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .sheet(isPresented: $showingPositionPicker) {
                NavigationView {
                    MultiPicker(
                        title: "Positionen auswählen",
                        selection: $selectedPositions,
                        options: Constants.positionOptions,
                        isNationalityPicker: false
                    )
                    .navigationTitle("Positionen")
                    .foregroundColor(.white)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Fertig") {
                                showingPositionPicker = false
                            }
                            .foregroundColor(.white)
                        }
                    }
                    .background(Color.black)
                }
            }
            Picker("Schuhmarke", selection: Binding(
                get: { schuhmarke ?? "" },
                set: { schuhmarke = $0.isEmpty ? nil : $0 }
            )) {
                Text("Keine Marke").tag("")
                ForEach(sponsorOptions.filter { $0.category == "Sportartikelhersteller" }) { sponsor in
                    Text(sponsor.name).tag(sponsor.name)
                }
            }
            .pickerStyle(.menu)
            .foregroundColor(.white)
            .accentColor(.white)
            Picker("Starker Fuß", selection: Binding(
                get: { starkerFuss ?? "" },
                set: { starkerFuss = $0.isEmpty ? nil : $0 }
            )) {
                Text("Nicht angegeben").tag("")
                ForEach(Constants.strongFootOptions, id: \.self) { foot in
                    Text(foot).tag(foot)
                }
            }
            .pickerStyle(.menu)
            .foregroundColor(.white)
            .accentColor(.white)
        }
    }

    private var contactInfoSection: some View {
        Section(header: Text("Kontaktinformationen").foregroundColor(.white)) {
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

    private var transfermarktSection: some View {
        Section(header: Text(client.geschlecht == "männlich" ? "Transfermarkt" : "Soccerdonna").foregroundColor(.white)) {
            TextField(client.geschlecht == "männlich" ? "Transfermarkt-ID" : "Soccerdonna-ID", text: Binding(
                get: { transfermarktID ?? "" },
                set: { transfermarktID = $0.isEmpty ? nil : $0 }
            ))
                .keyboardType(.numberPad)
                .foregroundColor(.white)
                .customPlaceholder(when: (transfermarktID ?? "").isEmpty) {
                    Text(client.geschlecht == "männlich" ? "z. B. 690425" : "z. B. 31388")
                        .foregroundColor(.gray)
                }
                .onChange(of: transfermarktID) { newID in
                    if let newID = newID, !newID.isEmpty {
                        Task {
                            await MainActor.run { isLoadingTransfermarkt = true }
                            do {
                                let playerData: PlayerData
                                if client.geschlecht == "männlich" {
                                    playerData = try await TransfermarktService.shared.fetchPlayerData(forPlayerID: newID)
                                } else {
                                    playerData = try await SoccerdonnaService.shared.fetchPlayerData(forPlayerID: newID)
                                }
                                await MainActor.run {
                                    isLoadingTransfermarkt = false
                                    transfermarktError = ""
                                    if vorname.isEmpty, let fullName = playerData.name {
                                        let parts = fullName.split(separator: " ")
                                        if parts.count >= 2 {
                                            vorname = String(parts[0])
                                            name = String(parts.dropFirst().joined(separator: " "))
                                        } else {
                                            name = fullName
                                        }
                                    }
                                    if selectedPositions.isEmpty, let position = playerData.position {
                                        selectedPositions = [position]
                                    }
                                    if selectedNationalities.isEmpty, let nationalities = playerData.nationalitaet {
                                        selectedNationalities = nationalities
                                    }
                                    if geburtsdatum == nil, let birthdate = playerData.geburtsdatum {
                                        geburtsdatum = birthdate
                                    }
                                    if vereinID == nil, let clubID = playerData.vereinID,
                                       let club = clubOptions.first(where: { $0.name == clubID }) {
                                        vereinID = club.id
                                        Task { await updateLeagueAndAbteilung() }
                                    }
                                    if vertragBis == nil, let contractEnd = playerData.contractEnd {
                                        vertragBis = contractEnd
                                    }
                                }
                            } catch {
                                await MainActor.run {
                                    isLoadingTransfermarkt = false
                                    transfermarktError = "Fehler beim Abrufen der Daten: \(error.localizedDescription)"
                                }
                            }
                        }
                    }
                }
            if isLoadingTransfermarkt {
                ProgressView("Lade Daten...")
                    .tint(.white)
            }
            if !transfermarktError.isEmpty {
                Text(transfermarktError)
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
    }

    private var additionalInfoSection: some View {
        Section(header: Text("Zusätzliche Informationen").foregroundColor(.white)) {
            TextField("Konditionen", text: Binding(
                get: { konditionen ?? "" },
                set: { konditionen = $0.isEmpty ? nil : $0 }
            ))
                .foregroundColor(.white)
            Picker("Art", selection: Binding(
                get: { art ?? "" },
                set: { art = $0.isEmpty ? nil : $0 }
            )) {
                Text("Nicht angegeben").tag("")
                Text("Vereinswechsel").tag("Vereinswechsel")
                Text("Vertragsverlängerung").tag("Vertragsverlängerung")
            }
            .pickerStyle(.menu)
            .foregroundColor(.white)
            .accentColor(.white)
            VStack(alignment: .leading, spacing: 10) {
                Text("Spieler-CV")
                    .font(.subheadline)
                    .foregroundColor(.white)
                Button(action: { showingCVPicker = true }) {
                    Label("CV auswählen", systemImage: "doc")
                        .foregroundColor(.white)
                }
                if let spielerCVURL = spielerCVURL {
                    Text("Aktuell: \(spielerCVURL.split(separator: "/").last ?? "")")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            VStack(alignment: .leading, spacing: 10) {
                Text("Video")
                    .font(.subheadline)
                    .foregroundColor(.white)
                Button(action: { showingVideoPicker = true }) {
                    Label("Video auswählen", systemImage: "video")
                        .foregroundColor(.white)
                }
                if let videoURL = videoURL {
                    Text("Aktuell: \(videoURL.split(separator: "/").last ?? "")")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
    }

    private var profileImagePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Profilbild")
                .font(.subheadline)
                .foregroundColor(.white)
            
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
            
            if isUploadingImage {
                ProgressView("Bild wird hochgeladen...")
                    .tint(.white)
            } else if let image = profileImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else if let urlString = client.profilbildURL, !urlString.isEmpty, let url = URL(string: urlString) {
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

    private var nationalityPicker: some View {
        Button(action: {
            print("EditClientView - NationalityPicker geöffnet")
            showingNationalityPicker = true
        }) {
            Text(selectedNationalities.isEmpty ? "Nationalitäten auswählen" : selectedNationalities.joined(separator: ", "))
                .foregroundColor(selectedNationalities.isEmpty ? .gray : .white)
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
                .foregroundColor(.white)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Fertig") {
                            showingNationalityPicker = false
                        }
                        .foregroundColor(.white)
                    }
                }
                .background(Color.black)
            }
        }
    }

    private func loadClubOptions() async {
        do {
            let (clubs, _) = try await FirestoreManager.shared.getClubs(lastDocument: nil as DocumentSnapshot?, limit: 1000)
            await MainActor.run {
                self.clubOptions = clubs
                self.isLoadingClubs = false
                updateLeagueAndAbteilungSync()
            }
        } catch {
            await MainActor.run {
                self.isLoadingClubs = false
                errorMessage = "Fehler beim Laden der Vereine: \(error.localizedDescription)"
            }
        }
    }

    private func loadSponsors() async {
        do {
            let (sponsors, _) = try await FirestoreManager.shared.getSponsors(lastDocument: nil as DocumentSnapshot?, limit: 1000)
            await MainActor.run {
                self.sponsorOptions = sponsors
            }
        } catch {
            await MainActor.run {
                self.sponsorOptions = []
                self.errorMessage = "Fehler beim Laden der Sponsoren: \(error.localizedDescription)"
            }
        }
    }

    private func loadContractData() async {
        guard let clientID = client.id else { return }
        do {
            let (contracts, _) = try await FirestoreManager.shared.getContracts(lastDocument: nil as DocumentSnapshot?, limit: 1000)
            await MainActor.run {
                contractViewModel.contracts = contracts.filter { $0.clientID == clientID }
                if let contract = contractViewModel.contracts.first {
                    if vertragBis == nil {
                        vertragBis = contract.endDatum
                    }
                    if vertragsOptionen == nil {
                        vertragsOptionen = contract.vertragsdetails
                    }
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = "Fehler beim Laden der Vertragsdaten: \(error.localizedDescription)"
            }
        }
    }

    private func updateLeagueAndAbteilung() async {
        await MainActor.run {
            updateLeagueAndAbteilungSync()
        }
    }

    private func updateLeagueAndAbteilungSync() {
        if let vereinID = vereinID,
           let selectedClub = clubOptions.first(where: { $0.id == vereinID }) {
            abteilung = selectedClub.abteilungForGender(client.geschlecht)
            if client.geschlecht == "männlich" {
                liga = selectedClub.mensDepartment?.league
                print("Liga für Männer gesetzt: \(liga ?? "Keine")")
            } else if client.geschlecht == "weiblich" {
                liga = selectedClub.womensDepartment?.league
                print("Liga für Frauen gesetzt: \(liga ?? "Keine")")
            }
        } else {
            abteilung = nil
            liga = nil
            print("Kein Verein ausgewählt, Liga zurückgesetzt")
        }
    }

    private func loadSelectedImage() async {
        guard let photoItem = selectedPhoto else {
            print("EditClientView - Kein Foto zum Laden ausgewählt")
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
                    self.imageURL = ""
                    self.client.profilbildURL = nil
                    print("EditClientView - Bild erfolgreich geladen: \(image)")
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

    private func loadSpielerCV(from url: URL) async {
        do {
            let data = try Data(contentsOf: url)
            await MainActor.run {
                self.spielerCVData = data
            }
        } catch {
            await MainActor.run {
                errorMessage = "Fehler beim Laden des CVs: \(error.localizedDescription)"
            }
        }
    }

    private func loadVideo(from url: URL) async {
        do {
            let data = try Data(contentsOf: url)
            await MainActor.run {
                self.videoData = data
            }
        } catch {
            await MainActor.run {
                errorMessage = "Fehler beim Laden des Videos: \(error.localizedDescription)"
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

    private func saveClient(updatedClient: Client) async {
        do {
            var clientToSave = updatedClient
            if let clientID = clientToSave.id {
                await MainActor.run { isUploadingImage = true }
                
                if let image = profileImage {
                    let url = try await FirestoreManager.shared.uploadImage(
                        documentID: clientID,
                        image: image,
                        collection: "profile_images"
                    )
                    clientToSave.profilbildURL = url
                } else if !imageURL.isEmpty {
                    let downloadedImage = try await downloadImage(from: imageURL)
                    let url = try await FirestoreManager.shared.uploadImage(
                        documentID: clientID,
                        image: downloadedImage,
                        collection: "profile_images"
                    )
                    clientToSave.profilbildURL = url
                }

                if let cvData = spielerCVData {
                    let url = try await FirestoreManager.shared.uploadFile(
                        documentID: clientID,
                        data: cvData,
                        collection: "player_cvs",
                        fileName: "cv_\(clientID)"
                    )
                    clientToSave.spielerCV = url
                }

                if let videoData = videoData {
                    let url = try await FirestoreManager.shared.uploadFile(
                        documentID: clientID,
                        data: videoData,
                        collection: "player_videos",
                        fileName: "video_\(clientID)"
                    )
                    clientToSave.video = url
                }

                try await FirestoreManager.shared.updateClient(client: clientToSave)
                await MainActor.run { isUploadingImage = false }
                onSave(clientToSave)
            } else {
                try await FirestoreManager.shared.updateClient(client: clientToSave)
                onSave(clientToSave)
            }
        } catch {
            await MainActor.run {
                errorMessage = "Fehler beim Speichern: \(error.localizedDescription)"
                print("Fehler beim Speichern: \(error)")
                isUploadingImage = false
            }
        }
    }

    private func isValidClient() -> Bool {
        if vorname.isEmpty || name.isEmpty {
            errorMessage = "Vorname und Name sind Pflichtfelder."
            return false
        }
        if let email = kontaktEmail, !email.isEmpty && !isValidEmail(email) {
            errorMessage = "Ungültiges E-Mail-Format."
            return false
        }
        return true
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
}

#Preview {
    EditClientView(
        client: .constant(Client(
            id: "1",
            typ: "Spieler",
            name: "Müller",
            vorname: "Thomas",
            geschlecht: "männlich",
            abteilung: "Männer",
            vereinID: "Bayern Munich",
            nationalitaet: ["Deutschland"],
            geburtsdatum: Date().addingTimeInterval(-25 * 365 * 24 * 60 * 60),
            konditionen: "Gehalt: 10M€, Bonus: 2M€",
            art: "Vereinswechsel",
            spielerCV: "https://example.com/cv.pdf",
            video: "https://example.com/video.mp4"
        )),
        onSave: { _ in },
        onCancel: {}
    )
    .environmentObject(AuthManager())
}
