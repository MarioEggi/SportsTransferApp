import SwiftUI
import FirebaseFirestore
import PhotosUI
import UniformTypeIdentifiers

struct AddClientView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthManager
    @State private var typ = "Spieler"
    @State private var vorname: String = ""
    @State private var name: String = ""
    @State private var geschlecht = "männlich"
    @State private var vereinID: String? = nil
    @State private var vertragBis: Date = Date()
    @State private var vertragsOptionen: String = ""
    @State private var gehalt: String = ""
    @State private var groesse: String = ""
    @State private var nationalmannschaft: String = ""
    @State private var positionFeld: [String] = []
    @State private var schuhmarke: String = ""
    @State private var starkerFuss: String = ""
    @State private var kontaktTelefon: String = ""
    @State private var kontaktEmail: String = ""
    @State private var adresse: String = ""
    @State private var geburtsdatum: Date = Date()
    @State private var clubOptions: [Club] = []
    @State private var sponsorOptions: [Sponsor] = []
    @State private var transfermarktID: String = ""
    @State private var errorMessage: String = ""
    @State private var showingPositionPicker = false
    @State private var showingNationalityPicker = false
    @State private var selectedNationalities: [String] = []
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var profileImage: UIImage? = nil
    @State private var isUploadingImage = false
    @State private var isLoadingTransfermarkt = false
    @State private var transfermarktError = ""
    @State private var liga: String?
    @State private var konditionen: String = ""
    @State private var art: String = ""
    @State private var spielerCVData: Data? = nil
    @State private var spielerCVURL: String? = nil
    @State private var videoData: Data? = nil
    @State private var videoURL: String? = nil
    @State private var showingCVPicker = false
    @State private var showingVideoPicker = false

    // Farben für das helle Design
    private let backgroundColor = Color(hex: "#F5F5F5") // Sehr helles Grau
    private let cardBackgroundColor = Color(hex: "#E0E0E0") // Leicht dunkleres Grau für Karten
    private let accentColor = Color(hex: "#00C4B4") // Akzentfarbe bleibt gleich
    private let textColor = Color(hex: "#333333") // Dunkle Textfarbe
    private let secondaryTextColor = Color(hex: "#666666") // Mittleres Grau für sekundären Text

    var onSave: (() -> Void)?

    var body: some View {
        NavigationView {
            ZStack {
                backgroundColor.edgesIgnoringSafeArea(.all)
                List {
                    clientTypeSection
                    clientDataSection
                    if typ == "Spieler" || typ == "Spielerin" {
                        positionSection
                    }
                    contactInfoSection
                    transfermarktSection
                    additionalInfoSection
                }
                .listStyle(PlainListStyle())
                .listRowInsets(EdgeInsets(top: 3, leading: 13, bottom: 3, trailing: 13))
                .listRowSeparator(.hidden)
                .scrollContentBackground(.hidden)
                .background(backgroundColor)
                .tint(accentColor)
                .foregroundColor(textColor)
                .navigationTitle("Neuer Klient")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Abbrechen") { dismiss() }
                            .foregroundColor(accentColor)
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Speichern") {
                            Task { await saveClient() }
                        }
                        .disabled(!isValidClient())
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
                .onChange(of: selectedPhoto) { _ in
                    Task { await loadSelectedImage() }
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
                }
            }
        }
    }

    private var clientTypeSection: some View {
        Section(header: Text("Kliententyp").foregroundColor(textColor)) {
            VStack(spacing: 10) {
                Picker("Typ", selection: $typ) {
                    Text("Spieler").tag("Spieler")
                    Text("Spielerin").tag("Spielerin")
                    Text("Trainer").tag("Trainer")
                    Text("Sonstige").tag("Sonstige")
                }
                .pickerStyle(.segmented)
                .foregroundColor(textColor)
                .tint(accentColor)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                Picker("Geschlecht", selection: $geschlecht) {
                    Text("Männlich").tag("männlich")
                    Text("Weiblich").tag("weiblich")
                }
                .pickerStyle(.segmented)
                .foregroundColor(textColor)
                .tint(accentColor)
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
    }

    private var clientDataSection: some View {
        Section(header: Text("Klientendaten").foregroundColor(textColor)) {
            VStack(spacing: 10) {
                TextField("Vorname", text: $vorname)
                    .foregroundColor(textColor)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                TextField("Name", text: $name)
                    .foregroundColor(textColor)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                DatePicker("Geburtsdatum", selection: $geburtsdatum, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .foregroundColor(textColor)
                    .tint(accentColor)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                Picker("Verein", selection: $vereinID) {
                    Text("Kein Verein").tag(String?.none)
                    ForEach(clubOptions.filter { $0.abteilungForGender(geschlecht) != nil }) { club in
                        Text(club.name).tag(club.id as String?)
                    }
                }
                .pickerStyle(.menu)
                .foregroundColor(textColor)
                .tint(accentColor)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .onChange(of: vereinID) { _ in updateLeagueAndAbteilung() }
                Text("Liga: \(liga ?? "Keine")")
                    .foregroundColor(secondaryTextColor)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                DatePicker("Vertragslaufzeit", selection: $vertragBis, displayedComponents: .date)
                    .foregroundColor(textColor)
                    .tint(accentColor)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                TextField("Vertragsoptionen", text: $vertragsOptionen)
                    .foregroundColor(textColor)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                TextField("Gehalt (€)", text: $gehalt)
                    .keyboardType(.decimalPad)
                    .foregroundColor(textColor)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                TextField("Größe (cm)", text: $groesse)
                    .keyboardType(.numberPad)
                    .foregroundColor(textColor)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                profileImagePicker
                nationalityPicker
                TextField("Nationalmannschaft", text: $nationalmannschaft)
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
    }

    private var positionSection: some View {
        Section(header: Text("Positionen").foregroundColor(textColor)) {
            VStack(spacing: 10) {
                Button(action: { showingPositionPicker = true }) {
                    Text(positionFeld.isEmpty ? "Positionen auswählen" : positionFeld.joined(separator: ", "))
                        .foregroundColor(positionFeld.isEmpty ? secondaryTextColor : textColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                }
                .sheet(isPresented: $showingPositionPicker) {
                    NavigationView {
                        MultiPicker(
                            title: "Positionen auswählen",
                            selection: $positionFeld,
                            options: Constants.positionOptions,
                            isNationalityPicker: false
                        )
                        .navigationTitle("Positionen")
                        .foregroundColor(textColor)
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("Fertig") { showingPositionPicker = false }
                                    .foregroundColor(accentColor)
                            }
                        }
                        .background(backgroundColor)
                    }
                }
                Picker("Schuhmarke", selection: $schuhmarke) {
                    Text("Keine Marke").tag("")
                    ForEach(sponsorOptions.filter { $0.category == "Sportartikelhersteller" }) { sponsor in
                        Text(sponsor.name).tag(sponsor.name)
                    }
                }
                .pickerStyle(.menu)
                .foregroundColor(textColor)
                .tint(accentColor)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                Picker("Starker Fuß", selection: $starkerFuss) {
                    Text("Nicht angegeben").tag("")
                    ForEach(Constants.strongFootOptions, id: \.self) { foot in
                        Text(foot).tag(foot)
                    }
                }
                .pickerStyle(.menu)
                .foregroundColor(textColor)
                .tint(accentColor)
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
    }

    private var contactInfoSection: some View {
        Section(header: Text("Kontaktinformationen").foregroundColor(textColor)) {
            VStack(spacing: 10) {
                TextField("Telefon", text: $kontaktTelefon)
                    .foregroundColor(textColor)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                TextField("E-Mail", text: $kontaktEmail)
                    .foregroundColor(textColor)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                TextField("Adresse", text: $adresse)
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
    }

    private var transfermarktSection: some View {
        Section(header: Text(geschlecht == "männlich" ? "Transfermarkt" : "Soccerdonna").foregroundColor(textColor)) {
            VStack(spacing: 10) {
                TextField(geschlecht == "männlich" ? "Transfermarkt-ID" : "Soccerdonna-ID", text: $transfermarktID)
                    .keyboardType(.numberPad)
                    .foregroundColor(textColor)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .customPlaceholder(when: transfermarktID.isEmpty) {
                        Text(geschlecht == "männlich" ? "z. B. 690425" : "z. B. 31388")
                            .foregroundColor(secondaryTextColor)
                    }
                    .onChange(of: transfermarktID) { newID in
                        if !newID.isEmpty {
                            Task {
                                await MainActor.run { isLoadingTransfermarkt = true }
                                do {
                                    let playerData: PlayerData
                                    if geschlecht == "männlich" {
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
                                        if positionFeld.isEmpty, let position = playerData.position {
                                            positionFeld = [position]
                                        }
                                        if selectedNationalities.isEmpty, let nationalities = playerData.nationalitaet {
                                            selectedNationalities = nationalities
                                        }
                                        if geburtsdatum == Date(), let birthdate = playerData.geburtsdatum {
                                            geburtsdatum = birthdate
                                        }
                                        if vereinID == nil, let clubID = playerData.vereinID,
                                           let club = clubOptions.first(where: { $0.name == clubID }) {
                                            vereinID = club.id
                                            updateLeagueAndAbteilung()
                                        }
                                        if vertragBis == Date(), let contractEnd = playerData.contractEnd {
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
                        .tint(accentColor)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                }
                if !transfermarktError.isEmpty {
                    Text(transfermarktError)
                        .foregroundColor(.red)
                        .font(.caption)
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

    private var profileImagePicker: some View {
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
            }
        }
        .padding(.vertical, 8)
    }

    private var nationalityPicker: some View {
        Button(action: { showingNationalityPicker = true }) {
            Text(selectedNationalities.isEmpty ? "Nationalitäten auswählen" : selectedNationalities.joined(separator: ", "))
                .foregroundColor(selectedNationalities.isEmpty ? secondaryTextColor : textColor)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
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
        .padding(.vertical, 8)
    }

    private var additionalInfoSection: some View {
        Section(header: Text("Zusätzliche Informationen").foregroundColor(textColor)) {
            VStack(spacing: 10) {
                TextField("Konditionen", text: $konditionen)
                    .foregroundColor(textColor)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                Picker("Art", selection: $art) {
                    Text("Nicht angegeben").tag("")
                    Text("Vereinswechsel").tag("Vereinswechsel")
                    Text("Vertragsverlängerung").tag("Vertragsverlängerung")
                }
                .pickerStyle(.menu)
                .foregroundColor(textColor)
                .tint(accentColor)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                VStack(alignment: .leading, spacing: 10) {
                    Text("Spieler-CV")
                        .font(.subheadline)
                        .foregroundColor(textColor)
                    Button(action: { showingCVPicker = true }) {
                        Label("CV auswählen", systemImage: "doc")
                            .foregroundColor(accentColor)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                    }
                    if let spielerCVURL = spielerCVURL {
                        Text("Hochgeladen: \(spielerCVURL.split(separator: "/").last ?? "")")
                            .font(.caption)
                            .foregroundColor(secondaryTextColor)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                    }
                }
                VStack(alignment: .leading, spacing: 10) {
                    Text("Video")
                        .font(.subheadline)
                        .foregroundColor(textColor)
                    Button(action: { showingVideoPicker = true }) {
                        Label("Video auswählen", systemImage: "video")
                            .foregroundColor(accentColor)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                    }
                    if let videoURL = videoURL {
                        Text("Hochgeladen: \(videoURL.split(separator: "/").last ?? "")")
                            .font(.caption)
                            .foregroundColor(secondaryTextColor)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                    }
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

    private func loadClubOptions() async {
        do {
            let (clubs, _) = try await FirestoreManager.shared.getClubs(lastDocument: nil as DocumentSnapshot?, limit: 1000)
            await MainActor.run {
                self.clubOptions = clubs
                updateLeagueAndAbteilung()
            }
        } catch {
            await MainActor.run {
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
                errorMessage = "Fehler beim Laden der Sponsoren: \(error.localizedDescription)"
                self.sponsorOptions = []
            }
        }
    }

    private func updateLeagueAndAbteilung() {
        if let vereinID = vereinID,
           let selectedClub = clubOptions.first(where: { $0.id == vereinID }) {
            let abteilung = selectedClub.abteilungForGender(geschlecht)
            if geschlecht == "männlich" {
                liga = selectedClub.mensDepartment?.league
            } else if geschlecht == "weiblich" {
                liga = selectedClub.womensDepartment?.league
            }
        } else {
            liga = nil
        }
    }

    private func loadSelectedImage() async {
        guard let photoItem = selectedPhoto else { return }
        do {
            if let data = try await photoItem.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    self.profileImage = image
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = "Fehler beim Laden des Bildes;\(error.localizedDescription)"
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

    private func saveClient() async {
        do {
            var newClient = Client(
                id: nil,
                typ: typ,
                name: name,
                vorname: vorname,
                geschlecht: geschlecht,
                abteilung: nil,
                vereinID: vereinID,
                nationalitaet: selectedNationalities.isEmpty ? nil : selectedNationalities,
                geburtsdatum: geburtsdatum,
                alter: nil,
                kontaktTelefon: kontaktTelefon.isEmpty ? nil : kontaktTelefon,
                kontaktEmail: kontaktEmail.isEmpty ? nil : kontaktEmail,
                adresse: adresse.isEmpty ? nil : adresse,
                liga: liga,
                vertragBis: vertragBis,
                vertragsOptionen: vertragsOptionen.isEmpty ? nil : vertragsOptionen,
                gehalt: Double(gehalt) ?? nil,
                schuhgroesse: nil,
                schuhmarke: schuhmarke.isEmpty ? nil : schuhmarke,
                starkerFuss: starkerFuss.isEmpty ? nil : starkerFuss,
                groesse: Int(groesse) ?? nil,
                gewicht: nil,
                positionFeld: positionFeld.isEmpty ? nil : positionFeld,
                sprachen: nil,
                lizenz: nil,
                nationalmannschaft: nationalmannschaft.isEmpty ? nil : nationalmannschaft,
                profilbildURL: nil,
                transfermarktID: transfermarktID.isEmpty ? nil : transfermarktID,
                userID: authManager.userID ?? UUID().uuidString,
                createdBy: authManager.currentUser?.email,
                konditionen: konditionen.isEmpty ? nil : konditionen,
                art: art.isEmpty ? nil : art,
                spielerCV: nil,
                video: nil
            )
            let clientID = try await FirestoreManager.shared.createClient(client: newClient)
            newClient.id = clientID
            if let image = profileImage {
                await MainActor.run { isUploadingImage = true }
                let url = try await FirestoreManager.shared.uploadImage(
                    documentID: clientID,
                    image: image,
                    collection: "profile_images"
                )
                newClient.profilbildURL = url
            }
            if let cvData = spielerCVData {
                let url = try await FirestoreManager.shared.uploadFile(
                    documentID: clientID,
                    data: cvData,
                    collection: "player_cvs",
                    fileName: "cv_\(clientID)"
                )
                newClient.spielerCV = url
            }
            if let videoData = videoData {
                let url = try await FirestoreManager.shared.uploadFile(
                    documentID: clientID,
                    data: videoData,
                    collection: "player_videos",
                    fileName: "video_\(clientID)"
                )
                newClient.video = url
            }
            try await FirestoreManager.shared.updateClient(client: newClient)
            await MainActor.run {
                isUploadingImage = false
                onSave?()
                dismiss()
            }
        } catch {
            await MainActor.run {
                errorMessage = "Fehler beim Speichern: \(error.localizedDescription)"
                isUploadingImage = false
            }
        }
    }

    private func isValidClient() -> Bool {
        if vorname.isEmpty || name.isEmpty {
            errorMessage = "Vorname und Name sind Pflichtfelder."
            return false
        }
        if !kontaktEmail.isEmpty && !isValidEmail(kontaktEmail) {
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
    AddClientView()
        .environmentObject(AuthManager())
}
