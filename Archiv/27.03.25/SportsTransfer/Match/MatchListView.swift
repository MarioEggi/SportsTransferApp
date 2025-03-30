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
                        title: Text("Fehler"),
                        message: Text(viewModel.errorMessage),
                        dismissButton: .default(Text("OK")) { viewModel.resetError() }
                    )
                }
                .task {
                    await viewModel.loadMatches()
                }
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
            }
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
            }
        }
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
            Button(role: .destructive, action: onDelete) {
                Label("Löschen", systemImage: "trash")
            }
            Button(action: onEdit) {
                Label("Bearbeiten", systemImage: "pencil")
            }
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
                    Button("Abbrechen") { onCancel() }
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
