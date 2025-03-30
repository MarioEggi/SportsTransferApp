import SwiftUI
import FirebaseFirestore

struct ClientListView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var viewModel: ClientViewModel
    @State private var showingAddClientSheet = false
    @State private var showingFilterSheet = false
    @State private var showingEditClientSheet = false
    @State private var selectedClient: Client?
    @State private var newClient = Client(
        typ: "Spieler",
        name: "",
        vorname: "",
        geschlecht: "männlich"
    )
    @State private var clubs: [Club] = []
    @State private var errorMessage = ""
    @State private var rowOpacities: [String: CGFloat] = [:]

    init() {
        _viewModel = StateObject(wrappedValue: ClientViewModel(authManager: AuthManager()))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                clientList
            }
            .navigationTitle("Klienten verwalten")
            .foregroundColor(.white)
            .toolbar { toolbarContent }
            .sheet(isPresented: $showingAddClientSheet) {
                AddClientView()
                    .environmentObject(authManager)
            }
            .sheet(isPresented: $showingEditClientSheet) {
                if let selectedClient = selectedClient {
                    EditClientView(
                        client: Binding(
                            get: { selectedClient },
                            set: { newValue in
                                self.selectedClient = newValue
                                viewModel.updateClientLocally(newValue)
                            }
                        ),
                        onSave: { updatedClient in
                            viewModel.updateClientLocally(updatedClient)
                            showingEditClientSheet = false
                        },
                        onCancel: {
                            showingEditClientSheet = false
                        }
                    )
                }
            }
            .sheet(isPresented: $showingFilterSheet) {
                FilterSheet(viewModel: viewModel, clubs: clubs)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
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
                await loadClubs()
                await MainActor.run {
                    viewModel.applyFiltersAndSorting()
                }
            }
            .background(Color.black)
        }
        .environmentObject(viewModel)
    }

    private var clientList: some View {
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
                            .foregroundColor(.white)
                    }
                    Button(action: {
                        selectedClient = client
                        showingEditClientSheet = true
                    }) {
                        Label("Bearbeiten", systemImage: "pencil")
                            .foregroundColor(.white)
                    }
                    .tint(.blue)
                }
                .listRowBackground(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.black)
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                        .padding(.vertical, 0)
                )
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 3, leading: 13, bottom: 3, trailing: 13))
                .opacity(rowOpacities[client.id ?? ""] ?? 0)
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.5).delay(Double(viewModel.filteredClients.firstIndex(where: { $0.id == client.id }) ?? 0) * 0.1)) {
                        rowOpacities[client.id ?? ""] = 1.0
                    }
                }
            }
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .tint(.white)
                    .listRowBackground(Color.black)
                    .listRowInsets(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
            }
        }
        .listStyle(PlainListStyle())
        .scrollContentBackground(.hidden)
        .background(Color.black)
        .padding(.horizontal)
    }

    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            HStack(spacing: 15) {
                Button(action: { showingFilterSheet = true }) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .foregroundColor(.white)
                }
                Button(action: { showingAddClientSheet = true }) {
                    Image(systemName: "plus")
                        .foregroundColor(.white)
                }
            }
        }
    }

    @ViewBuilder
    private func clientRow(for client: Client) -> some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.white.opacity(0.5))
                .frame(height: 0.5)
                .padding(.bottom, 5)

            HStack(spacing: 12) {
                clubLogoView(for: client)
                clientProfileView(for: client)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(client.vorname) \(client.name)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    VStack(alignment: .leading, spacing: 1) {
                        if let geburtsdatum = client.geburtsdatum {
                            let age = Calendar.current.dateComponents([.year], from: geburtsdatum, to: Date()).year ?? 0
                            Text("\(dateFormatter.string(from: geburtsdatum)) (\(age))")
                                .font(.caption)
                                .foregroundColor(.white)
                        } else {
                            Text("Geburtsdatum unbekannt")
                                .font(.caption)
                                .foregroundColor(.gray.opacity(0.5))
                        }

                        if let liga = client.liga {
                            Text(liga)
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                    }
                }

                Spacer()

                Text(client.typ == "Spieler" ? "♂" : "♀")
                    .font(.system(size: 16))
                    .foregroundColor(client.typ == "Spieler" ? .blue : .pink)
            }
            .padding(.vertical, 0)
            .padding(.horizontal, 12)
        }
    }

    @ViewBuilder
    private func clubLogoView(for client: Client) -> some View {
        if let vereinID = client.vereinID,
           let club = clubs.first(where: { $0.id == vereinID }),
           let logoURL = club.sharedInfo?.logoURL,
           let url = URL(string: logoURL) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                case .failure, .empty:
                    Image(systemName: "building.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .foregroundColor(.gray)
                        .clipShape(Circle())
                @unknown default:
                    Image(systemName: "building.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .foregroundColor(.gray)
                        .clipShape(Circle())
                }
            }
        } else {
            Image(systemName: "building.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
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
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                case .failure, .empty:
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.gray)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                @unknown default:
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.gray)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                }
            }
        } else {
            Image(systemName: "person.circle.fill")
                .resizable()
                .scaledToFill()
                .frame(width: 60, height: 60)
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
            let (loadedClubs, _) = try await FirestoreManager.shared.getClubs(lastDocument: nil, limit: 1000)
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
                Section(header: Text("Filter").font(.headline).foregroundColor(.white)) {
                    Picker("Verein", selection: $viewModel.filterClub) {
                        Text("Alle").tag(String?.none)
                        ForEach(clubs.map { $0.name }.sorted(), id: \.self) { club in
                            Text(club).tag(String?.some(club))
                        }
                    }
                    .foregroundColor(.white)
                    .accentColor(.white)
                    Picker("Geschlecht", selection: $viewModel.filterGender) {
                        Text("Alle").tag(String?.none)
                        Text("Männlich").tag(String?.some("männlich"))
                        Text("Weiblich").tag(String?.some("weiblich"))
                    }
                    .foregroundColor(.white)
                    .accentColor(.white)
                    Picker("Typ", selection: $viewModel.filterType) {
                        Text("Alle").tag(String?.none)
                        Text("Spieler").tag(String?.some("Spieler"))
                        Text("Spielerin").tag(String?.some("Spielerin"))
                        Text("Trainer").tag(String?.some("Trainer"))
                        Text("Co-Trainer").tag(String?.some("Co-Trainer"))
                    }
                    .foregroundColor(.white)
                    .accentColor(.white)
                }
                Section(header: Text("Sortierung").font(.headline).foregroundColor(.white)) {
                    Picker("Sortieren nach", selection: $viewModel.sortOption) {
                        ForEach(Constants.SortOption.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .foregroundColor(.white)
                    .accentColor(.white)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.black)
            .navigationTitle("Filter")
            .foregroundColor(.white)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") {
                        viewModel.applyFiltersAndSorting()
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

#Preview {
    ClientListView()
        .environmentObject(AuthManager())
}
