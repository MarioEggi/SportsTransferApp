import SwiftUI
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth
import SDWebImageSwiftUI

// MARK: - ClientViewModel
class ClientViewModel: ObservableObject {
    @Published var image: UIImage?
    @Published var isLoadingImage = false
    @Published var activities: [Activity] = []
    @Published var club: Club?
    @Published var isFavorite = false
    @Published var contract: Contract?
    @Published var transfermarktStats: [String: String] = [:]
    @Published var isLoadingTransfermarktData = false
    @Published var errorMessage = ""

    func loadData(for client: Client, userID: String?) {
        Task { @MainActor in
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await self.loadActivities(clientID: client.id) }
                group.addTask { await self.loadClub(vereinID: client.vereinID) }
                group.addTask { await self.loadContract(clientID: client.id) }
                group.addTask { await self.loadFavoriteStatus(userID: userID, clientID: client.id) }
                group.addTask { await self.loadTransfermarktData(transfermarktID: client.transfermarktID) }
            }
        }
    }

    private func loadActivities(clientID: String?) async {
        guard let clientID = clientID else { return }
        do {
            let loadedActivities = try await FirestoreManager.shared.getActivities(forClientID: clientID)
            await MainActor.run {
                self.activities = loadedActivities
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Fehler beim Laden der Aktivitäten: \(error.localizedDescription)"
            }
        }
    }

    private func loadClub(vereinID: String?) async {
        guard let vereinID = vereinID else { return }
        do {
            let clubs = try await FirestoreManager.shared.getClubs()
            await MainActor.run {
                if let matchingClub = clubs.first(where: { $0.name == vereinID }) {
                    self.club = matchingClub
                }
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Fehler beim Laden des Vereins: \(error.localizedDescription)"
            }
        }
    }

    private func loadContract(clientID: String?) async {
        guard let clientID = clientID else { return }
        do {
            let loadedContract = try await FirestoreManager.shared.getContract(forClientID: clientID)
            await MainActor.run {
                self.contract = loadedContract
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Fehler beim Laden des Vertrags: \(error.localizedDescription)"
            }
        }
    }

    private func loadFavoriteStatus(userID: String?, clientID: String?) async {
        guard let userID = userID, let clientID = clientID else { return }
        if let data = UserDefaults.standard.data(forKey: "favorites_\(userID)"),
           let favorites = try? JSONDecoder().decode(Set<String>.self, from: data) {
            await MainActor.run {
                self.isFavorite = favorites.contains(clientID)
            }
        }
    }

    func toggleFavorite(userID: String?, clientID: String?) {
        guard let userID = userID, let clientID = clientID else { return }
        isFavorite.toggle()
        var favorites = (try? JSONDecoder().decode(Set<String>.self, from: UserDefaults.standard.data(forKey: "favorites_\(userID)") ?? Data())) ?? Set<String>()
        if isFavorite {
            favorites.insert(clientID)
        } else {
            favorites.remove(clientID)
        }
        if let data = try? JSONEncoder().encode(favorites) {
            UserDefaults.standard.set(data, forKey: "favorites_\(userID)")
        }
    }

    private func loadTransfermarktData(transfermarktID: String?) async {
        guard let transfermarktID = transfermarktID else {
            await MainActor.run {
                self.transfermarktStats = [:]
                self.isLoadingTransfermarktData = false
            }
            return
        }
        await MainActor.run {
            self.isLoadingTransfermarktData = true
        }
        do {
            let stats = try await withTimeout(seconds: 10) {
                try await TransfermarktService.shared.fetchTransfermarktData(forPlayerID: transfermarktID)
            }
            await MainActor.run {
                self.transfermarktStats = stats
                self.isLoadingTransfermarktData = false
                print("Geladene Stats: \(stats)")
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Fehler beim Laden der Transfermarkt-Daten: \(error.localizedDescription)"
                self.transfermarktStats = ["Fehler": "Daten konnten nicht geladen werden"]
                self.isLoadingTransfermarktData = false
                print("Fehler: \(error)")
            }
        }
    }

    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask { try await operation() }
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw URLError(.timedOut)
            }
            
            let result = try await group.next() ?? { throw URLError(.cancelled) }()
            group.cancelAll()
            return result
        }
    }

    func uploadImage(_ selectedImage: UIImage, clientID: String?, onCompletion: @escaping (String?) -> Void) {
        guard let clientID = clientID else {
            Task {
                await MainActor.run {
                    self.errorMessage = "Kein Client-ID verfügbar"
                    self.isLoadingImage = false
                }
                onCompletion(nil)
            }
            return
        }
        Task {
            await MainActor.run {
                self.isLoadingImage = true
            }
            do {
                let url = try await FirestoreManager.shared.uploadProfileImage(documentID: clientID, image: selectedImage, collection: "profile_images")
                await MainActor.run {
                    self.isLoadingImage = false
                    onCompletion(url)
                }
            } catch {
                await MainActor.run {
                    self.isLoadingImage = false
                    self.errorMessage = "Fehler beim Hochladen des Bildes: \(error.localizedDescription)"
                    onCompletion(nil)
                }
            }
        }
    }
}

// MARK: - ClientView
struct ClientView: View {
    @EnvironmentObject var authManager: AuthManager
    @Binding var client: Client
    @StateObject private var viewModel = ClientViewModel()
    @State private var showingImagePicker = false
    @State private var showingEditSheet = false
    @State private var showingCreateLoginSheet = false
    @State private var loginEmail = ""
    @State private var loginPassword = ""
    @State private var selectedTab: Int = 0
    @State private var navigateToContractDetail = false

    var previousClientAction: (() -> Void)?
    var nextClientAction: (() -> Void)?

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    private var detailsTab: some View {
        Form {
            Section(header: Text("Spieldaten")) {
                labeledField(label: "Positionen", value: client.positionFeld?.joined(separator: ", "))
                labeledField(label: "Nationalmannschaft", value: client.nationalmannschaft)
                labeledField(label: "Größe", value: client.groesse.map { "\($0) cm" })
                labeledField(label: "Starker Fuß", value: client.starkerFuss)
            }
            
            Section(header: Text("Leistungsdaten (Transfermarkt)")) {
                if viewModel.isLoadingTransfermarktData {
                    ProgressView("Lade Transfermarkt-Daten...")
                        .foregroundColor(.gray)
                } else if viewModel.transfermarktStats.isEmpty {
                    Text("Keine Leistungsdaten verfügbar. Überprüfe die transfermarktID oder die HTML-Struktur.")
                        .foregroundColor(.gray)
                } else {
                    ForEach(viewModel.transfermarktStats.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                        labeledField(label: key, value: value)
                    }
                }
            }
        }
    }

    private var contractTab: some View {
        VStack(spacing: 20) {
            Section(header: Text("Vertragsübersicht")
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.top)) {
                if let contract = viewModel.contract {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Verein:")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Text(contract.vereinID ?? "Nicht angegeben")
                                .font(.body)
                        }
                        HStack {
                            Text("Startdatum:")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Text(dateFormatter.string(from: contract.startDatum))
                                .font(.body)
                        }
                        if let endDatum = contract.endDatum {
                            HStack {
                                Text("Enddatum:")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Text(dateFormatter.string(from: endDatum))
                                    .font(.body)
                            }
                        }
                        if let gehalt = contract.gehalt {
                            HStack {
                                Text("Gehalt:")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Text(String(format: "%.2f €", gehalt))
                                    .font(.body)
                            }
                        }
                        if let vertragsdetails = contract.vertragsdetails {
                            HStack {
                                Text("Details:")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Text(vertragsdetails)
                                    .font(.body)
                                    .lineLimit(2)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                } else {
                    Text("Kein Vertrag für diesen Klienten vorhanden.")
                        .foregroundColor(.gray)
                        .italic()
                        .padding()
                }
            }

            if viewModel.contract != nil {
                Button(action: {
                    navigateToContractDetail = true
                }) {
                    Text("Zum Vertrag")
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                .padding(.horizontal)
            }
        }
        .padding()
    }

    private var contactTab: some View {
        Form {
            Section(header: Text("Kontaktdaten")) {
                if let phone = client.kontaktTelefon {
                    HStack {
                        labeledField(label: "Telefon", value: phone)
                        Spacer()
                        Button(action: { openURL("tel:\(phone)") }) {
                            Image(systemName: "phone.fill")
                                .foregroundColor(.blue)
                        }
                    }
                }
                if let email = client.kontaktEmail {
                    HStack {
                        labeledField(label: "E-Mail", value: email)
                        Spacer()
                        Button(action: { openURL("mailto:\(email)") }) {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(.blue)
                        }
                    }
                }
                labeledField(label: "Adresse", value: client.adresse)
            }
        }
    }

    private func labeledField(label: String, value: String?) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.gray)
            Spacer()
            Text(value ?? "Nicht angegeben")
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(value != nil ? Color(.systemGray6) : Color.clear)
                .cornerRadius(4)
                .foregroundColor(.black)
        }
    }

    private var genderSymbol: String {
        switch client.typ {
        case "Spieler": return "♂"
        case "Spielerin": return "♀"
        default: return ""
        }
    }

    private func calculateAge() -> Int? {
        guard let birthDate = client.geburtsdatum else { return nil }
        let calendar = Calendar.current
        let now = Date()
        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: now)
        return ageComponents.year
    }

    private func openURL(_ urlString: String) {
        if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 15) {
                    // Profilbild und grundlegende Infos
                    VStack(spacing: 10) {
                        if viewModel.isLoadingImage {
                            ProgressView("Lade Bild...")
                                .frame(width: 100, height: 100)
                        } else if let urlString = client.profilbildURL, let url = URL(string: urlString) {
                            WebImage(url: url)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                                .onFailure { _ in
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 100, height: 100)
                                        .foregroundColor(.gray)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                                }
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .foregroundColor(.gray)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                        }

                        Button(action: { showingImagePicker = true }) {
                            Image(systemName: "arrow.up.circle")
                                .font(.system(size: 24))
                                .foregroundColor(.blue)
                                .opacity(0.6)
                        }
                        .sheet(isPresented: $showingImagePicker) {
                            ImagePicker(selectedImage: $viewModel.image, isPresented: $showingImagePicker) { selectedImage in
                                viewModel.uploadImage(selectedImage, clientID: client.id) { url in
                                    if let url = url {
                                        client.profilbildURL = url
                                        Task {
                                            do {
                                                try await FirestoreManager.shared.updateClient(client: client)
                                                print("Client-Profilbild-URL aktualisiert")
                                            } catch {
                                                await MainActor.run {
                                                    viewModel.errorMessage = "Fehler beim Speichern der Bild-URL: \(error.localizedDescription)"
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Text("\(client.vorname) \(client.name)\(calculateAge().map { ", \($0) Jahre" } ?? "")")
                            .font(.title2)
                            .bold()
                            .multilineTextAlignment(.center)

                        if let vereinID = client.vereinID {
                            HStack {
                                if let club = viewModel.club, let logoURL = club.logoURL, let url = URL(string: logoURL) {
                                    WebImage(url: url)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 20, height: 20)
                                        .clipShape(Circle())
                                        .onFailure { _ in
                                            Image(systemName: "building.fill")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 20, height: 20)
                                                .foregroundColor(.gray)
                                        }
                                } else {
                                    Image(systemName: "building.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 20, height: 20)
                                        .foregroundColor(.gray)
                                }
                                Text(vereinID)
                                    .font(.headline)
                            }
                        }
                    }
                    .padding()

                    // Tab-Leiste
                    TabView(selection: $selectedTab) {
                        detailsTab.tag(0)
                        contractTab.tag(1)
                        contactTab.tag(2)
                    }
                    .frame(height: 300)
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))

                    // Tab-Navigation
                    Picker("Abschnitt", selection: $selectedTab) {
                        Text("Details").tag(0)
                        Text("Vertrag").tag(1)
                        Text("Kontaktdaten").tag(2)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()

                    // Leads-Bereich
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Leads / Aktivitäten")
                            .font(.headline)
                        if viewModel.activities.isEmpty {
                            Text("Keine Aktivitäten vorhanden.")
                                .foregroundColor(.gray)
                        } else {
                            ForEach(viewModel.activities.prefix(3)) { activity in
                                NavigationLink(destination: ActivityDetailView(activity: activity)) {
                                    VStack(alignment: .leading) {
                                        Text(activity.description)
                                            .lineLimit(1)
                                        Text(activity.timestamp, style: .date)
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                        }
                    }
                    .padding()

                    // Button: Klienten-Login erstellen
                    if client.userID == nil {
                        Button(action: {
                            showingCreateLoginSheet = true
                        }) {
                            Text("Klienten-Login erstellen")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .padding()
                    } else {
                        Text("Klienten-Login bereits erstellt (UserID: \(client.userID!))")
                            .foregroundColor(.green)
                            .padding()
                    }
                }
                .navigationTitle("\(client.vorname) \(client.name)")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        HStack {
                            if let previous = previousClientAction {
                                Button(action: previous) {
                                    Image(systemName: "chevron.left")
                                        .foregroundColor(.blue)
                                }
                            }
                            if let next = nextClientAction {
                                Button(action: next) {
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack {
                            Text(genderSymbol)
                                .font(.system(size: 14))
                                .foregroundColor(client.typ == "Spieler" ? .blue : .pink)
                            Button(action: { showingEditSheet = true }) {
                                Image(systemName: "pencil")
                                    .foregroundColor(.blue)
                            }
                            Button(action: {
                                viewModel.toggleFavorite(userID: authManager.userID, clientID: client.id)
                            }) {
                                Image(systemName: viewModel.isFavorite ? "star.fill" : "star")
                                    .foregroundColor(viewModel.isFavorite ? .yellow : .gray)
                            }
                        }
                    }
                }
                .sheet(isPresented: $showingEditSheet) {
                    EditClientView(client: $client, onSave: { updatedClient in
                        Task {
                            do {
                                try await FirestoreManager.shared.updateClient(client: updatedClient)
                                await MainActor.run {
                                    client = updatedClient
                                    print("Client erfolgreich aktualisiert")
                                }
                            } catch {
                                await MainActor.run {
                                    viewModel.errorMessage = "Fehler beim Speichern: \(error.localizedDescription)"
                                }
                            }
                            await MainActor.run {
                                showingEditSheet = false
                            }
                        }
                    }, onCancel: {
                        showingEditSheet = false
                    })
                }
                .sheet(isPresented: $showingCreateLoginSheet) {
                    CreateClientLoginView(
                        email: $loginEmail,
                        password: $loginPassword,
                        onSave: {
                            guard !loginEmail.isEmpty, !loginPassword.isEmpty else {
                                viewModel.errorMessage = "E-Mail und Passwort dürfen nicht leer sein."
                                return
                            }
                            guard let clientID = client.id else {
                                viewModel.errorMessage = "Klienten-ID nicht verfügbar."
                                return
                            }
                            Task {
                                do {
                                    try await authManager.createClientLogin(email: loginEmail, password: loginPassword, clientID: clientID) { result in
                                        switch result {
                                        case .success:
                                            client.userID = Auth.auth().currentUser?.uid
                                            Task {
                                                do {
                                                    try await FirestoreManager.shared.updateClient(client: client)
                                                    print("Client mit UserID aktualisiert")
                                                    await MainActor.run {
                                                        showingCreateLoginSheet = false
                                                        loginEmail = ""
                                                        loginPassword = ""
                                                    }
                                                } catch {
                                                    await MainActor.run {
                                                        viewModel.errorMessage = "Fehler beim Aktualisieren des Clients: \(error.localizedDescription)"
                                                    }
                                                }
                                            }
                                        case .failure(let error):
                                            await MainActor.run {
                                                viewModel.errorMessage = "Fehler beim Erstellen des Logins: \(error.localizedDescription)"
                                            }
                                        }
                                    }
                                } catch {
                                    await MainActor.run {
                                        viewModel.errorMessage = "Fehler beim Erstellen des Logins: \(error.localizedDescription)"
                                    }
                                }
                            }
                        },
                        onCancel: {
                            showingCreateLoginSheet = false
                            loginEmail = ""
                            loginPassword = ""
                        }
                    )
                }
                .alert(isPresented: .constant(!viewModel.errorMessage.isEmpty)) {
                    Alert(title: Text("Fehler"), message: Text(viewModel.errorMessage), dismissButton: .default(Text("OK")) {
                        viewModel.errorMessage = ""
                    })
                }
                .onAppear {
                    viewModel.loadData(for: client, userID: authManager.userID)
                }
                .navigationDestination(isPresented: $navigateToContractDetail) {
                    if let contract = viewModel.contract {
                        ContractDetailView(contract: contract)
                    } else {
                        Text("Kein Vertrag verfügbar")
                    }
                }
            }
        }
    }
}

// MARK: - EditClientView (verschachtelte Struktur)
struct EditClientView: View {
    @Binding var client: Client
    var onSave: (Client) -> Void
    var onCancel: () -> Void
    @EnvironmentObject var authManager: AuthManager

    @State private var vorname: String = ""
    @State private var name: String = ""
    @State private var vereinID: String? = nil
    @State private var liga: String = ""
    @State private var vertragBis: Date = Date()
    @State private var vertragsOptionen: String = ""
    @State private var gehalt: String = ""
    @State private var groesse: String = ""
    @State private var nationalitaet: [String] = []
    @State private var nationalmannschaft: String = ""
    @State private var positionFeld: [String] = []
    @State private var schuhmarke: String = ""
    @State private var starkerFuss: String = ""
    @State private var kontaktTelefon: String = ""
    @State private var kontaktEmail: String = ""
    @State private var adresse: String = ""
    @State private var geburtsdatum: Date = Date()
    @State private var clubOptions: [String] = []
    @State private var transfermarktID: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Klientendaten")) {
                    TextField("Vorname", text: $vorname)
                        .disabled(true)
                    TextField("Name", text: $name)
                        .disabled(true)
                    DatePicker("Geburtsdatum", selection: $geburtsdatum, displayedComponents: .date)
                        .disabled(true)
                    Picker("Verein", selection: $vereinID) {
                        Text("Kein Verein").tag(String?.none)
                        ForEach(clubOptions, id: \.self) { club in
                            Text(club).tag(String?.some(club))
                        }
                    }
                    .pickerStyle(.menu)
                    .disabled(true)
                    TextField("Liga", text: $liga)
                        .disabled(true)
                    DatePicker("Vertragslaufzeit", selection: $vertragBis, displayedComponents: .date)
                        .disabled(true)
                    TextField("Vertragsoptionen", text: $vertragsOptionen)
                        .disabled(true)
                    TextField("Gehalt (€)", text: $gehalt)
                        .keyboardType(.decimalPad)
                        .disabled(true)
                    TextField("Grösse (cm)", text: $groesse)
                        .keyboardType(.numberPad)
                        .disabled(true)
                    TextField("Nationalitäten (durch Komma getrennt)", text: Binding(
                        get: { nationalitaet.joined(separator: ", ") },
                        set: { nationalitaet = $0.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) } }
                    ))
                    .disabled(true)
                    TextField("Nationalmannschaft", text: $nationalmannschaft)
                        .disabled(true)
                    TextField("Positionen (durch Komma getrennt)", text: Binding(
                        get: { positionFeld.joined(separator: ", ") },
                        set: { positionFeld = $0.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) } }
                    ))
                    .disabled(true)
                    TextField("Schuhmarke", text: $schuhmarke)
                        .disabled(true)
                    Picker("Starker Fuß", selection: $starkerFuss) {
                        Text("Nicht angegeben").tag("")
                        Text("rechts").tag("rechts")
                        Text("links").tag("links")
                        Text("beide").tag("beide")
                    }
                    .pickerStyle(.menu)
                    .disabled(true)
                }

                Section(header: Text("Kontaktinformationen")) {
                    TextField("Telefon", text: $kontaktTelefon)
                        .disabled(authManager.userRole == .mitarbeiter)
                    TextField("E-Mail", text: $kontaktEmail)
                        .disabled(authManager.userRole == .mitarbeiter)
                    TextField("Adresse", text: $adresse)
                        .disabled(authManager.userRole == .mitarbeiter)
                }

                Section(header: Text("Transfermarkt")) {
                    TextField("Transfermarkt-ID", text: $transfermarktID)
                        .keyboardType(.numberPad)
                        .customPlaceholder(when: transfermarktID.isEmpty) {
                            Text("z. B. 8198")
                                .foregroundColor(.gray)
                        }
                        .disabled(true)
                }
            }
            .navigationTitle("Profil bearbeiten")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { onCancel() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        updateClient()
                        onSave(client)
                    }
                    .disabled(authManager.userRole == .mitarbeiter)
                }
            }
            .task {
                loadClientData()
                await loadClubOptions()
            }
        }
    }

    func loadClubOptions() async {
        do {
            let clubs = try await FirestoreManager.shared.getClubs()
            await MainActor.run {
                self.clubOptions = clubs.filter { club in
                    if client.geschlecht == "männlich" {
                        return club.abteilung == "Männer"
                    } else if client.geschlecht == "weiblich" {
                        return club.abteilung == "Frauen"
                    }
                    return false
                }.map { $0.name }
                if let currentVereinID = client.vereinID, !clubOptions.contains(currentVereinID) {
                    self.clubOptions.insert(currentVereinID, at: 0)
                }
                self.vereinID = client.vereinID
            }
        } catch {
            print("Fehler beim Laden der Vereine: \(error.localizedDescription)")
        }
    }

    func loadClientData() {
        vorname = client.vorname
        name = client.name
        vereinID = client.vereinID
        liga = client.liga ?? ""
        vertragBis = client.vertragBis ?? Date()
        vertragsOptionen = client.vertragsOptionen ?? ""
        gehalt = client.gehalt != nil ? String(client.gehalt!) : ""
        groesse = client.groesse != nil ? String(client.groesse!) : ""
        nationalitaet = client.nationalitaet ?? []
        nationalmannschaft = client.nationalmannschaft ?? ""
        positionFeld = client.positionFeld ?? []
        schuhmarke = client.schuhmarke ?? ""
        starkerFuss = client.starkerFuss ?? ""
        kontaktTelefon = client.kontaktTelefon ?? ""
        kontaktEmail = client.kontaktEmail ?? ""
        adresse = client.adresse ?? ""
        geburtsdatum = client.geburtsdatum ?? Date()
        transfermarktID = client.transfermarktID ?? ""
    }

    func updateClient() {
        client.vorname = vorname.isEmpty ? client.vorname : vorname
        client.name = name.isEmpty ? client.name : name
        client.vereinID = vereinID
        client.liga = liga.isEmpty ? nil : liga
        client.vertragBis = vertragBis
        client.vertragsOptionen = vertragsOptionen.isEmpty ? nil : vertragsOptionen
        client.gehalt = Double(gehalt) ?? nil
        client.groesse = Int(groesse) ?? nil
        client.nationalitaet = nationalitaet.isEmpty ? nil : nationalitaet
        client.nationalmannschaft = nationalmannschaft.isEmpty ? nil : nationalmannschaft
        client.positionFeld = positionFeld.isEmpty ? nil : positionFeld
        client.schuhmarke = schuhmarke.isEmpty ? nil : schuhmarke
        client.starkerFuss = starkerFuss.isEmpty ? nil : starkerFuss
        client.kontaktTelefon = kontaktTelefon.isEmpty ? nil : kontaktTelefon
        client.kontaktEmail = kontaktEmail.isEmpty ? nil : kontaktEmail
        client.adresse = adresse.isEmpty ? nil : adresse
        client.geburtsdatum = geburtsdatum
        client.transfermarktID = transfermarktID.isEmpty ? nil : transfermarktID
    }
}

// MARK: - CreateClientLoginView
struct CreateClientLoginView: View {
    @Binding var email: String
    @Binding var password: String
    let onSave: () -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Klienten-Login erstellen")) {
                    TextField("E-Mail", text: $email)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                    SecureField("Passwort", text: $password)
                        .autocapitalization(.none)
                }
            }
            .navigationTitle("Login erstellen")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { onCancel() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Erstellen") { onSave() }
                }
            }
        }
    }
}

// MARK: - ImagePicker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Binding var isPresented: Bool
    var onImageSelected: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.selectedImage = uiImage
                parent.onImageSelected(uiImage)
            }
            parent.isPresented = false
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isPresented = false
        }
    }
}

#Preview {
    ClientView(client: .constant(Client(
        id: "1",
        typ: "Spieler",
        name: "Müller",
        vorname: "Thomas",
        geschlecht: "männlich",
        vereinID: "Bayern Munich",
        nationalitaet: ["Deutschland"],
        geburtsdatum: Date().addingTimeInterval(-25 * 365 * 24 * 60 * 60),
        kontaktTelefon: "+49123456789",
        kontaktEmail: "thomas.mueller@example.com",
        adresse: "München, Deutschland",
        liga: "1. Bundesliga",
        starkerFuss: "rechts",
        groesse: 186,
        positionFeld: ["Stürmer"],
        nationalmannschaft: "Deutschland",
        transfermarktID: "8198"
    )))
    .environmentObject(AuthManager())
}

extension View {
    func customPlaceholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}
