import SwiftUI

struct AddProcessView: View {
    @Environment(\.dismiss) var dismiss
    let onSave: () -> Void
    
    @State private var processType: ProcessType = .transfer
    @State private var transfer = TransferProcess(clientID: "", vereinID: "")
    @State private var sponsoring = SponsoringProcess(clientID: "", sponsorID: "")
    @State private var profile = ProfileRequest(vereinID: "", abteilung: "Frauen", gesuchtePositionen: [])
    
    // Daten für Suchfelder
    @State private var clients: [Client] = []
    @State private var clubs: [Club] = []
    @State private var sponsors: [Sponsor] = []
    @State private var funktionäre: [Funktionär] = []
    
    // Zustände für gefilterte Vereine basierend auf Geschlecht/Abteilung
    @State private var filteredClientsForTransfer: [Client] = []
    @State private var filteredClubsForTransfer: [Club] = []
    @State private var filteredClientsForProfile: [Client] = []
    @State private var filteredClubsForProfile: [Club] = []
    
    // Farben für helles Design
    private let backgroundColor = Color(hex: "#F5F5F5")
    private let cardBackgroundColor = Color(hex: "#E0E0E0")
    private let accentColor = Color(hex: "#00C4B4")
    private let textColor = Color(hex: "#333333")
    private let secondaryTextColor = Color(hex: "#666666")
    
    enum ProcessType: String, CaseIterable, Identifiable {
        case transfer = "Transfer/Verlängerung"
        case sponsoring = "Sponsoring"
        case profile = "Profil-Anfrage"
        var id: String { rawValue }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundColor.edgesIgnoringSafeArea(.all)
                List {
                    Section(header: Text("Prozessart").foregroundColor(textColor)) {
                        Picker("Prozessart", selection: $processType) {
                            ForEach(ProcessType.allCases) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(.menu)
                        .foregroundColor(textColor)
                        .tint(accentColor)
                    }
                    .listRowBackground(cardBackgroundColor)
                    
                    switch processType {
                    case .transfer:
                        TransferFormView(transfer: $transfer, clients: filteredClientsForTransfer, clubs: filteredClubsForTransfer, funktionäre: funktionäre)
                    case .sponsoring:
                        SponsoringFormView(sponsoring: $sponsoring, clients: clients, sponsors: sponsors, funktionäre: funktionäre)
                    case .profile:
                        ProfileFormView(profile: $profile, clients: filteredClientsForProfile, clubs: filteredClubsForProfile, funktionäre: funktionäre)
                    }
                }
                .listStyle(PlainListStyle())
                .scrollContentBackground(.hidden)
                .background(backgroundColor)
                .navigationTitle("Neuer Prozess")
                .foregroundColor(textColor)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Abbrechen") { dismiss() }
                            .foregroundColor(accentColor)
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Speichern") {
                            Task {
                                switch processType {
                                case .transfer:
                                    _ = try await FirestoreManager.shared.createTransferProcess(transferProcess: transfer)
                                case .sponsoring:
                                    _ = try await FirestoreManager.shared.createSponsoringProcess(sponsoringProcess: sponsoring)
                                case .profile:
                                    _ = try await FirestoreManager.shared.createProfileRequest(profileRequest: profile)
                                }
                                await MainActor.run {
                                    onSave()
                                    dismiss()
                                }
                            }
                        }
                        .foregroundColor(accentColor)
                    }
                }
            }
            .onAppear {
                Task {
                    await loadInitialData()
                }
            }
            .onChange(of: transfer.clientID) { _ in
                updateFilteredClubsForTransfer()
            }
            .onChange(of: profile.abteilung) { _ in
                updateFilteredClientsAndClubsForProfile()
            }
        }
    }
    
    // Lade initiale Daten für Suchfelder
    private func loadInitialData() async {
        do {
            let (loadedClients, _) = try await FirestoreManager.shared.getClients(lastDocument: nil, limit: 1000)
            let (loadedClubs, _) = try await FirestoreManager.shared.getClubs(lastDocument: nil, limit: 1000)
            let (loadedSponsors, _) = try await FirestoreManager.shared.getSponsors(lastDocument: nil, limit: 1000)
            let (loadedFunktionäre, _) = try await FirestoreManager.shared.getFunktionäre(lastDocument: nil, limit: 1000)
            await MainActor.run {
                clients = loadedClients
                clubs = loadedClubs
                sponsors = loadedSponsors
                funktionäre = loadedFunktionäre
                filteredClientsForTransfer = loadedClients
                updateFilteredClubsForTransfer()
                updateFilteredClientsAndClubsForProfile()
            }
        } catch {
            print("Fehler beim Laden der Daten: \(error)")
        }
    }
    
    // Filter Klienten und Clubs für Transfer basierend auf Geschlecht
    private func updateFilteredClubsForTransfer() {
        if transfer.clientID.isEmpty {
            filteredClientsForTransfer = clients
            filteredClubsForTransfer = clubs
        } else if let selectedClient = clients.first(where: { $0.id == transfer.clientID }) {
            let geschlecht = selectedClient.geschlecht ?? "Männer"
            filteredClientsForTransfer = clients.filter { $0.geschlecht == geschlecht }
            filteredClubsForTransfer = clubs.filter { club in
                club.abteilungForGender(geschlecht) != nil
            }
            if let club = clubs.first(where: { $0.id == transfer.vereinID }) {
                transfer.abteilung = club.abteilungForGender(geschlecht)
            }
        }
    }
    
    // Filter Klienten und Clubs für Profil-Anfrage basierend auf Abteilung
    private func updateFilteredClientsAndClubsForProfile() {
        let selectedAbteilung = profile.abteilung
        let geschlecht = selectedAbteilung == "Frauen" ? "weiblich" : "männlich"
        filteredClientsForProfile = clients.filter { $0.geschlecht == geschlecht && ($0.abteilung == selectedAbteilung || $0.abteilung == nil) }
        filteredClubsForProfile = clubs.filter { club in
            club.abteilungForGender(geschlecht) == selectedAbteilung
        }
    }
}

// Modal-Suchfenster
struct SearchModalView<T: Identifiable>: View {
    let items: [T]
    let displayText: (T) -> String
    let idKeyPath: KeyPath<T, String?>
    let onSelect: (T) -> Void
    @Binding var isPresented: Bool
    @State private var searchText: String = ""
    @State private var filteredItems: [T] = []
    
    private let textColor = Color(hex: "#333333")
    private let accentColor = Color(hex: "#00C4B4")
    private let cardBackgroundColor = Color(hex: "#E0E0E0")
    
    var body: some View {
        NavigationView {
            VStack {
                TextField("Suchen", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .onChange(of: searchText) { _ in
                        updateFilteredItems()
                    }
                
                List(filteredItems) { item in
                    Text(displayText(item))
                        .foregroundColor(textColor)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(cardBackgroundColor)
                        .onTapGesture {
                            onSelect(item)
                            isPresented = false
                        }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Suche")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        isPresented = false
                    }
                    .foregroundColor(accentColor)
                }
            }
        }
        .onAppear {
            updateFilteredItems()
        }
    }
    
    private func updateFilteredItems() {
        if searchText.isEmpty {
            filteredItems = items
        } else {
            filteredItems = items.filter { displayText($0).lowercased().contains(searchText.lowercased()) }
        }
    }
}

// Transfer-Formular (unverändert)
struct TransferFormView: View {
    @Binding var transfer: TransferProcess
    let clients: [Client]
    let clubs: [Club]
    let funktionäre: [Funktionär]
    
    @State private var showingClientSearch = false
    @State private var showingClubSearch = false
    @State private var showingFunktionärSearch = false
    @State private var clientSearchText: String = ""
    @State private var clubSearchText: String = ""
    @State private var funktionärSearchText: String = ""
    @State private var filteredFunktionäre: [Funktionär] = []
    
    private let textColor = Color(hex: "#333333")
    private let secondaryTextColor = Color(hex: "#666666")
    private let cardBackgroundColor = Color(hex: "#E0E0E0")
    private let accentColor = Color(hex: "#00C4B4")
    
    var body: some View {
        Section(header: Text("Transfer Details").foregroundColor(textColor)) {
            HStack {
                TextField("Klient", text: $clientSearchText)
                    .foregroundColor(textColor)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button(action: {
                    showingClientSearch = true
                }) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(accentColor)
                }
            }
            .sheet(isPresented: $showingClientSearch) {
                SearchModalView(
                    items: clients,
                    displayText: { "\($0.vorname) \($0.name)" },
                    idKeyPath: \.id,
                    onSelect: { client in
                        transfer.clientID = client.id ?? ""
                        clientSearchText = "\(client.vorname) \(client.name)"
                        if let clubID = client.vereinID {
                            transfer.vereinID = clubID
                            clubSearchText = clubs.first(where: { $0.id == clubID })?.name ?? ""
                            updateFilteredFunktionäre()
                        }
                        if let liga = client.liga {
                            transfer.liga = liga
                        }
                        if let abteilung = client.abteilung {
                            transfer.abteilung = abteilung
                        }
                    },
                    isPresented: $showingClientSearch
                )
            }
            
            HStack {
                TextField("Verein", text: $clubSearchText)
                    .foregroundColor(textColor)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button(action: {
                    showingClubSearch = true
                }) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(accentColor)
                }
            }
            .sheet(isPresented: $showingClubSearch) {
                SearchModalView(
                    items: clubs,
                    displayText: { $0.name },
                    idKeyPath: \.id,
                    onSelect: { club in
                        transfer.vereinID = club.id ?? ""
                        clubSearchText = club.name
                        transfer.abteilung = club.abteilungForGender(clients.first(where: { $0.id == transfer.clientID })?.geschlecht ?? "Männer")
                        updateFilteredFunktionäre()
                    },
                    isPresented: $showingClubSearch
                )
            }
            
            HStack {
                TextField("Funktionär", text: $funktionärSearchText)
                    .foregroundColor(textColor)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button(action: {
                    showingFunktionärSearch = true
                }) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(accentColor)
                }
            }
            .sheet(isPresented: $showingFunktionärSearch) {
                SearchModalView(
                    items: filteredFunktionäre,
                    displayText: { "\($0.vorname) \($0.name)" },
                    idKeyPath: \.id,
                    onSelect: { funktionär in
                        transfer.funktionärID = funktionär.id
                        funktionärSearchText = "\(funktionär.vorname) \(funktionär.name)"
                    },
                    isPresented: $showingFunktionärSearch
                )
            }
            
            Picker("Initiator", selection: $transfer.kontaktInitiator) {
                Text("Nicht angegeben").tag(String?.none)
                Text("Verein").tag("Verein" as String?)
                Text("Wir").tag("Wir" as String?)
            }
            .pickerStyle(.menu)
            .foregroundColor(textColor)
            .tint(accentColor)
            
            Picker("Art", selection: $transfer.art) {
                Text("Nicht angegeben").tag(String?.none)
                Text("Vereinswechsel").tag("Vereinswechsel" as String?)
                Text("Vertragsverlängerung").tag("Vertragsverlängerung" as String?)
            }
            .pickerStyle(.menu)
            .foregroundColor(textColor)
            .tint(accentColor)
            
            Picker("Abteilung", selection: $transfer.abteilung) {
                Text("Nicht angegeben").tag(String?.none)
                Text("Frauen").tag("Frauen" as String?)
                Text("Männer").tag("Männer" as String?)
            }
            .pickerStyle(.menu)
            .foregroundColor(textColor)
            .tint(accentColor)
            .disabled(!transfer.clientID.isEmpty)
            
            TextField("Priorität (1-5)", value: $transfer.priority, formatter: NumberFormatter())
                .foregroundColor(textColor)
            TextField("Titel", text: Binding(get: { transfer.title ?? "" }, set: { transfer.title = $0.isEmpty ? nil : $0 }))
                .foregroundColor(textColor)
            TextField("Konditionen", text: Binding(get: { transfer.konditionen ?? "" }, set: { transfer.konditionen = $0.isEmpty ? nil : $0 }))
                .foregroundColor(textColor)
        }
        .listRowBackground(cardBackgroundColor)
        .onAppear {
            updateFilteredFunktionäre()
        }
    }
    
    private func updateFilteredFunktionäre() {
        let selectedClubID = transfer.vereinID
        if !selectedClubID.isEmpty {
            filteredFunktionäre = funktionäre.filter { $0.vereinID == selectedClubID }
        } else {
            filteredFunktionäre = []
        }
    }
}

// Sponsoring-Formular (unverändert)
struct SponsoringFormView: View {
    @Binding var sponsoring: SponsoringProcess
    let clients: [Client]
    let sponsors: [Sponsor]
    let funktionäre: [Funktionär]
    
    @State private var showingClientSearch = false
    @State private var showingSponsorSearch = false
    @State private var showingAnsprechpersonSearch = false
    @State private var clientSearchText: String = ""
    @State private var sponsorSearchText: String = ""
    @State private var ansprechpersonSearchText: String = ""
    @State private var filteredFunktionäre: [Funktionär] = []
    
    private let textColor = Color(hex: "#333333")
    private let secondaryTextColor = Color(hex: "#666666")
    private let cardBackgroundColor = Color(hex: "#E0E0E0")
    private let accentColor = Color(hex: "#00C4B4")
    
    var body: some View {
        Section(header: Text("Sponsoring Details").foregroundColor(textColor)) {
            HStack {
                TextField("Klient", text: $clientSearchText)
                    .foregroundColor(textColor)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button(action: {
                    showingClientSearch = true
                }) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(accentColor)
                }
            }
            .sheet(isPresented: $showingClientSearch) {
                SearchModalView(
                    items: clients,
                    displayText: { "\($0.vorname) \($0.name)" },
                    idKeyPath: \.id,
                    onSelect: { client in
                        sponsoring.clientID = client.id ?? ""
                        clientSearchText = "\(client.vorname) \(client.name)"
                    },
                    isPresented: $showingClientSearch
                )
            }
            
            HStack {
                TextField("Sponsor", text: $sponsorSearchText)
                    .foregroundColor(textColor)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button(action: {
                    showingSponsorSearch = true
                }) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(accentColor)
                }
            }
            .sheet(isPresented: $showingSponsorSearch) {
                SearchModalView(
                    items: sponsors,
                    displayText: { $0.name },
                    idKeyPath: \.id,
                    onSelect: { sponsor in
                        sponsoring.sponsorID = sponsor.id ?? ""
                        sponsorSearchText = sponsor.name
                        updateFilteredFunktionäre()
                    },
                    isPresented: $showingSponsorSearch
                )
            }
            
            HStack {
                TextField("Ansprechperson", text: $ansprechpersonSearchText)
                    .foregroundColor(textColor)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button(action: {
                    showingAnsprechpersonSearch = true
                }) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(accentColor)
                }
            }
            .sheet(isPresented: $showingAnsprechpersonSearch) {
                SearchModalView(
                    items: filteredFunktionäre,
                    displayText: { "\($0.vorname) \($0.name)" },
                    idKeyPath: \.id,
                    onSelect: { funktionär in
                        sponsoring.funktionärID = funktionär.id
                        ansprechpersonSearchText = "\(funktionär.vorname) \(funktionär.name)"
                    },
                    isPresented: $showingAnsprechpersonSearch
                )
            }
            
            Picker("Initiator", selection: $sponsoring.kontaktInitiator) {
                Text("Nicht angegeben").tag(String?.none)
                Text("Sponsor").tag("Sponsor" as String?)
                Text("Wir").tag("Wir" as String?)
            }
            .pickerStyle(.menu)
            .foregroundColor(textColor)
            .tint(accentColor)
            
            Picker("Art", selection: $sponsoring.art) {
                Text("Nicht angegeben").tag(String?.none)
                Text("Ausrüstervertrag").tag("Ausrüstervertrag" as String?)
                Text("Sponsoring").tag("Sponsoring" as String?)
            }
            .pickerStyle(.menu)
            .foregroundColor(textColor)
            .tint(accentColor)
            
            TextField("Priorität (1-5)", value: $sponsoring.priority, formatter: NumberFormatter())
                .foregroundColor(textColor)
            TextField("Titel", text: Binding(get: { sponsoring.title ?? "" }, set: { sponsoring.title = $0.isEmpty ? nil : $0 }))
                .foregroundColor(textColor)
            TextField("Konditionen", text: Binding(get: { sponsoring.konditionen ?? "" }, set: { sponsoring.konditionen = $0.isEmpty ? nil : $0 }))
                .foregroundColor(textColor)
        }
        .listRowBackground(cardBackgroundColor)
        .onAppear {
            updateFilteredFunktionäre()
        }
    }
    
    private func updateFilteredFunktionäre() {
        let selectedSponsorID = sponsoring.sponsorID
        if !selectedSponsorID.isEmpty {
            filteredFunktionäre = funktionäre.filter { $0.id == selectedSponsorID }
        } else {
            filteredFunktionäre = []
        }
    }
}

// Profil-Anfrage-Formular (mit Klienten-Suche hinzugefügt)
struct ProfileFormView: View {
    @Binding var profile: ProfileRequest
    let clients: [Client]
    let clubs: [Club]
    let funktionäre: [Funktionär]
    
    @State private var showingClientSearch = false
    @State private var showingClubSearch = false
    @State private var showingFunktionärSearch = false
    @State private var clientSearchText: String = ""
    @State private var clubSearchText: String = ""
    @State private var funktionärSearchText: String = ""
    @State private var filteredFunktionäre: [Funktionär] = []
    @State private var newPosition: String = ""
    @State private var newStarkerFuss: String? = nil
    @State private var newAlterMin: Int?
    @State private var newAlterMax: Int?
    @State private var newGroesseMin: Int?
    @State private var newTempoMin: Int?
    @State private var newWeitereKriterien: String = ""
    
    private let textColor = Color(hex: "#333333")
    private let secondaryTextColor = Color(hex: "#666666")
    private let cardBackgroundColor = Color(hex: "#E0E0E0")
    private let accentColor = Color(hex: "#00C4B4")
    
    var body: some View {
        Section(header: Text("Profil-Anfrage").foregroundColor(textColor)) {
            Picker("Abteilung", selection: $profile.abteilung) {
                Text("Frauen").tag("Frauen")
                Text("Männer").tag("Männer")
            }
            .pickerStyle(.menu)
            .foregroundColor(textColor)
            .tint(accentColor)
            
            // Klient Suche
            HStack {
                TextField("Klient (optional)", text: $clientSearchText)
                    .foregroundColor(textColor)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button(action: {
                    showingClientSearch = true
                }) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(accentColor)
                }
            }
            .sheet(isPresented: $showingClientSearch) {
                SearchModalView(
                    items: clients,
                    displayText: { "\($0.vorname) \($0.name)" },
                    idKeyPath: \.id,
                    onSelect: { client in
                        clientSearchText = "\(client.vorname) \(client.name)"
                        // Optional: Speichere clientID, falls benötigt
                    },
                    isPresented: $showingClientSearch
                )
            }
            
            // Verein Suche
            HStack {
                TextField("Verein", text: $clubSearchText)
                    .foregroundColor(textColor)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button(action: {
                    showingClubSearch = true
                }) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(accentColor)
                }
            }
            .sheet(isPresented: $showingClubSearch) {
                SearchModalView(
                    items: clubs.filter { $0.abteilungForGender(profile.abteilung == "Frauen" ? "weiblich" : "männlich") == profile.abteilung },
                    displayText: { $0.name },
                    idKeyPath: \.id,
                    onSelect: { club in
                        profile.vereinID = club.id ?? ""
                        clubSearchText = club.name
                        updateFilteredFunktionäre()
                    },
                    isPresented: $showingClubSearch
                )
            }
            
            // Funktionär basierend auf Verein und Abteilung
            HStack {
                TextField("Funktionär", text: $funktionärSearchText)
                    .foregroundColor(textColor)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button(action: {
                    showingFunktionärSearch = true
                }) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(accentColor)
                }
            }
            .sheet(isPresented: $showingFunktionärSearch) {
                SearchModalView(
                    items: filteredFunktionäre,
                    displayText: { "\($0.vorname) \($0.name)" },
                    idKeyPath: \.id,
                    onSelect: { funktionär in
                        profile.funktionärID = funktionär.id
                        funktionärSearchText = "\(funktionär.vorname) \(funktionär.name)"
                    },
                    isPresented: $showingFunktionärSearch
                )
            }
            
            Picker("Initiator", selection: $profile.kontaktInitiator) {
                Text("Nicht angegeben").tag(String?.none)
                Text("Verein").tag("Verein" as String?)
                Text("Wir").tag("Wir" as String?)
            }
            .pickerStyle(.menu)
            .foregroundColor(textColor)
            .tint(accentColor)
            
            // Eingabe für neue Position mit Kriterien
            VStack(spacing: 8) {
                Picker("Position", selection: $newPosition) {
                    Text("Nicht angegeben").tag("")
                    ForEach(Constants.positionOptions, id: \.self) { position in
                        Text(position).tag(position)
                    }
                }
                .pickerStyle(.menu)
                .foregroundColor(textColor)
                .tint(accentColor)
                
                Picker("Starker Fuß", selection: $newStarkerFuss) {
                    Text("Nicht angegeben").tag(String?.none)
                    ForEach(Constants.strongFootOptions, id: \.self) { foot in
                        Text(foot).tag(foot as String?)
                    }
                }
                .pickerStyle(.menu)
                .foregroundColor(textColor)
                .tint(accentColor)
                
                TextField("Alter Min", value: $newAlterMin, formatter: NumberFormatter())
                    .foregroundColor(textColor)
                TextField("Alter Max", value: $newAlterMax, formatter: NumberFormatter())
                    .foregroundColor(textColor)
                TextField("Größe Min (cm)", value: $newGroesseMin, formatter: NumberFormatter())
                    .foregroundColor(textColor)
                TextField("Tempo Min (0-100)", value: $newTempoMin, formatter: NumberFormatter())
                    .foregroundColor(textColor)
                TextField("Weitere Kriterien", text: $newWeitereKriterien)
                    .foregroundColor(textColor)
                
                Button(action: {
                    if !newPosition.isEmpty {
                        let criteria = ProfileRequest.PositionCriteria(
                            position: newPosition,
                            alterMin: newAlterMin,
                            alterMax: newAlterMax,
                            groesseMin: newGroesseMin,
                            tempoMin: newTempoMin,
                            weitereKriterien: newWeitereKriterien.isEmpty ? newStarkerFuss : (newWeitereKriterien + (newStarkerFuss != nil ? ", Starker Fuß: \(newStarkerFuss!)" : ""))
                        )
                        profile.gesuchtePositionen.append(criteria)
                        newPosition = ""
                        newStarkerFuss = nil
                        newAlterMin = nil
                        newAlterMax = nil
                        newGroesseMin = nil
                        newTempoMin = nil
                        newWeitereKriterien = ""
                    }
                }) {
                    Text("Position hinzufügen")
                        .foregroundColor(accentColor)
                }
            }
            
            // Anzeige der hinzugefügten Positionen
            if !profile.gesuchtePositionen.isEmpty {
                ForEach(profile.gesuchtePositionen.indices, id: \.self) { index in
                    let criteria = profile.gesuchtePositionen[index]
                    VStack(alignment: .leading) {
                        Text(criteria.position)
                            .font(.headline)
                            .foregroundColor(textColor)
                        if let alterMin = criteria.alterMin { Text("Alter Min: \(alterMin)").foregroundColor(secondaryTextColor) }
                        if let alterMax = criteria.alterMax { Text("Alter Max: \(alterMax)").foregroundColor(secondaryTextColor) }
                        if let groesseMin = criteria.groesseMin { Text("Größe Min: \(groesseMin) cm").foregroundColor(secondaryTextColor) }
                        if let tempoMin = criteria.tempoMin { Text("Tempo Min: \(tempoMin)").foregroundColor(secondaryTextColor) }
                        if let weitere = criteria.weitereKriterien { Text("Weitere: \(weitere)").foregroundColor(secondaryTextColor) }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .listRowBackground(cardBackgroundColor)
        .onAppear {
            updateFilteredFunktionäre()
        }
    }
    
    private func updateFilteredFunktionäre() {
        let selectedClubID = profile.vereinID
        if !selectedClubID.isEmpty {
            filteredFunktionäre = funktionäre.filter {
                $0.vereinID == selectedClubID && ($0.abteilung == profile.abteilung || $0.abteilung == nil)
            }
        } else {
            filteredFunktionäre = funktionäre
        }
    }
}

#Preview {
    AddProcessView(onSave: {})
}
