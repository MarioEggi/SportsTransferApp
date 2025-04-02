import SwiftUI
import FirebaseFirestore

struct MatchListView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var viewModel = MatchViewModel()
    @State private var showingAddMatch = false
    @State private var isEditing = false

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
                        Text(isEditing ? "Spiel bearbeiten" : "Spiele")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(textColor)
                        Spacer()
                        Button(action: {
                            if authManager.isLoggedIn {
                                showingAddMatch = true
                                isEditing = false
                            } else {
                                viewModel.errorMessage = "Du musst angemeldet sein."
                            }
                        }) {
                            Image(systemName: "plus")
                                .foregroundColor(accentColor)
                        }
                        .disabled(!authManager.isLoggedIn)
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)

                    List {
                        if viewModel.matches.isEmpty && !viewModel.isLoading {
                            Text("Keine Spiele vorhanden.")
                                .foregroundColor(secondaryTextColor)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .listRowBackground(backgroundColor)
                        } else {
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
                            if viewModel.isLoading {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                                    .tint(accentColor)
                                    .listRowBackground(backgroundColor)
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                    .scrollContentBackground(.hidden)
                    .background(backgroundColor)
                    .padding(.horizontal)
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
                        title: Text("Fehler").foregroundColor(textColor),
                        message: Text(viewModel.errorMessage).foregroundColor(secondaryTextColor),
                        dismissButton: .default(Text("OK").foregroundColor(accentColor)) { viewModel.resetError() }
                    )
                }
                .task {
                    await viewModel.loadMatches()
                }
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

    // Farben für das dunkle Design
    private let textColor = Color(hex: "#E0E0E0")
    private let secondaryTextColor = Color(hex: "#B0BEC5")
    private let accentColor = Color(hex: "#00C4B4")

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let heimVereinID = match.heimVereinID {
                Text("Heim: \(heimVereinID)")
                    .font(.headline)
                    .foregroundColor(textColor)
            }
            if let gastVereinID = match.gastVereinID {
                Text("Auswärts: \(gastVereinID)")
                    .font(.caption)
                    .foregroundColor(secondaryTextColor)
            }
            Text("Datum: \(dateFormatter.string(from: match.datum))")
                .font(.caption)
                .foregroundColor(secondaryTextColor)
            if let ergebnis = match.ergebnis {
                Text("Ergebnis: \(ergebnis)")
                    .font(.caption)
                    .foregroundColor(secondaryTextColor)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .swipeActions {
            Button(role: .destructive, action: onDelete) {
                Label("Löschen", systemImage: "trash")
                    .foregroundColor(.white)
            }
            Button(action: onEdit) {
                Label("Bearbeiten", systemImage: "pencil")
                    .foregroundColor(.white)
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

#Preview {
    MatchListView()
        .environmentObject(AuthManager())
}

import SwiftUI

struct AddMatchView: View {
    let isEditing: Bool
    let initialMatch: Match?
    let onSave: (Match) -> Void
    let onCancel: () -> Void
    @Environment(\.dismiss) var dismiss

    @State private var heimVereinID: String = ""
    @State private var gastVereinID: String = ""
    @State private var datum: Date = Date()
    @State private var ergebnis: String? = nil
    @State private var stadion: String? = nil

    // Farben für das helle Design
    private let backgroundColor = Color(hex: "#F5F5F5")
    private let cardBackgroundColor = Color(hex: "#E0E0E0")
    private let accentColor = Color(hex: "#00C4B4")
    private let textColor = Color(hex: "#333333")
    private let secondaryTextColor = Color(hex: "#666666")

    var body: some View {
        NavigationView {
            ZStack {
                backgroundColor.edgesIgnoringSafeArea(.all)
                List {
                    Section(header: Text("Spieldaten").foregroundColor(textColor)) {
                        VStack(spacing: 10) {
                            TextField("Heim-Verein-ID", text: $heimVereinID)
                                .foregroundColor(textColor)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                            TextField("Gast-Verein-ID", text: $gastVereinID)
                                .foregroundColor(textColor)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                            DatePicker("Datum", selection: $datum, displayedComponents: .date)
                                .foregroundColor(textColor)
                                .tint(accentColor)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                            TextField("Ergebnis", text: Binding(
                                get: { ergebnis ?? "" },
                                set: { ergebnis = $0.isEmpty ? nil : $0 }
                            ))
                                .foregroundColor(textColor)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                            TextField("Stadion", text: Binding(
                                get: { stadion ?? "" },
                                set: { stadion = $0.isEmpty ? nil : $0 }
                            ))
                                .foregroundColor(textColor)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                        }
                        .padding(.vertical, 8)
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
                }
                .listStyle(PlainListStyle())
                .listRowInsets(EdgeInsets(top: 3, leading: 13, bottom: 3, trailing: 13))
                .scrollContentBackground(.hidden)
                .background(backgroundColor)
                .navigationTitle(isEditing ? "Spiel bearbeiten" : "Spiel anlegen")
                .foregroundColor(textColor)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Abbrechen") { onCancel() }
                            .foregroundColor(accentColor)
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
                            dismiss()
                        }
                        .foregroundColor(accentColor)
                    }
                }
                .onAppear {
                    if let match = initialMatch {
                        heimVereinID = match.heimVereinID ?? ""
                        gastVereinID = match.gastVereinID ?? ""
                        datum = match.datum
                        ergebnis = match.ergebnis
                        stadion = match.stadion
                    }
                }
            }
        }
    }
}

#Preview {
    AddMatchView(
        isEditing: false,
        initialMatch: nil,
        onSave: { _ in },
        onCancel: {}
    )
}
