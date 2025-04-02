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

    // Farben für das dunkle Design
    private let backgroundColor = Color(hex: "#1C2526")
    private let cardBackgroundColor = Color(hex: "#2A3439")
    private let accentColor = Color(hex: "#00C4B4")
    private let textColor = Color(hex: "#E0E0E0")
    private let secondaryTextColor = Color(hex: "#B0BEC5")

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundColor.edgesIgnoringSafeArea(.all)
                VStack(spacing: 0) {
                    HStack {
                        Text("Kontakte")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(textColor)
                        Spacer()
                        HStack(spacing: 15) {
                            Button(action: { showingAddClientSheet = true }) {
                                Image(systemName: "person.badge.plus")
                                    .foregroundColor(accentColor)
                            }
                            Button(action: { showingAddFunktionärSheet = true }) {
                                Image(systemName: "person.2.badge.gearshape")
                                    .foregroundColor(accentColor)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)

                    filterPicker
                    groupByPicker

                    List {
                        if groupedContacts.isEmpty && filteredContacts.isEmpty {
                            Text("Keine Kontakte vorhanden.")
                                .foregroundColor(secondaryTextColor)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .listRowBackground(backgroundColor)
                        } else if groupBy == .none {
                            ForEach(filteredContacts) { contact in
                                contactRow(for: contact)
                                    .listRowBackground(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(cardBackgroundColor)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(accentColor.opacity(0.3), lineWidth: 1)
                                            )
                                            .padding(.vertical, 2)
                                    )
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets(top: 3, leading: 13, bottom: 3, trailing: 13))
                            }
                        } else {
                            ForEach(groupedContacts.keys.sorted(), id: \.self) { key in
                                Section(header: Text(key).font(.headline).foregroundColor(textColor)) {
                                    ForEach(groupedContacts[key] ?? []) { contact in
                                        contactRow(for: contact)
                                            .listRowBackground(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .fill(cardBackgroundColor)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 10)
                                                            .stroke(accentColor.opacity(0.3), lineWidth: 1)
                                                    )
                                                    .padding(.vertical, 2)
                                            )
                                            .listRowSeparator(.hidden)
                                            .listRowInsets(EdgeInsets(top: 3, leading: 13, bottom: 3, trailing: 13))
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                    .scrollContentBackground(.hidden)
                    .background(backgroundColor)
                    .padding(.horizontal)
                }
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
                        title: Text("Fehler").foregroundColor(textColor),
                        message: Text(errorMessage).foregroundColor(secondaryTextColor),
                        dismissButton: .default(Text("OK").foregroundColor(accentColor)) {
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
            }
        }
    }

    private var filterPicker: some View {
        Picker("Filter", selection: $filterType) {
            ForEach(Constants.ContactFilterType.allCases, id: \.self) { type in
                Text(type.rawValue).tag(type)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .foregroundColor(textColor)
        .padding(.horizontal)
    }

    private var groupByPicker: some View {
        Picker("Gruppieren nach", selection: $groupBy) {
            ForEach(Constants.GroupByOption.allCases, id: \.self) { option in
                Text(option.rawValue).tag(option)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .foregroundColor(textColor)
        .padding(.horizontal)
        .padding(.bottom, 10)
    }

    private func contactRow(for contact: Contact) -> some View {
        Group {  // Verwende Group, um die Typen zu vereinheitlichen
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
                                        .tint(accentColor)
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 40, height: 40)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(accentColor.opacity(0.3), lineWidth: 1))
                                case .failure:
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 40, height: 40)
                                        .foregroundColor(secondaryTextColor)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(accentColor.opacity(0.3), lineWidth: 1))
                                @unknown default:
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 40, height: 40)
                                        .foregroundColor(secondaryTextColor)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(accentColor.opacity(0.3), lineWidth: 1))
                                }
                            }
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 40, height: 40)
                                .foregroundColor(secondaryTextColor)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(accentColor.opacity(0.3), lineWidth: 1))
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(client.vorname) \(client.name)")
                                .font(.headline)
                                .foregroundColor(textColor)
                            if let vereinID = client.vereinID {
                                Text(vereinID)
                                    .font(.caption)
                                    .foregroundColor(secondaryTextColor)
                            }
                            if let abteilung = client.abteilung {
                                Text(abteilung)
                                    .font(.caption)
                                    .foregroundColor(secondaryTextColor)
                            }
                        }
                        Spacer()
                        Text(client.typ == "Spieler" ? "♂" : "♀")
                            .font(.system(size: 14))
                            .foregroundColor(client.typ == "Spieler" ? .blue : .pink)
                    }
                    .padding(.vertical, 8)
                }
            case .funktionär(let funktionär):
                NavigationLink(destination: FunktionärView(funktionär: .constant(funktionär))) {
                    HStack(spacing: 10) {
                        if let profilbildURL = funktionär.profilbildURL, let url = URL(string: profilbildURL) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                        .frame(width: 40, height: 40)
                                        .tint(accentColor)
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 40, height: 40)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(accentColor.opacity(0.3), lineWidth: 1))
                                case .failure:
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 40, height: 40)
                                        .foregroundColor(secondaryTextColor)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(accentColor.opacity(0.3), lineWidth: 1))
                                @unknown default:
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 40, height: 40)
                                        .foregroundColor(secondaryTextColor)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(accentColor.opacity(0.3), lineWidth: 1))
                                }
                            }
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 40, height: 40)
                                .foregroundColor(secondaryTextColor)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(accentColor.opacity(0.3), lineWidth: 1))
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(funktionär.vorname) \(funktionär.name)")
                                .font(.headline)
                                .foregroundColor(textColor)
                            if let position = funktionär.positionImVerein {
                                Text(position)
                                    .font(.caption)
                                    .foregroundColor(secondaryTextColor)
                            }
                            if let vereinID = funktionär.vereinID {
                                Text(vereinID)
                                    .font(.caption)
                                    .foregroundColor(secondaryTextColor)
                            }
                            if let abteilung = funktionär.abteilung {
                                Text(abteilung)
                                    .font(.caption)
                                    .foregroundColor(secondaryTextColor)
                            }
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
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
