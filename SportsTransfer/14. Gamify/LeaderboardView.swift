import SwiftUI
import FirebaseFirestore

struct LeaderboardView: View {
    @State private var users: [User] = []
    @State private var errorMessage = ""

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
                        Text("Rangliste")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(textColor)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)

                    List {
                        if users.isEmpty {
                            Text("Keine Mitarbeiter gefunden.")
                                .foregroundColor(secondaryTextColor)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .listRowBackground(backgroundColor)
                        } else {
                            ForEach(users.indices, id: \.self) { index in
                                let user = users[index]
                                HStack {
                                    Text("\(index + 1).")
                                        .font(.headline)
                                        .foregroundColor(index < 3 ? .yellow : textColor)
                                    Text(user.email)
                                        .foregroundColor(textColor)
                                    Spacer()
                                    Text("\(user.points ?? 0) Punkte")
                                        .foregroundColor(secondaryTextColor)
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
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
                .alert(isPresented: Binding(get: { !errorMessage.isEmpty }, set: { if !$0 { errorMessage = "" } })) {
                    Alert(
                        title: Text("Fehler").foregroundColor(textColor),
                        message: Text(errorMessage).foregroundColor(secondaryTextColor),
                        dismissButton: .default(Text("OK").foregroundColor(accentColor))
                    )
                }
                .task {
                    await loadUsers()
                }
            }
        }
    }

    private func loadUsers() async {
        do {
            let snapshot = try await Firestore.firestore().collection("users")
                .whereField("rolle", isEqualTo: "Mitarbeiter")
                .getDocuments()
            let loadedUsers = snapshot.documents.compactMap { doc -> User? in
                var user = try? doc.data(as: User.self)
                user?.id = doc.documentID
                return user
            }
            await MainActor.run {
                users = loadedUsers.sorted { ($0.points ?? 0) > ($1.points ?? 0) }
            }
        } catch {
            errorMessage = "Fehler beim Laden der Rangliste: \(error.localizedDescription)"
        }
    }
}

#Preview {
    LeaderboardView()
}
