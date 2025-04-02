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

    // Farben für das dunkle Design
    private let backgroundColor = Color(hex: "#1C2526")
    private let cardBackgroundColor = Color(hex: "#2A3439")
    private let accentColor = Color(hex: "#00C4B4")
    private let textColor = Color(hex: "#E0E0E0")
    private let secondaryTextColor = Color(hex: "#B0BEC5")

    init() {
        _viewModel = StateObject(wrappedValue: ClientViewModel(authManager: AuthManager()))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundColor.edgesIgnoringSafeArea(.all)
                VStack(spacing: 0) {
                    // Überschrift und Suchleiste
                    HStack {
                        Text("Klienten")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(textColor)
                        Spacer()
                        HStack(spacing: 15) {
                            Button(action: { showingFilterSheet = true }) {
                                Image(systemName: "line.3.horizontal.decrease.circle")
                                    .foregroundColor(accentColor)
                            }
                            Button(action: { showingAddClientSheet = true }) {
                                Image(systemName: "plus")
                                    .foregroundColor(accentColor)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)

                    // Suchleiste
                    TextField("Suche nach Name...", text: $viewModel.searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                        .foregroundColor(textColor)
                        .background(cardBackgroundColor)
                        .cornerRadius(8)
                        .onChange(of: viewModel.searchText) { _ in
                            viewModel.applyFiltersAndSorting()
                        }

                    clientList
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        EmptyView() // Entferne die NavigationBar-Überschrift, da wir eine eigene haben
                    }
                }
                .sheet(isPresented: $showingAddClientSheet) {
                    AddClientView(onSave: {
                        Task {
                            await viewModel.loadClients()
                        }
                    })
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
                        title: Text("Fehler").foregroundColor(textColor),
                        message: Text(errorMessage).foregroundColor(secondaryTextColor),
                        dismissButton: .default(Text("OK").foregroundColor(accentColor)) {
                            errorMessage = ""
                        }
                    )
                }
                .task {
                    await loadClubs()
                    await viewModel.loadClients()
                }
            }
        }
        .environmentObject(viewModel)
    }

    private var clientList: some View {
        List {
            if viewModel.filteredClients.isEmpty {
                Text("Keine Klienten gefunden.")
                    .foregroundColor(secondaryTextColor)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowBackground(backgroundColor)
            } else {
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
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .tint(accentColor)
                    .listRowBackground(backgroundColor)
                    .listRowInsets(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
            }
        }
        .listStyle(PlainListStyle())
        .scrollContentBackground(.hidden)
        .background(backgroundColor)
        .padding(.horizontal)
        .onAppear {
            print("Anzahl der gefilterten Klienten: \(viewModel.filteredClients.count)")
        }
    }

    @ViewBuilder
    private func clientRow(for client: Client) -> some View {
        HStack(spacing: 12) {
            clubLogoView(for: client)
            clientProfileView(for: client)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(client.vorname) \(client.name)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(textColor)

                VStack(alignment: .leading, spacing: 1) {
                    if let geburtsdatum = client.geburtsdatum {
                        let age = Calendar.current.dateComponents([.year], from: geburtsdatum, to: Date()).year ?? 0
                        Text("\(dateFormatter.string(from: geburtsdatum)) (\(age))")
                            .font(.caption)
                            .foregroundColor(secondaryTextColor)
                    } else {
                        Text("Geburtsdatum unbekannt")
                            .font(.caption)
                            .foregroundColor(secondaryTextColor)
                    }

                    if let liga = client.liga {
                        Text(liga)
                            .font(.caption)
                            .foregroundColor(secondaryTextColor)
                    }
                }
            }

            Spacer()

            Text(client.geschlecht == "männlich" ? "♂" : "♀")
                .font(.system(size: 16))
                .foregroundColor(client.geschlecht == "männlich" ? .blue : .pink)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
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
                        .overlay(Circle().stroke(accentColor.opacity(0.3), lineWidth: 1))
                case .failure, .empty:
                    Image(systemName: "building.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .foregroundColor(secondaryTextColor)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(accentColor.opacity(0.3), lineWidth: 1))
                @unknown default:
                    Image(systemName: "building.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .foregroundColor(secondaryTextColor)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(accentColor.opacity(0.3), lineWidth: 1))
                }
            }
        } else {
            Image(systemName: "building.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .foregroundColor(secondaryTextColor)
                .clipShape(Circle())
                .overlay(Circle().stroke(accentColor.opacity(0.3), lineWidth: 1))
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
                        .overlay(Circle().stroke(accentColor.opacity(0.3), lineWidth: 1))
                case .failure, .empty:
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
}

struct FilterSheet: View {
    @ObservedObject var viewModel: ClientViewModel
    let clubs: [Club]
    @Environment(\.dismiss) var dismiss

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
                Form {
                    Section(header: Text("Filter").font(.headline).foregroundColor(textColor)) {
                        Picker("Verein", selection: $viewModel.filterClub) {
                            Text("Alle").tag(String?.none)
                            ForEach(clubs.map { $0.name }.sorted(), id: \.self) { club in
                                Text(club).tag(String?.some(club))
                            }
                        }
                        .foregroundColor(textColor)
                        .accentColor(accentColor)
                        Picker("Geschlecht", selection: $viewModel.filterGender) {
                            Text("Alle").tag(String?.none)
                            Text("Männlich").tag(String?.some("männlich"))
                            Text("Weiblich").tag(String?.some("weiblich"))
                        }
                        .foregroundColor(textColor)
                        .accentColor(accentColor)
                        Picker("Typ", selection: $viewModel.filterType) {
                            Text("Alle").tag(String?.none)
                            Text("Spieler").tag(String?.some("Spieler"))
                            Text("Spielerin").tag(String?.some("Spielerin"))
                            Text("Trainer").tag(String?.some("Trainer"))
                            Text("Co-Trainer").tag(String?.some("Co-Trainer"))
                        }
                        .foregroundColor(textColor)
                        .accentColor(accentColor)
                    }
                    Section(header: Text("Sortierung").font(.headline).foregroundColor(textColor)) {
                        Picker("Sortieren nach", selection: $viewModel.sortOption) {
                            ForEach(SortOption.allCases, id: \.self) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                        .foregroundColor(textColor)
                        .accentColor(accentColor)
                    }
                }
                .scrollContentBackground(.hidden)
                .background(backgroundColor)
                .navigationTitle("Filter")
                .foregroundColor(textColor)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Fertig") {
                            viewModel.applyFiltersAndSorting()
                            dismiss()
                        }
                        .foregroundColor(accentColor)
                    }
                }
            }
        }
    }
}

#Preview {
    ClientListView()
        .environmentObject(AuthManager())
}
