import SwiftUI
import FirebaseFirestore

struct ActivityDetailView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss
    let activity: Activity
    @State private var editedDescription = ""
    @State private var showingEditMode = false
    @State private var errorMessage = ""
    @State private var showingDeleteConfirmation = false
    @State private var comments: [String] = []
    @State private var newComment = ""
    @State private var category = "Sonstiges"

    private let categories = ["Besuch", "Coaching", "Vertrag", "Problem", "Analyse", "Sonstiges"]

    var body: some View {
        Form {
            Section(header: Text("Details")) {
                Text("Beschreibung")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                if showingEditMode {
                    TextField("Beschreibung", text: $editedDescription)
                } else {
                    Text(activity.description)
                }
                
                HStack {
                    Text("Datum")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Spacer()
                    Text(activity.timestamp, style: .date)
                }
                
                HStack {
                    Text("Erstellt von")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Spacer()
                    Text(authManager.userEmail ?? "Unbekannt")
                }

                if showingEditMode {
                    Picker("Kategorie", selection: $category) {
                        ForEach(categories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                } else {
                    HStack {
                        Text("Kategorie")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Spacer()
                        Text(category)
                    }
                }
            }

            Section(header: Text("Kommentare")) {
                if comments.isEmpty {
                    Text("Keine Kommentare vorhanden.")
                        .foregroundColor(.gray)
                } else {
                    ForEach(comments, id: \.self) { comment in
                        Text(comment)
                    }
                }
                if showingEditMode {
                    HStack {
                        TextField("Neuer Kommentar", text: $newComment)
                        Button(action: {
                            if !newComment.isEmpty {
                                comments.append("\(authManager.userEmail ?? "Unbekannt"): \(newComment)")
                                newComment = ""
                            }
                        }) {
                            Image(systemName: "plus.circle")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }

            if showingEditMode {
                Section {
                    Button("Speichern") {
                        Task {
                            await saveChanges()
                        }
                    }
                    .foregroundColor(.blue)
                    
                    Button("Abbrechen") {
                        editedDescription = activity.description
                        category = activity.category ?? "Sonstiges"
                        comments = activity.comments ?? []
                        showingEditMode = false
                    }
                    .foregroundColor(.gray)
                }
            }

            Section {
                Button("Aktivität löschen") {
                    showingDeleteConfirmation = true
                }
                .foregroundColor(.red)
            }
        }
        .navigationTitle("Aktivität")
        .toolbar {
            if !showingEditMode {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { enterEditMode() }) {
                        Image(systemName: "pencil")
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .alert(isPresented: $showingDeleteConfirmation) {
            Alert(
                title: Text("Aktivität löschen"),
                message: Text("Möchtest du diese Aktivität wirklich löschen?"),
                primaryButton: .destructive(Text("Löschen")) {
                    Task {
                        await deleteActivity()
                    }
                },
                secondaryButton: .cancel()
            )
        }
        .alert(isPresented: .constant(!errorMessage.isEmpty)) {
            Alert(title: Text("Fehler"), message: Text(errorMessage), dismissButton: .default(Text("OK")) {
                errorMessage = ""
            })
        }
        .onAppear {
            editedDescription = activity.description
            category = activity.category ?? "Sonstiges"
            comments = activity.comments ?? []
        }
    }

    private func enterEditMode() {
        showingEditMode = true
    }

    private func saveChanges() async {
        guard let activityID = activity.id else {
            await MainActor.run {
                errorMessage = "Keine Aktivitäts-ID vorhanden"
            }
            return
        }
        let updatedActivity = Activity(
            id: activityID,
            clientID: activity.clientID,
            description: editedDescription,
            timestamp: activity.timestamp,
            category: category,
            comments: comments
        )
        do {
            try await FirestoreManager.shared.updateActivity(activity: updatedActivity)
            await MainActor.run {
                showingEditMode = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Fehler beim Speichern: \(error.localizedDescription)"
            }
        }
    }

    private func deleteActivity() async {
        guard let activityID = activity.id else {
            await MainActor.run {
                errorMessage = "Keine Aktivitäts-ID vorhanden"
            }
            return
        }
        do {
            try await FirestoreManager.shared.deleteActivity(activityID: activityID)
            await MainActor.run {
                dismiss() // Zurück zur ClientView
            }
        } catch {
            await MainActor.run {
                errorMessage = "Fehler beim Löschen: \(error.localizedDescription)"
            }
        }
    }
}

#Preview("Activity Detail") {
    ActivityDetailView(activity: Activity(id: "1", clientID: "client1", description: "Besprechung mit Trainer", timestamp: Date()))
        .environmentObject(AuthManager())
}
