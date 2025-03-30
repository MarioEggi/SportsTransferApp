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

    var body: some View {
        Form {
            Section(header: Text("Details").foregroundColor(.white)) {
                Text("Beschreibung")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                if showingEditMode {
                    TextField("Beschreibung", text: $editedDescription)
                        .foregroundColor(.white) // Weiße Schrift
                } else {
                    Text(activity.description)
                        .foregroundColor(.white) // Weiße Schrift
                }
                
                HStack {
                    Text("Datum")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Spacer()
                    Text(activity.timestamp, style: .date)
                        .foregroundColor(.white) // Weiße Schrift
                }
                
                HStack {
                    Text("Erstellt von")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Spacer()
                    Text(authManager.userEmail ?? "Unbekannt")
                        .foregroundColor(.white) // Weiße Schrift
                }

                if showingEditMode {
                    Picker("Kategorie", selection: $category) {
                        ForEach(Constants.activityCategories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .foregroundColor(.white) // Weiße Schrift
                    .accentColor(.white) // Weiße Akzente
                } else {
                    HStack {
                        Text("Kategorie")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Spacer()
                        Text(category)
                            .foregroundColor(.white) // Weiße Schrift
                    }
                }
            }

            Section(header: Text("Kommentare").foregroundColor(.white)) {
                if comments.isEmpty {
                    Text("Keine Kommentare vorhanden.")
                        .foregroundColor(.gray)
                } else {
                    ForEach(comments, id: \.self) { comment in
                        Text(comment)
                            .foregroundColor(.white) // Weiße Schrift
                    }
                }
                if showingEditMode {
                    HStack {
                        TextField("Neuer Kommentar", text: $newComment)
                            .foregroundColor(.white) // Weiße Schrift
                        Button(action: {
                            if !newComment.isEmpty {
                                comments.append("\(authManager.userEmail ?? "Unbekannt"): \(newComment)")
                                newComment = ""
                            }
                        }) {
                            Image(systemName: "plus.circle")
                                .foregroundColor(.white) // Weißes Symbol
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
                    .foregroundColor(.white) // Weiße Schrift
                    
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
        .scrollContentBackground(.hidden) // Standard-Hintergrund der Form ausblenden
        .background(Color.black) // Schwarzer Hintergrund für die Form
        .navigationTitle("Aktivität")
        .foregroundColor(.white) // Weiße Schrift für den Titel
        .toolbar {
            if !showingEditMode {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { enterEditMode() }) {
                        Image(systemName: "pencil")
                            .foregroundColor(.white) // Weißes Symbol
                    }
                }
            }
        }
        .alert(isPresented: $showingDeleteConfirmation) {
            Alert(
                title: Text("Aktivität löschen").foregroundColor(.white),
                message: Text("Möchtest du diese Aktivität wirklich löschen?").foregroundColor(.white),
                primaryButton: .destructive(Text("Löschen").foregroundColor(.red)) {
                    Task {
                        await deleteActivity()
                    }
                },
                secondaryButton: .cancel(Text("Abbrechen").foregroundColor(.white))
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
                dismiss()
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
