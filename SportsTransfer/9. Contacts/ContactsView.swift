import SwiftUI
import FirebaseFirestore

struct ContactsView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var clients: [Client] = []
    @State private var funktionäre: [Funktionär] = []
    @State private var filterType: Constants.ContactFilterType = .all
    @State private var groupBy: Constants.GroupByOption = .none
    @State private var showingAddClientSheet = false
    @State private var showingAddFunktionärSheet = false
    @State private var newClient = Client(
        typ: "Spieler",
        name: "",
        vorname: "",
        geschlecht: "männlich"
    )
    @State private var newFunktionär = Funktionär(
        name: "",
        vorname: ""
    )
    @State private var errorMessage = ""
    @State private var clientListener: ListenerRegistration?
    @State private var funktionärListener: ListenerRegistration?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                filterPicker
                groupByPicker
                contactsList
            }
            .navigationTitle("Kontakte")
            .foregroundColor(.white) // Weiße Schrift für den Titel
            .toolbar { toolbarContent }
            .sheet(isPresented: $showingAddClientSheet) {
                AddClientView()
                    .environmentObject(authManager)
            }
            .sheet(isPresented: $showingAddFunktionärSheet) {
                AddFunktionärView(
                    funktionär: $newFunktionär,
                    onSave: { updatedFunktionär in
                        Task {
                            do {
                                try await FirestoreManager.shared.createFunktionär(funktionär: updatedFunktionär)
                                await MainActor.run {
                                    resetNewFunktionär()
                                    showingAddFunktionärSheet = false
                                }
                            } catch {
                                errorMessage = "Fehler beim Speichern des Funktionärs: \(error.localizedDescription)"
                            }
                        }
                    },
                    onCancel: {
                        resetNewFunktionär()
                        showingAddFunktionärSheet = false
                    }
                )
            }
            .alert(isPresented: .constant(!errorMessage.isEmpty)) {
                Alert(
                    title: Text("Fehler").foregroundColor(.white),
                    message: Text(errorMessage).foregroundColor(.white),
                    dismissButton: .default(Text("OK").foregroundColor(.white)) {
                        errorMessage = ""
                    }
                )
            }
            .task {
                await setupRealtimeListeners()
            }
            .onDisappear {
                clientListener?.remove()
                funktionärListener?.remove()
            }
            .background(Color.black) // Schwarzer Hintergrund für die gesamte View
        }
    }

    private var filterPicker: some View {
        Picker("Filter", selection: $filterType) {
            ForEach(Constants.ContactFilterType.allCases, id: \.self) { type in
                Text(type.rawValue).tag(type)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .foregroundColor(.white) // Weiße Schrift
        .padding()
        .background(Color.black) // Schwarzer Hintergrund
    }

    private var groupByPicker: some View {
        Picker("Gruppieren nach", selection: $groupBy) {
            ForEach(Constants.GroupByOption.allCases, id: \.self) { option in
                Text(option.rawValue).tag(option)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .foregroundColor(.white) // Weiße Schrift
        .padding()
        .background(Color.black) // Schwarzer Hintergrund
    }

    private var contactsList: some View {
        Group {
            if groupedContacts.isEmpty {
                Text("Keine Kontakte vorhanden.")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                List {
                    if groupBy == .none {
                        ForEach(filteredContacts) { contact in
                            contactRow(for: contact)
                        }
                    } else {
                        ForEach(groupedContacts.keys.sorted(), id: \.self) { key in
                            Section(header: Text(key).font(.headline).foregroundColor(.white)) {
                                ForEach(groupedContacts[key] ?? []) { contact in
                                    contactRow(for: contact)
                                }
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden) // Standard-Hintergrund der Liste ausblenden
                .background(Color.black) // Schwarzer Hintergrund für die Liste
            }
        }
    }

    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            HStack {
                Button(action: { showingAddClientSheet = true }) {
                    Image(systemName: "person.badge.plus")
                        .foregroundColor(.white) // Weißes Symbol
                }
                Button(action: { showingAddFunktionärSheet = true }) {
                    Image(systemName: "person.2.badge.gearshape")
                        .foregroundColor(.white) // Weißes Symbol
                }
            }
        }
    }

    private var filteredContacts: [Contact] {
        switch filterType {
        case .all:
            return clients.map { Contact.client($0) } + funktionäre.map { Contact.funktionär($0) }
        case .clients:
            return clients.map { Contact.client($0) }
        case .funktionäre:
            return funktionäre.map { Contact.funktionär($0) }
        }
    }

    private var groupedContacts: [String: [Contact]] {
        var grouped: [String: [Contact]] = [:]
        let contacts = filteredContacts

        switch groupBy {
        case .none:
            return [:]
        case .club:
            for contact in contacts {
                let key = contact.club ?? "Ohne Verein"
                if grouped[key] == nil {
                    grouped[key] = []
                }
                grouped[key]?.append(contact)
            }
        case .type:
            for contact in contacts {
                let key: String
                switch contact {
                case .client(let client):
                    key = client.typ
                case .funktionär(let funktionär):
                    key = funktionär.positionImVerein ?? "Funktionär"
                }
                if grouped[key] == nil {
                    grouped[key] = []
                }
                grouped[key]?.append(contact)
            }
        }
        return grouped
    }

    @ViewBuilder
    private func contactRow(for contact: Contact) -> some View {
        switch contact {
        case .client(let client):
            NavigationLink(destination: ClientView(client: .constant(client))) {
                HStack(spacing: 10) {
                    if let profilbildURL = client.profilbildURL, let url = URL(string: profilbildURL) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(width: 40, height: 40)
                                    .tint(.white) // Weißer Ladeindikator
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 40, height: 40)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                            case .failure:
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 40, height: 40)
                                    .foregroundColor(.gray)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                            @unknown default:
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 40, height: 40)
                                    .foregroundColor(.gray)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                            }
                        }
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 40, height: 40)
                            .foregroundColor(.gray)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(client.vorname) \(client.name)")
                            .font(.headline)
                            .foregroundColor(.white) // Weiße Schrift
                        if let vereinID = client.vereinID {
                            Text(vereinID)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        if let abteilung = client.abteilung {
                            Text(abteilung)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Text(client.typ == "Spieler" ? "♂" : "♀")
                        .font(.system(size: 14))
                        .foregroundColor(client.typ == "Spieler" ? .blue : .pink)
                }
                .padding(.vertical, 5)
            }
            .listRowBackground(Color.gray.opacity(0.2)) // Dunklerer Hintergrund für Listenelemente
        case .funktionär(let funktionär):
            NavigationLink(destination: FunktionärView(funktionär: .constant(funktionär))) {
                HStack(spacing: 10) {
                    if let profilbildURL = funktionär.profilbildURL, let url = URL(string: profilbildURL) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(width: 40, height: 40)
                                    .tint(.white) // Weißer Ladeindikator
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 40, height: 40)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                            case .failure:
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 40, height: 40)
                                    .foregroundColor(.gray)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                            @unknown default:
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 40, height: 40)
                                    .foregroundColor(.gray)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                            }
                        }
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 40, height: 40)
                            .foregroundColor(.gray)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(funktionär.vorname) \(funktionär.name)")
                            .font(.headline)
                            .foregroundColor(.white) // Weiße Schrift
                        if let position = funktionär.positionImVerein {
                            Text(position)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        if let vereinID = funktionär.vereinID {
                            Text(vereinID)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        if let abteilung = funktionär.abteilung {
                            Text(abteilung)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.vertical, 5)
            }
            .listRowBackground(Color.gray.opacity(0.2)) // Dunklerer Hintergrund für Listenelemente
        }
    }

    private func resetNewClient() {
        newClient = Client(
            typ: "Spieler",
            name: "",
            vorname: "",
            geschlecht: "männlich"
        )
    }

    private func resetNewFunktionär() {
        newFunktionär = Funktionär(
            name: "",
            vorname: ""
        )
    }

    private func setupRealtimeListeners() async {
        let clientListener = Firestore.firestore().collection("clients")
            .order(by: "name")
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    self.errorMessage = "Fehler beim Laden der Klienten: \(error.localizedDescription)"
                    return
                }
                guard let documents = snapshot?.documents else { return }
                let updatedClients = documents.compactMap { try? $0.data(as: Client.self) }
                DispatchQueue.main.async {
                    self.clients = updatedClients
                }
            }

        let funktionärListener = Firestore.firestore().collection("funktionare")
            .order(by: "name")
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    self.errorMessage = "Fehler beim Laden der Funktionäre: \(error.localizedDescription)"
                    return
                }
                guard let documents = snapshot?.documents else { return }
                let updatedFunktionäre = documents.compactMap { try? $0.data(as: Funktionär.self) }
                DispatchQueue.main.async {
                    self.funktionäre = updatedFunktionäre
                }
            }

        await MainActor.run {
            self.clientListener = clientListener
            self.funktionärListener = funktionärListener
        }
    }
}

enum Contact: Identifiable {
    case client(Client)
    case funktionär(Funktionär)

    var id: String {
        switch self {
        case .client(let client):
            return client.id ?? UUID().uuidString
        case .funktionär(let funktionär):
            return funktionär.id ?? UUID().uuidString
        }
    }

    var club: String? {
        switch self {
        case .client(let client):
            return client.vereinID
        case .funktionär(let funktionär):
            return funktionär.vereinID
        }
    }
}

#Preview {
    ContactsView()
        .environmentObject(AuthManager())
}
