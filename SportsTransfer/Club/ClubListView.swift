import SwiftUI

struct ClubListView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var clubs: [Club] = []
    @State private var errorMessage: String = ""

    var body: some View {
        NavigationStack {
            List {
                ForEach(clubs) { club in
                    NavigationLink(destination: ClubView(club: .constant(club))) {
                        Text(club.name)
                    }
                }
            }
            .navigationTitle("Vereine verwalten")
            .alert(isPresented: .constant(!errorMessage.isEmpty)) {
                Alert(title: Text("Fehler"), message: Text(errorMessage), dismissButton: .default(Text("OK")) {
                    errorMessage = ""
                })
            }
            .task {
                await loadClubs()
            }
        }
    }

    private func loadClubs() async {
        do {
            let loadedClubs = try await FirestoreManager.shared.getClubs()
            await MainActor.run {
                clubs = loadedClubs
            }
        } catch {
            await MainActor.run {
                errorMessage = "Fehler beim Laden der Vereine: \(error.localizedDescription)"
            }
        }
    }
}

#Preview {
    let club = Club(name: "Bayern München")
    return ClubListView()
        .environmentObject(AuthManager())
}
