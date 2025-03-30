import SwiftUI
import FirebaseFirestore

struct ClubListView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var clubs: [Club] = []
    @State private var showingAddClubSheet = false
    @State private var newClub: Club = Club(id: nil, name: "", mensDepartment: nil, womensDepartment: nil, sharedInfo: nil)
    @State private var errorMessage = ""
    @State private var listener: ListenerRegistration?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if clubs.isEmpty {
                    Text("Keine Vereine vorhanden.")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    List {
                        ForEach(clubs) { club in
                            NavigationLink(destination: ClubView(clubID: club.id ?? "")) {
                                clubRow(for: club)
                            }
                            .swipeActions {
                                Button(role: .destructive) {
                                    Task {
                                        await deleteClub(club)
                                    }
                                } label: {
                                    Label("Löschen", systemImage: "trash")
                                        .foregroundColor(.white)
                                }
                            }
                            .listRowBackground(Color.gray.opacity(0.2))
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .background(Color.black)
                }
            }
            .navigationTitle("Vereine verwalten")
            .foregroundColor(.white)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddClubSheet = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(.white)
                    }
                }
            }
            .sheet(isPresented: $showingAddClubSheet) {
                AddClubView(
                    club: $newClub,
                    onSave: { updatedClub in
                        Task {
                            do {
                                if updatedClub.id != nil {
                                    try await FirestoreManager.shared.updateClub(club: updatedClub)
                                } else {
                                    try await FirestoreManager.shared.createClub(club: updatedClub)
                                }
                                await MainActor.run {
                                    resetNewClub()
                                    showingAddClubSheet = false
                                }
                            } catch {
                                errorMessage = "Fehler beim Speichern: \(error.localizedDescription)"
                            }
                        }
                    },
                    onCancel: {
                        resetNewClub()
                        showingAddClubSheet = false
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
                await loadClubsOnce()
                await setupRealtimeListener()
            }
            .onDisappear {
                listener?.remove()
            }
            .background(Color.black)
        }
    }

    @ViewBuilder
    private func clubRow(for club: Club) -> some View {
        HStack(spacing: 10) {
            if let logoURL = club.sharedInfo?.logoURL, let url = URL(string: logoURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: 40, height: 40)
                            .tint(.white)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                    case .failure:
                        Image(systemName: "building.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                            .foregroundColor(.gray)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                    @unknown default:
                        Image(systemName: "building.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                            .foregroundColor(.gray)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                    }
                }
            } else {
                Image(systemName: "building.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.gray)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.gray, lineWidth: 1))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(club.name)
                    .font(.headline)
                    .foregroundColor(.white)
                if let mensLeague = club.mensDepartment?.league {
                    Text("Männer: \(mensLeague)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                if let womensLeague = club.womensDepartment?.league {
                    Text("Frauen: \(womensLeague)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                if let memberCount = club.sharedInfo?.memberCount {
                    Text("Mitglieder: \(memberCount)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                if let founded = club.sharedInfo?.founded {
                    Text("Gegründet: \(founded)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 5)
    }

    private func resetNewClub() {
        newClub = Club(id: nil, name: "", mensDepartment: nil, womensDepartment: nil, sharedInfo: nil)
    }

    private func loadClubsOnce() async {
        do {
            let (loadedClubs, _) = try await FirestoreManager.shared.getClubs(limit: 1000)
            print("Einmalige Abfrage - Geladene Vereine: \(loadedClubs.count), IDs: \(loadedClubs.map { $0.id ?? "unbekannt" })")
            await MainActor.run {
                self.clubs = loadedClubs
            }
        } catch {
            errorMessage = "Fehler beim einmaligen Laden der Vereine: \(error.localizedDescription)"
            print("Fehler beim einmaligen Laden der Vereine: \(error.localizedDescription)")
        }
    }

    private func setupRealtimeListener() async {
        let newListener = Firestore.firestore().collection("clubs")
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    self.errorMessage = "Fehler beim Listener (Vereine): \(error.localizedDescription)"
                    print("Fehler beim Listener (Vereine): \(error.localizedDescription)")
                    return
                }
                guard let documents = snapshot?.documents else {
                    print("Keine Dokumente in der Sammlung 'clubs' gefunden (Realtime).")
                    return
                }
                let updatedClubs = documents.compactMap { doc -> Club? in
                    do {
                        let club = try doc.data(as: Club.self)
                        return club
                    } catch {
                        print("Fehler beim Dekodieren des Vereins \(doc.documentID): \(error.localizedDescription)")
                        return nil
                    }
                }
                print("Geladene Vereine (Realtime): \(updatedClubs.count), IDs: \(updatedClubs.map { $0.id ?? "unbekannt" })")
                DispatchQueue.main.async {
                    self.clubs = updatedClubs
                }
            }
        await MainActor.run {
            self.listener = newListener
        }
    }

    private func deleteClub(_ club: Club) async {
        guard let id = club.id else {
            errorMessage = "Keine Vereins-ID vorhanden"
            return
        }
        do {
            try await FirestoreManager.shared.deleteClub(clubID: id)
        } catch {
            errorMessage = "Fehler beim Löschen: \(error.localizedDescription)"
        }
    }
}

#Preview {
    ClubListView()
        .environmentObject(AuthManager())
}
