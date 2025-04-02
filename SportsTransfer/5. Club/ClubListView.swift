import SwiftUI
import FirebaseFirestore

struct ClubListView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var clubs: [Club] = []
    @State private var showingAddClubSheet = false
    @State private var newClub: Club = Club(id: nil, name: "", mensDepartment: nil, womensDepartment: nil, sharedInfo: nil)
    @State private var errorMessage = ""
    @State private var listener: ListenerRegistration?

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
                        Text("Vereine")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(textColor)
                        Spacer()
                        Button(action: { showingAddClubSheet = true }) {
                            Image(systemName: "plus")
                                .foregroundColor(accentColor)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)

                    List {
                        if clubs.isEmpty {
                            Text("Keine Vereine gefunden.")
                                .foregroundColor(secondaryTextColor)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .listRowBackground(backgroundColor)
                        } else {
                            ForEach(clubs) { club in
                                NavigationLink(destination: ClubView(clubID: club.id ?? "")) {
                                    clubRow(for: club)
                                }
                                .swipeActions {
                                    Button(role: .destructive) {
                                        Task { await deleteClub(club) }
                                    } label: {
                                        Label("Löschen", systemImage: "trash")
                                            .foregroundColor(.white)
                                    }
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
                    }
                    .listStyle(PlainListStyle())
                    .scrollContentBackground(.hidden)
                    .background(backgroundColor)
                    .padding(.horizontal)
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
                        title: Text("Fehler").foregroundColor(textColor),
                        message: Text(errorMessage).foregroundColor(secondaryTextColor),
                        dismissButton: .default(Text("OK").foregroundColor(accentColor)) {
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
            }
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
                            .tint(accentColor)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(accentColor.opacity(0.3), lineWidth: 1))
                    case .failure:
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

            VStack(alignment: .leading, spacing: 2) {
                Text(club.name)
                    .font(.headline)
                    .foregroundColor(textColor)
                if let mensLeague = club.mensDepartment?.league {
                    Text("Männer: \(mensLeague)")
                        .font(.caption)
                        .foregroundColor(secondaryTextColor)
                }
                if let womensLeague = club.womensDepartment?.league {
                    Text("Frauen: \(womensLeague)")
                        .font(.caption)
                        .foregroundColor(secondaryTextColor)
                }
                if let memberCount = club.sharedInfo?.memberCount {
                    Text("Mitglieder: \(memberCount)")
                        .font(.caption)
                        .foregroundColor(secondaryTextColor)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 8)
    }

    private func resetNewClub() {
        newClub = Club(id: nil, name: "", mensDepartment: nil, womensDepartment: nil, sharedInfo: nil)
    }

    private func loadClubsOnce() async {
        do {
            let (loadedClubs, _) = try await FirestoreManager.shared.getClubs(lastDocument: nil, limit: 1000)
            await MainActor.run {
                self.clubs = loadedClubs
            }
        } catch {
            errorMessage = "Fehler beim einmaligen Laden der Vereine: \(error.localizedDescription)"
        }
    }

    private func setupRealtimeListener() async {
        let newListener = Firestore.firestore().collection("clubs")
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    self.errorMessage = "Fehler beim Listener (Vereine): \(error.localizedDescription)"
                    return
                }
                guard let documents = snapshot?.documents else { return }
                let updatedClubs = documents.compactMap { try? $0.data(as: Club.self) }
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
