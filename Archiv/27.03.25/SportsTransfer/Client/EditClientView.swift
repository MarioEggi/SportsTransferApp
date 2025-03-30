import SwiftUI
import FirebaseFirestore
import PhotosUI

struct EditClientView: View {
    @Binding var client: Client
    var onSave: (Client) -> Void
    var onCancel: () -> Void
    @EnvironmentObject var authManager: AuthManager

    @State private var vorname: String = ""
    @State private var name: String = ""
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
    @StateObject private var contractViewModel = ContractViewModel()

    var body: some View {
        NavigationView {
            Form {
                clientDataSection
                if client.typ == "Spieler" || client.typ == "Spielerin" {
                    positionSection
                }
                contactInfoSection
                transfermarktSection
            }
            .navigationTitle("Profil bearbeiten")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { onCancel() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        Task { await saveClient() }
                    }
                    .disabled(!isValidClient())
                }
            }
            .alert(isPresented: .constant(!errorMessage.isEmpty)) {
                Alert(
                    title: Text("Fehler"),
                    message: Text(errorMessage),
                    dismissButton: .default(Text("OK")) { errorMessage = "" }
                )
            }
            .onChange(of: selectedPhoto) { _ in
                Task { await loadSelectedImage() }
            }
            .task {
                await loadClubOptions()
                await loadSponsors()
                await loadContractData()
                loadClientData()
            }
        }
    }

    private var clientDataSection: some View {
        Section(header: Text("Klientendaten")) {
            TextField("Vorname", text: $vorname)
            TextField("Name", text: $name)
            DatePicker("Geburtsdatum", selection: $geburtsdatum, displayedComponents: .date)
                .datePickerStyle(.compact)
            Picker("Verein", selection: $vereinID) {
                Text("Kein Verein").tag(String?.none)
                ForEach(clubOptions.filter { $0.abteilungForGender(client.geschlecht) != nil }) { club in
                    Text(club.name).tag(club.id as String?)
                }
            }
            .pickerStyle(.menu)
            .onChange(of: vereinID) { _ in updateLeagueAndAbteilung() }
            Text("Liga: \(client.liga ?? "Keine")")
                .foregroundColor(.gray)
            DatePicker("Vertragslaufzeit", selection: $vertragBis, displayedComponents: .date)
            TextField("Vertragsoptionen", text: $vertragsOptionen)
            TextField("Gehalt (€)", text: $gehalt)
                .keyboardType(.decimalPad)
            TextField("Größe (cm)", text: $groesse)
                .keyboardType(.numberPad)
            profileImagePicker
            nationalityPicker
            TextField("Nationalmannschaft", text: $nationalmannschaft)
        }
    }

    private var positionSection: some View {
        Section(header: Text("Positionen")) {
            Button(action: { showingPositionPicker = true }) {
                Text(positionFeld.isEmpty ? "Positionen auswählen" : positionFeld.joined(separator: ", "))
                    .foregroundColor(positionFeld.isEmpty ? .gray : .black)
                    .frame(maxWidth: .infinity, alignment: .leading)
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
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Fertig") { showingPositionPicker = false }
                        }
                    }
                }
            }
            Picker("Schuhmarke", selection: $schuhmarke) {
                Text("Keine Marke").tag("")
                ForEach(sponsorOptions.filter { $0.category == "Sportartikelhersteller" }) { sponsor in
                    Text(sponsor.name).tag(sponsor.name)
                }
            }
            .pickerStyle(.menu)
            Picker("Starker Fuß", selection: $starkerFuss) {
                Text("Nicht angegeben").tag("")
                ForEach(Constants.strongFootOptions, id: \.self) { foot in
                    Text(foot).tag(foot)
                }
            }
            .pickerStyle(.menu)
        }
    }

    private var contactInfoSection: some View {
        Section(header: Text("Kontaktinformationen")) {
            TextField("Telefon", text: $kontaktTelefon)
            TextField("E-Mail", text: $kontaktEmail)
            TextField("Adresse", text: $adresse)
        }
    }

    private var transfermarktSection: some View {
        Section(header: Text(client.geschlecht == "männlich" ? "Transfermarkt" : "Soccerdonna")) {
            TextField(client.geschlecht == "männlich" ? "Transfermarkt-ID" : "Soccerdonna-ID", text: $transfermarktID)
                .keyboardType(.numberPad)
                .customPlaceholder(when: transfermarktID.isEmpty) {
                    Text(client.geschlecht == "männlich" ? "z. B. 690425" : "z. B. 31388")
                        .foregroundColor(.gray)
                }
                .onChange(of: transfermarktID) { newID in
                    if !newID.isEmpty {
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
            }
            if !transfermarktError.isEmpty {
                Text(transfermarktError)
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
    }

    private var profileImagePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Profilbild")
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
        Button(action: { showingNationalityPicker = true }) {
            Text(selectedNationalities.isEmpty ? "Nationalitäten auswählen" : selectedNationalities.joined(separator: ", "))
                .foregroundColor(selectedNationalities.isEmpty ? .gray : .black)
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
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Fertig") {
                            client.nationalitaet = selectedNationalities.isEmpty ? nil : selectedNationalities
                            showingNationalityPicker = false
                        }
                    }
                }
            }
        }
    }

    private func loadClubOptions() async {
        do {
            let (clubs, _) = try await FirestoreManager.shared.getClubs(lastDocument: nil as DocumentSnapshot?, limit: 1000)
            await MainActor.run {
                self.clubOptions = clubs
                updateLeagueAndAbteilung()
            }
        } catch {
            errorMessage = "Fehler beim Laden der Vereine: \(error.localizedDescription)"
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
                    vertragBis = contract.endDatum ?? Date()
                    vertragsOptionen = contract.vertragsdetails ?? ""
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = "Fehler beim Laden der Vertragsdaten: \(error.localizedDescription)"
            }
        }
    }

    private func updateLeagueAndAbteilung() {
        if let vereinID = vereinID,
           let selectedClub = clubOptions.first(where: { $0.id == vereinID }) {
            client.abteilung = selectedClub.abteilungForGender(client.geschlecht)
            if client.geschlecht == "männlich" {
                client.liga = selectedClub.mensDepartment?.league
                print("Liga für Männer gesetzt: \(client.liga ?? "Keine")")
            } else if client.geschlecht == "weiblich" {
                client.liga = selectedClub.womensDepartment?.league
                print("Liga für Frauen gesetzt: \(client.liga ?? "Keine")")
            }
        } else {
            client.abteilung = nil
            client.liga = nil
            print("Kein Verein ausgewählt, Liga zurückgesetzt")
        }
    }

    private func loadClientData() {
        vorname = client.vorname
        name = client.name
        vereinID = client.vereinID
        vertragBis = client.vertragBis ?? Date()
        vertragsOptionen = client.vertragsOptionen ?? ""
        gehalt = client.gehalt != nil ? String(client.gehalt!) : ""
        groesse = client.groesse != nil ? String(client.groesse!) : ""
        nationalmannschaft = client.nationalmannschaft ?? ""
        selectedNationalities = client.nationalitaet ?? []
        positionFeld = client.positionFeld ?? []
        schuhmarke = client.schuhmarke ?? ""
        starkerFuss = client.starkerFuss ?? ""
        kontaktTelefon = client.kontaktTelefon ?? ""
        kontaktEmail = client.kontaktEmail ?? ""
        adresse = client.adresse ?? ""
        geburtsdatum = client.geburtsdatum ?? Date()
        transfermarktID = client.transfermarktID ?? ""
    }

    private func loadSelectedImage() async {
        guard let photoItem = selectedPhoto else { return }
        do {
            if let data = try await photoItem.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    self.profileImage = image
                    self.client.profilbildURL = nil
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = "Fehler beim Laden des Bildes: \(error.localizedDescription)"
            }
        }
    }

    private func saveClient() async {
        do {
            print("Vor dem Speichern - Client: \(client)")
            if let image = profileImage, let clientID = client.id {
                await MainActor.run { isUploadingImage = true }
                let url = try await FirestoreManager.shared.uploadImage(
                    documentID: clientID,
                    image: image,
                    collection: "profile_images"
                )
                client.profilbildURL = url
                await MainActor.run { isUploadingImage = false }
            }
            updateClient()
            print("Nach updateClient - Client: \(client)")
            onSave(client)
            print("Nach onSave - Client: \(client)")
        } catch {
            await MainActor.run {
                errorMessage = "Fehler beim Speichern: \(error.localizedDescription)"
                print("Fehler beim Speichern: \(error.localizedDescription)")
                isUploadingImage = false
            }
        }
    }

    private func updateClient() {
        var updatedClient = client
        updatedClient.vorname = vorname
        updatedClient.name = name
        updatedClient.vereinID = vereinID
        updatedClient.vertragBis = vertragBis
        updatedClient.vertragsOptionen = vertragsOptionen.isEmpty ? nil : vertragsOptionen
        updatedClient.gehalt = Double(gehalt) ?? nil
        updatedClient.groesse = Int(groesse) ?? nil
        updatedClient.nationalitaet = selectedNationalities.isEmpty ? nil : selectedNationalities
        updatedClient.nationalmannschaft = nationalmannschaft.isEmpty ? nil : nationalmannschaft
        updatedClient.positionFeld = positionFeld.isEmpty ? nil : positionFeld
        updatedClient.schuhmarke = schuhmarke.isEmpty ? nil : schuhmarke
        updatedClient.starkerFuss = starkerFuss.isEmpty ? nil : starkerFuss
        updatedClient.kontaktTelefon = kontaktTelefon.isEmpty ? nil : kontaktTelefon
        updatedClient.kontaktEmail = kontaktEmail.isEmpty ? nil : kontaktEmail
        updatedClient.adresse = adresse.isEmpty ? nil : adresse
        updatedClient.geburtsdatum = geburtsdatum
        updatedClient.transfermarktID = transfermarktID.isEmpty ? nil : transfermarktID
        updateLeagueAndAbteilung()
        client = updatedClient
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
            geburtsdatum: Date().addingTimeInterval(-25 * 365 * 24 * 60 * 60)
        )),
        onSave: { _ in },
        onCancel: {}
    )
    .environmentObject(AuthManager())
}
