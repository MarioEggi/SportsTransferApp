import SwiftUI
import FirebaseFirestore

struct ClientListView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var viewModel: ClientViewModel // Verwende das EnvironmentObject
    @Environment(\.colorScheme) var colorScheme
    @State private var showingAddClientSheet = false
    @State private var showingFilterSheet = false
    @State private var newClient = Client(
        typ: "Spieler",
        name: "",
        vorname: "",
        geschlecht: "männlich"
    )
    @State private var clubs: [Club] = []
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                List {
                    ForEach(viewModel.filteredClients) { client in
                        NavigationLink(destination: ClientView(client: .constant(client))) {
                            clientRow(for: client)
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                Task {
                                    await viewModel.deleteClient(client)
                                }
                            } label: {
                                Label("Löschen", systemImage: "trash")
                            }
                        }
                    }
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    }
                }
                .background(colorScheme == .dark ? Color.black : Color(.systemBackground))
            }
            .navigationTitle("Klienten verwalten")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 15) {
                        Button(action: { showingFilterSheet = true }) {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .foregroundColor(.blue)
                        }
                        Button(action: { showingAddClientSheet = true }) {
                            Image(systemName: "plus")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddClientSheet) {
                AddClientView(
                    client: $newClient,
                    isEditing: false,
                    onSave: { updatedClient in
                        Task {
                            await viewModel.saveClient(updatedClient)
                            await MainActor.run {
                                resetNewClient()
                                showingAddClientSheet = false
                            }
                        }
                    },
                    onCancel: {
                        resetNewClient()
                        showingAddClientSheet = false
                    }
                )
                .transition(.move(edge: .bottom))
            }
            .sheet(isPresented: $showingFilterSheet) {
                FilterSheet(viewModel: viewModel, clubs: clubs)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
            .alert(isPresented: .constant(!errorMessage.isEmpty)) {
                Alert(
                    title: Text("Fehler"),
                    message: Text(errorMessage),
                    dismissButton: .default(Text("OK")) {
                        errorMessage = ""
                    }
                )
            }
            .task {
                await loadClubs()
            }
        }
    }

    @ViewBuilder
    private func clientRow(for client: Client) -> some View {
        HStack(spacing: 10) {
            clubLogoView(for: client)
            clientProfileView(for: client)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(client.vorname) \(client.name)")
                    .font(.headline)
                    .scaleEffect(0.7)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                if let geburtsdatum = client.geburtsdatum {
                    Text(dateFormatter.string(from: geburtsdatum))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                if let liga = client.liga {
                    Text(liga)
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

    @ViewBuilder
    private func clubLogoView(for client: Client) -> some View {
        if let vereinID = client.vereinID,
           let club = clubs.first(where: { $0.name == vereinID }),
           let logoURL = club.sharedInfo?.logoURL,
           let url = URL(string: logoURL) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .clipShape(Circle())
                case .failure, .empty:
                    Image(systemName: "building.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundColor(.gray)
                        .clipShape(Circle())
                @unknown default:
                    Image(systemName: "building.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundColor(.gray)
                        .clipShape(Circle())
                }
            }
        } else {
            Image(systemName: "building.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .foregroundColor(.gray)
                .clipShape(Circle())
        }
    }

    @ViewBuilder
    private func clientProfileView(for client: Client) -> some View {
        if let profilbildURL = client.profilbildURL,
           let url = URL(string: profilbildURL) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                case .failure, .empty:
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
    }

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    private func loadClubs() async {
        do {
            let (loadedClubs, _) = try await FirestoreManager.shared.getClubs(limit: 1000)
            await MainActor.run {
                clubs = loadedClubs
            }
        } catch {
            errorMessage = "Fehler beim Laden der Vereine: \(error.localizedDescription)"
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
}

struct FilterSheet: View {
    @ObservedObject var viewModel: ClientViewModel
    let clubs: [Club]
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Filter").font(.headline)) {
                    Picker("Verein", selection: $viewModel.filterClub) {
                        Text("Alle").tag(String?.none)
                        ForEach(clubs.map { $0.name }.sorted(), id: \.self) { club in
                            Text(club).tag(String?.some(club))
                        }
                    }
                    Picker("Geschlecht", selection: $viewModel.filterGender) {
                        Text("Alle").tag(String?.none)
                        Text("Männlich").tag(String?.some("männlich"))
                        Text("Weiblich").tag(String?.some("weiblich"))
                    }
                    Picker("Typ", selection: $viewModel.filterType) {
                        Text("Alle").tag(String?.none)
                        Text("Spieler").tag(String?.some("Spieler"))
                        Text("Spielerin").tag(String?.some("Spielerin"))
                        Text("Trainer").tag(String?.some("Trainer"))
                        Text("Co-Trainer").tag(String?.some("Co-Trainer"))
                    }
                }
                Section(header: Text("Sortierung").font(.headline)) {
                    Picker("Sortieren nach", selection: $viewModel.sortOption) {
                        ForEach(Constants.SortOption.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                }
            }
            .navigationTitle("Filter")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") {
                        viewModel.applyFiltersAndSorting()
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ClientListView()
        .environmentObject(AuthManager())
        .environmentObject(ClientViewModel())
}
