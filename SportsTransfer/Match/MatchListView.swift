import SwiftUI
import FirebaseFirestore

struct MatchListView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var matches: [Match] = []
    @State private var showingAddMatch = false
    @State private var isEditing = false
    @State private var errorMessage: String = ""

    var body: some View {
        NavigationStack {
            List {
                ForEach(matches) { match in
                    VStack(alignment: .leading) {
                        if let heimVereinID = match.heimVereinID {
                            Text("Heim: \(heimVereinID)")
                                .font(.headline)
                        }
                        if let gastVereinID = match.gastVereinID {
                            Text("Auswärts: \(gastVereinID)")
                        }
                        Text("Datum: \(dateFormatter.string(from: match.datum))")
                        if let ergebnis = match.ergebnis {
                            Text("Ergebnis: \(ergebnis)")
                        }
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            Task {
                                await deleteMatch(match)
                            }
                        } label: {
                            Label("Löschen", systemImage: "trash")
                        }
                        Button {
                            isEditing = true
                            showingAddMatch = true
                        } label: {
                            Label("Bearbeiten", systemImage: "pencil")
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Spiel bearbeiten" : "Spielübersicht")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Neues Spiel anlegen") {
                        if authManager.isLoggedIn {
                            showingAddMatch = true
                            isEditing = false
                        } else {
                            errorMessage = "Du musst angemeldet sein, um ein neues Spiel anzulegen."
                        }
                    }
                    .disabled(!authManager.isLoggedIn)
                }
            }
            .alert(isPresented: .constant(!errorMessage.isEmpty)) {
                Alert(title: Text("Fehler"), message: Text(errorMessage), dismissButton: .default(Text("OK")) {
                    errorMessage = ""
                })
            }
            .sheet(isPresented: $showingAddMatch) {
                AddMatchView(isEditing: isEditing, initialMatch: isEditing ? matches.first : nil, onSave: { match in
                    Task {
                        if authManager.isLoggedIn {
                            if isEditing {
                                await updateMatch(match)
                            } else {
                                await createMatch(match)
                            }
                        } else {
                            await MainActor.run {
                                errorMessage = "Du musst angemeldet sein, um das Spiel zu speichern."
                            }
                        }
                        await MainActor.run {
                            showingAddMatch = false
                            isEditing = false
                        }
                    }
                }, onCancel: {
                    showingAddMatch = false
                    isEditing = false
                })
            }
            .task {
                await loadMatches()
            }
        }
    }

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    private func loadMatches() async {
        do {
            let loadedMatches = try await FirestoreManager.shared.getMatches()
            await MainActor.run {
                matches = loadedMatches
            }
        } catch {
            await MainActor.run {
                errorMessage = "Fehler beim Laden der Spiele: \(error.localizedDescription)"
            }
        }
    }

    private func createMatch(_ match: Match) async {
        do {
            try await FirestoreManager.shared.createMatch(match: match)
            await loadMatches()
        } catch {
            await MainActor.run {
                errorMessage = "Fehler beim Hinzufügen des Spiels: \(error.localizedDescription)"
            }
        }
    }

    private func updateMatch(_ match: Match) async {
        guard match.id != nil else { return }
        do {
            try await FirestoreManager.shared.updateMatch(match: match)
            await loadMatches()
        } catch {
            await MainActor.run {
                errorMessage = "Fehler beim Aktualisieren des Spiels: \(error.localizedDescription)"
            }
        }
    }

    private func deleteMatch(_ match: Match) async {
        guard let id = match.id else { return }
        do {
            try await FirestoreManager.shared.deleteMatch(matchID: id)
            await loadMatches()
        } catch {
            await MainActor.run {
                errorMessage = "Fehler beim Löschen des Spiels: \(error.localizedDescription)"
            }
        }
    }
}

struct AddMatchView: View {
    let isEditing: Bool
    let initialMatch: Match?
    let onSave: (Match) -> Void
    let onCancel: () -> Void

    @State private var heimVereinID: String = ""
    @State private var gastVereinID: String = ""
    @State private var datum: Date = Date()
    @State private var ergebnis: String? = nil
    @State private var stadion: String? = nil

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Spieldaten")) {
                    TextField("Heim-Verein-ID", text: $heimVereinID)
                    TextField("Gast-Verein-ID", text: $gastVereinID)
                    DatePicker("Datum", selection: $datum, displayedComponents: .date)
                    TextField("Ergebnis", text: Binding(
                        get: { ergebnis ?? "" },
                        set: { ergebnis = $0.isEmpty ? nil : $0 }
                    ))
                    TextField("Stadion", text: Binding(
                        get: { stadion ?? "" },
                        set: { stadion = $0.isEmpty ? nil : $0 }
                    ))
                }
            }
            .navigationTitle(isEditing ? "Spiel bearbeiten" : "Spiel anlegen")
            .onAppear {
                if let match = initialMatch {
                    heimVereinID = match.heimVereinID ?? ""
                    gastVereinID = match.gastVereinID ?? ""
                    datum = match.datum
                    ergebnis = match.ergebnis
                    stadion = match.stadion
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        onCancel()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        let match = Match(
                            id: initialMatch?.id,
                            heimVereinID: heimVereinID.isEmpty ? nil : heimVereinID,
                            gastVereinID: gastVereinID.isEmpty ? nil : gastVereinID,
                            datum: datum,
                            ergebnis: ergebnis,
                            stadion: stadion
                        )
                        onSave(match)
                    }
                }
            }
        }
    }
}

#Preview {
    MatchListView()
        .environmentObject(AuthManager())
}
