import SwiftUI
import FirebaseFirestore

struct FunktionärListView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var viewModel: FunktionärViewModel // Verwende das neue ViewModel
    @Environment(\.colorScheme) var colorScheme
    @State private var showingAddFunktionärSheet = false
    @State private var showingEditFunktionärSheet = false
    @State private var newFunktionär = Funktionär(
        name: "",
        vorname: ""
    )
    @State private var selectedFunktionär: Funktionär?
    @State private var clubs: [Club] = []

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if viewModel.funktionäre.isEmpty {
                    Text("Keine Funktionäre vorhanden.")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    List {
                        ForEach(viewModel.funktionäre) { funktionär in
                            NavigationLink(destination: FunktionärView(funktionär: .constant(funktionär))) {
                                funktionärRow(for: funktionär)
                            }
                            .swipeActions {
                                Button(role: .destructive) {
                                    Task {
                                        await viewModel.deleteFunktionär(funktionär)
                                    }
                                } label: {
                                    Label("Löschen", systemImage: "trash")
                                }
                                Button(action: {
                                    selectedFunktionär = funktionär
                                    showingEditFunktionärSheet = true
                                }) {
                                    Label("Bearbeiten", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                        }
                        if viewModel.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .background(colorScheme == .dark ? Color.black : Color(.systemBackground))
                }
            }
            .navigationTitle("Funktionäre verwalten")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddFunktionärSheet = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showingAddFunktionärSheet) {
                AddFunktionärView(
                    funktionär: $newFunktionär,
                    onSave: { updatedFunktionär in
                        Task {
                            await viewModel.saveFunktionär(updatedFunktionär)
                            await MainActor.run {
                                resetNewFunktionär()
                                showingAddFunktionärSheet = false
                            }
                        }
                    },
                    onCancel: {
                        resetNewFunktionär()
                        showingAddFunktionärSheet = false
                    }
                )
            }
            .sheet(isPresented: $showingEditFunktionärSheet) {
                if let selectedFunktionär = selectedFunktionär {
                    EditFunktionärView(
                        funktionär: Binding(
                            get: { selectedFunktionär },
                            set: { self.selectedFunktionär = $0 }
                        ),
                        onSave: { updatedFunktionär in
                            Task {
                                await viewModel.saveFunktionär(updatedFunktionär)
                                await MainActor.run {
                                    showingEditFunktionärSheet = false
                                    self.selectedFunktionär = nil
                                }
                            }
                        },
                        onCancel: {
                            showingEditFunktionärSheet = false
                            self.selectedFunktionär = nil
                        }
                    )
                }
            }
            .alert(isPresented: $viewModel.isShowingError) {
                Alert(
                    title: Text("Fehler"),
                    message: Text(viewModel.errorMessage),
                    dismissButton: .default(Text("OK")) {
                        viewModel.resetError()
                    }
                )
            }
            .task {
                await loadClubs()
            }
        }
    }

    @ViewBuilder
    private func funktionärRow(for funktionär: Funktionär) -> some View {
        HStack(spacing: 10) {
            if let profilbildURL = funktionär.profilbildURL, let url = URL(string: profilbildURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: 40, height: 40)
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
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                if let position = funktionär.positionImVerein {
                    Text(position)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                if let vereinID = funktionär.vereinID,
                   let club = clubs.first(where: { $0.id == vereinID }) {
                    HStack(spacing: 5) {
                        if let logoURL = club.sharedInfo?.logoURL, let url = URL(string: logoURL) {
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
                        Text(club.name)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
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

    private func resetNewFunktionär() {
        newFunktionär = Funktionär(
            name: "",
            vorname: ""
        )
    }

    private func loadClubs() async {
        do {
            let (loadedClubs, _) = try await FirestoreManager.shared.getClubs(limit: 1000)
            await MainActor.run {
                clubs = loadedClubs
            }
        } catch {
            await MainActor.run {
                viewModel.addErrorToQueue("Fehler beim Laden der Vereine: \(error.localizedDescription)")
            }
        }
    }
}

#Preview {
    FunktionärListView()
        .environmentObject(AuthManager())
        .environmentObject(FunktionärViewModel())
}
