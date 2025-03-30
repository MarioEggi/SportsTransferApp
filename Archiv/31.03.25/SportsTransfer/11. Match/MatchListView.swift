import SwiftUI
import FirebaseFirestore

struct MatchListView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var viewModel = MatchViewModel()
    @State private var showingAddMatch = false
    @State private var isEditing = false

    var body: some View {
        NavigationStack {
            matchList
                .navigationTitle(isEditing ? "Spiel bearbeiten" : "Spielübersicht")
                .foregroundColor(.white) // Weiße Schrift für den Titel
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Neues Spiel anlegen") {
                            if authManager.isLoggedIn {
                                showingAddMatch = true
                                isEditing = false
                            } else {
                                viewModel.errorMessage = "Du musst angemeldet sein."
                            }
                        }
                        .foregroundColor(.white) // Weiße Schrift
                        .disabled(!authManager.isLoggedIn)
                    }
                }
                .sheet(isPresented: $showingAddMatch) {
                    AddMatchView(
                        isEditing: isEditing,
                        initialMatch: isEditing ? viewModel.matches.first : nil,
                        onSave: { match in
                            Task {
                                await viewModel.saveMatch(match)
                                await MainActor.run {
                                    showingAddMatch = false
                                    isEditing = false
                                }
                            }
                        },
                        onCancel: {
                            showingAddMatch = false
                            isEditing = false
                        }
                    )
                }
                .alert(isPresented: .constant(!viewModel.errorMessage.isEmpty)) {
                    Alert(
                        title: Text("Fehler").foregroundColor(.white),
                        message: Text(viewModel.errorMessage).foregroundColor(.white),
                        dismissButton: .default(Text("OK").foregroundColor(.white)) { viewModel.resetError() }
                    )
                }
                .task {
                    await viewModel.loadMatches()
                }
                .background(Color.black) // Schwarzer Hintergrund für die gesamte View
        }
    }

    private var matchList: some View {
        List {
            ForEach(viewModel.matches) { match in
                MatchRowView(
                    match: match,
                    viewModel: viewModel,
                    onDelete: {
                        Task { await viewModel.deleteMatch(match) }
                    },
                    onEdit: {
                        isEditing = true
                        showingAddMatch = true
                    },
                    isLast: match == viewModel.matches.last
                )
                .listRowBackground(Color.gray.opacity(0.2)) // Dunklerer Hintergrund für Listenelemente
            }
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .tint(.white) // Weißer Ladeindikator
                    .listRowBackground(Color.black) // Schwarzer Hintergrund
            }
        }
        .scrollContentBackground(.hidden) // Standard-Hintergrund der Liste ausblenden
        .background(Color.black) // Schwarzer Hintergrund für die Liste
    }
}

struct MatchRowView: View {
    let match: Match
    let viewModel: MatchViewModel
    let onDelete: () -> Void
    let onEdit: () -> Void
    let isLast: Bool
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading) {
            if let heimVereinID = match.heimVereinID {
                Text("Heim: \(heimVereinID)")
                    .font(.headline)
                    .foregroundColor(.white) // Weiße Schrift
            }
            if let gastVereinID = match.gastVereinID {
                Text("Auswärts: \(gastVereinID)")
                    .foregroundColor(.white) // Weiße Schrift
            }
            Text("Datum: \(dateFormatter.string(from: match.datum))")
                .foregroundColor(.white) // Weiße Schrift
            if let ergebnis = match.ergebnis {
                Text("Ergebnis: \(ergebnis)")
                    .foregroundColor(.white) // Weiße Schrift
            }
        }
        .swipeActions {
            Button(role: .destructive, action: onDelete) {
                Label("Löschen", systemImage: "trash")
                    .foregroundColor(.white) // Weiße Schrift und Symbol
            }
            Button(action: onEdit) {
                Label("Bearbeiten", systemImage: "pencil")
                    .foregroundColor(.white) // Weiße Schrift und Symbol
            }
            .tint(.blue)
        }
        .onAppear {
            if isLast {
                Task { await viewModel.loadMatches(loadMore: true) }
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
                Section(header: Text("Spieldaten").foregroundColor(.white)) {
                    TextField("Heim-Verein-ID", text: $heimVereinID)
                        .foregroundColor(.white) // Weiße Schrift
                    TextField("Gast-Verein-ID", text: $gastVereinID)
                        .foregroundColor(.white) // Weiße Schrift
                    DatePicker("Datum", selection: $datum, displayedComponents: .date)
                        .foregroundColor(.white) // Weiße Schrift
                        .accentColor(.white) // Weiße Akzente
                    TextField("Ergebnis", text: Binding(
                        get: { ergebnis ?? "" },
                        set: { ergebnis = $0.isEmpty ? nil : $0 }
                    ))
                        .foregroundColor(.white) // Weiße Schrift
                    TextField("Stadion", text: Binding(
                        get: { stadion ?? "" },
                        set: { stadion = $0.isEmpty ? nil : $0 }
                    ))
                        .foregroundColor(.white) // Weiße Schrift
                }
            }
            .scrollContentBackground(.hidden) // Standard-Hintergrund der Form ausblenden
            .background(Color.black) // Schwarzer Hintergrund für die Form
            .navigationTitle(isEditing ? "Spiel bearbeiten" : "Spiel anlegen")
            .foregroundColor(.white) // Weiße Schrift für den Titel
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
                    Button("Abbrechen") { onCancel() }
                        .foregroundColor(.white) // Weiße Schrift
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
                    .foregroundColor(.white) // Weiße Schrift
                }
            }
        }
    }
}

#Preview {
    MatchListView()
        .environmentObject(AuthManager())
}
