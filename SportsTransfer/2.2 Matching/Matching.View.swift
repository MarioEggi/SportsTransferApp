import SwiftUI
import FirebaseFirestore

struct MatchingView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var matches: [Matching] = []
    @State private var clients: [String: Client] = [:]
    @State private var clubs: [String: Club] = [:]
    @State private var errorMessage = ""
    @State private var showingFeedbackSheet = false
    @State private var selectedMatch: Matching?
    @State private var rejectionReason = ""

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
                        Text("Matching")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(textColor)
                        Spacer()
                        Button(action: {
                            Task { await generateMatches() }
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(accentColor)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)

                    List {
                        if matches.isEmpty {
                            Text("Keine Matches gefunden.")
                                .foregroundColor(secondaryTextColor)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .listRowBackground(backgroundColor)
                        } else {
                            ForEach(matches) { match in
                                HStack {
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text("\(clients[match.clientID]?.vorname ?? "Unbekannt") \(clients[match.clientID]?.name ?? "")")
                                            .font(.headline)
                                            .foregroundColor(textColor)
                                        Text("Verein: \(clubs[match.vereinID]?.name ?? "Unbekannt")")
                                            .font(.subheadline)
                                            .foregroundColor(secondaryTextColor)
                                        Text("Match-Score: \(String(format: "%.1f", match.matchScore))%")
                                            .font(.caption)
                                            .foregroundColor(match.matchScore > 75 ? .green : .yellow)
                                        Text("Status: \(match.status)")
                                            .font(.caption)
                                            .foregroundColor(match.status == "accepted" ? .green : match.status == "rejected" ? .red : .gray)
                                    }
                                    Spacer()
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .swipeActions {
                                    Button(action: { Task { await acceptMatch(match) } }) {
                                        Label("Akzeptieren", systemImage: "checkmark")
                                    }
                                    .tint(.green)
                                    Button(action: {
                                        selectedMatch = match
                                        showingFeedbackSheet = true
                                    }) {
                                        Label("Ablehnen", systemImage: "xmark")
                                    }
                                    .tint(.red)
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
                .sheet(isPresented: $showingFeedbackSheet) {
                    feedbackSheet
                }
                .task {
                    await loadMatches()
                    await loadClientsAndClubs()
                }
                .alert(isPresented: Binding(get: { !errorMessage.isEmpty }, set: { if !$0 { errorMessage = "" } })) {
                    Alert(
                        title: Text("Fehler").foregroundColor(textColor),
                        message: Text(errorMessage).foregroundColor(secondaryTextColor),
                        dismissButton: .default(Text("OK").foregroundColor(accentColor))
                    )
                }
            }
        }
    }

    private var feedbackSheet: some View {
        NavigationView {
            ZStack {
                backgroundColor.edgesIgnoringSafeArea(.all)
                Form {
                    Section(header: Text("Grund für Ablehnung").foregroundColor(textColor)) {
                        TextField("Grund eingeben...", text: $rejectionReason)
                            .foregroundColor(textColor)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                    }
                }
                .scrollContentBackground(.hidden)
                .background(backgroundColor)
                .foregroundColor(textColor)
                .navigationTitle("Match ablehnen")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Abbrechen") {
                            rejectionReason = ""
                            showingFeedbackSheet = false
                        }
                        .foregroundColor(accentColor)
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Ablehnen") {
                            Task { await rejectMatch(selectedMatch!) }
                            rejectionReason = ""
                            showingFeedbackSheet = false
                        }
                        .foregroundColor(accentColor)
                    }
                }
            }
        }
    }

    private func loadMatches() async {
        do {
            let snapshot = try await Firestore.firestore().collection("matches")
                .whereField("status", isEqualTo: "pending")
                .getDocuments()
            let loadedMatches = snapshot.documents.compactMap { try? $0.data(as: Matching.self) }
            await MainActor.run { matches = loadedMatches }
        } catch {
            errorMessage = "Fehler beim Laden der Matches: \(error.localizedDescription)"
        }
    }

    private func loadClientsAndClubs() async {
        do {
            let (loadedClients, _) = try await FirestoreManager.shared.getClients(lastDocument: nil, limit: 1000)
            let (loadedClubs, _) = try await FirestoreManager.shared.getClubs(lastDocument: nil, limit: 1000)
            await MainActor.run {
                clients = Dictionary(uniqueKeysWithValues: loadedClients.compactMap { client in
                    guard let id = client.id else { return nil }
                    return (id, client)
                })
                clubs = Dictionary(uniqueKeysWithValues: loadedClubs.compactMap { club in
                    guard let id = club.id else { return nil }
                    return (id, club)
                })
            }
        } catch {
            errorMessage = "Fehler beim Laden der Klienten/Vereine: \(error.localizedDescription)"
        }
    }

    private func generateMatches() async {
        do {
            let newMatches = try await FirestoreManager.shared.generateMatches()
            await MainActor.run { matches = newMatches }
        } catch {
            errorMessage = "Fehler beim Generieren der Matches: \(error.localizedDescription)"
        }
    }

    private func acceptMatch(_ match: Matching) async {
        do {
            let feedback = MatchFeedback(
                matchID: match.id,
                userID: authManager.userID ?? "unknown",
                status: "accepted",
                reason: nil,
                timestamp: Date()
            )
            try await FirestoreManager.shared.saveMatchFeedback(feedback: feedback)
            await loadMatches()
        } catch {
            errorMessage = "Fehler beim Akzeptieren des Matches: \(error.localizedDescription)"
        }
    }

    private func rejectMatch(_ match: Matching) async {
        do {
            let feedback = MatchFeedback(
                matchID: match.id,
                userID: authManager.userID ?? "unknown",
                status: "rejected",
                reason: rejectionReason,
                timestamp: Date()
            )
            try await FirestoreManager.shared.saveMatchFeedback(feedback: feedback)
            await loadMatches()
        } catch {
            errorMessage = "Fehler beim Ablehnen des Matches: \(error.localizedDescription)"
        }
    }
}

#Preview {
    MatchingView()
        .environmentObject(AuthManager())
}
