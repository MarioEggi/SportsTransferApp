import SwiftUI
import FirebaseFirestore

struct ClientListView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var clients: [Client] = []
    @State private var errorMessage: String = ""
    @State private var showingAddClientSheet = false
    @State private var newClient = Client(
        id: nil,
        typ: "Spieler",
        name: "",
        vorname: "",
        geschlecht: "männlich",
        vereinID: nil,
        nationalitaet: [],
        geburtsdatum: nil,
        liga: nil,
        profilbildURL: nil
    )
    @State private var clubs: [Club] = [] // Für Vereinslogos
    @State private var imageCache: [String: UIImage] = [:] // Cache für Vereinslogos

    var body: some View {
        NavigationStack {
            List {
                ForEach(clients.indices, id: \.self) { index in
                    NavigationLink(destination: ClientView(client: $clients[index])) {
                        HStack(spacing: 10) {
                            // Vereinslogo
                            clubLogoView(for: clients[index])

                            // Profilbild und Name
                            clientProfileView(for: clients[index])

                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(clients[index].vorname) \(clients[index].name)")
                                    .font(.headline)
                                    .scaleEffect(0.7)
                                if let geburtsdatum = clients[index].geburtsdatum {
                                    Text(dateFormatter.string(from: geburtsdatum))
                                        .font(.caption)
                                }
                                if let liga = clients[index].liga {
                                    Text(liga)
                                        .font(.caption)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            Text(clients[index].typ == "Spieler" ? "♂" : "♀")
                                .font(.system(size: 14))
                                .foregroundColor(clients[index].typ == "Spieler" ? .blue : .pink)
                        }
                        .padding(.vertical, 5)
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            Task {
                                await deleteClient(clients[index])
                            }
                        } label: {
                            Label("Löschen", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle("Klienten verwalten")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddClientSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddClientSheet) {
                AddClientView(
                    client: $newClient,
                    isEditing: false,
                    onSave: { updatedClient in
                        Task {
                            do {
                                try await FirestoreManager.shared.createClient(client: updatedClient)
                                await loadClients()
                                await MainActor.run {
                                    resetNewClient()
                                }
                            } catch {
                                await MainActor.run {
                                    errorMessage = "Fehler beim Speichern: \(error.localizedDescription)"
                                }
                            }
                            await MainActor.run {
                                showingAddClientSheet = false
                            }
                        }
                    },
                    onCancel: {
                        resetNewClient()
                        showingAddClientSheet = false
                    }
                )
            }
            .alert(isPresented: .constant(!errorMessage.isEmpty)) {
                Alert(title: Text("Fehler"), message: Text(errorMessage), dismissButton: .default(Text("OK")) {
                    errorMessage = ""
                })
            }
            .task {
                await loadClients()
                await loadClubs()
            }
        }
    }

    // Hilfsfunktionen für die Ansicht
    @ViewBuilder
    private func clubLogoView(for client: Client) -> some View {
        if let vereinID = client.vereinID,
           let club = clubs.first(where: { $0.name == vereinID }),
           let logoURL = club.logoURL,
           let cachedImage = imageCache[logoURL] {
            Image(uiImage: cachedImage)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .clipShape(Circle())
        } else {
            Image(systemName: "building.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .foregroundColor(.gray)
                .clipShape(Circle())
                .task {
                    await loadClubLogo(for: client.vereinID)
                }
        }
    }

    @ViewBuilder
    private func clientProfileView(for client: Client) -> some View {
        if let profilbildURL = client.profilbildURL,
           let cachedImage = imageCache[profilbildURL] {
            Image(uiImage: cachedImage)
                .resizable()
                .scaledToFill()
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.gray, lineWidth: 1))
        } else {
            Image(systemName: "person.circle.fill")
                .resizable()
                .scaledToFill()
                .frame(width: 40, height: 40)
                .foregroundColor(.gray)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                .task {
                    await loadImage(for: client)
                }
        }
    }

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    private func loadClients() async {
        do {
            let loadedClients = try await FirestoreManager.shared.getClients()
            await MainActor.run {
                clients = loadedClients
                for client in loadedClients {
                    if let profilbildURL = client.profilbildURL {
                        Task { await loadImage(for: client) }
                    }
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = "Fehler beim Laden der Klienten: \(error.localizedDescription)"
            }
        }
    }

    private func loadClubs() async {
        do {
            let loadedClubs = try await FirestoreManager.shared.getClubs()
            await MainActor.run {
                clubs = loadedClubs
                for club in loadedClubs {
                    if let logoURL = club.logoURL {
                        Task { await loadClubLogo(for: club.name) }
                    }
                }
            }
        } catch {
            print("Fehler beim Laden der Vereine: \(error.localizedDescription)")
        }
    }

    private func deleteClient(_ client: Client) async {
        guard let id = client.id else { return }
        do {
            try await FirestoreManager.shared.deleteClient(clientID: id)
            await loadClients()
        } catch {
            await MainActor.run {
                errorMessage = "Fehler beim Löschen des Klienten: \(error.localizedDescription)"
            }
        }
    }

    private func loadImage(for client: Client) async {
        if let profilbildURL = client.profilbildURL, let url = URL(string: profilbildURL) {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let image = UIImage(data: data) {
                    await MainActor.run {
                        self.imageCache[profilbildURL] = image
                    }
                }
            } catch {
                print("Fehler beim Laden des Bildes: \(error.localizedDescription)")
            }
        }
    }

    private func loadClubLogo(for vereinID: String?) async {
        guard let vereinID = vereinID,
              let club = clubs.first(where: { $0.name == vereinID }),
              let logoURL = club.logoURL,
              let url = URL(string: logoURL) else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let image = UIImage(data: data) {
                await MainActor.run {
                    self.imageCache[logoURL] = image
                }
            }
        } catch {
            print("Fehler beim Laden des Vereinslogos: \(error.localizedDescription)")
        }
    }

    private func resetNewClient() {
        newClient = Client(
            id: nil,
            typ: "Spieler",
            name: "",
            vorname: "",
            geschlecht: "männlich",
            vereinID: nil,
            nationalitaet: [],
            geburtsdatum: nil,
            liga: nil,
            profilbildURL: nil
        )
    }
}

#Preview {
    ClientListView()
        .environmentObject(AuthManager())
}
