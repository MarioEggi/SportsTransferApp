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
        NavigationView {
            mainContent
                .navigationTitle("Aktivität")
                .foregroundColor(.white)
                .toolbar { toolbarItems }
                .alert(isPresented: $showingDeleteConfirmation) { deleteConfirmationAlert }
                .alert(isPresented: .constant(!errorMessage.isEmpty)) { errorAlert }
                .onAppear {
                    editedDescription = activity.description
                    category = activity.category ?? "Sonstiges"
                    comments = activity.comments ?? []
                }
        }
    }

    // Hauptinhalt
    private var mainContent: some View {
        Form {
            detailsSection
            commentsSection
            if showingEditMode { editActionsSection }
            deleteSection
        }
        .scrollContentBackground(.hidden)
        .background(Color.black)
    }

    // Toolbar-Items
    private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            if !showingEditMode {
                Button(action: { enterEditMode() }) {
                    Image(systemName: "pencil")
                        .foregroundColor(.white)
                }
            }
        }
    }

    // Details-Sektion
    private var detailsSection: some View {
        Section(header: Text("Details").foregroundColor(.white)) {
            descriptionField
            dateField
            createdByField
            categoryField
        }
    }

    private var descriptionField: some View {
        Group {
            Text("Beschreibung").font(.subheadline).foregroundColor(.gray)
            if showingEditMode {
                TextField("Beschreibung", text: $editedDescription).foregroundColor(.white)
            } else {
                Text(activity.description).foregroundColor(.white)
            }
        }
    }

    private var dateField: some View {
        HStack {
            Text("Datum").font(.subheadline).foregroundColor(.gray)
            Spacer()
            Text(activity.timestamp, style: .date).foregroundColor(.white)
        }
    }

    private var createdByField: some View {
        HStack {
            Text("Erstellt von").font(.subheadline).foregroundColor(.gray)
            Spacer()
            Text(authManager.userEmail ?? "Unbekannt").foregroundColor(.white)
        }
    }

    private var categoryField: some View {
        Group {
            if showingEditMode {
                Picker("Kategorie", selection: $category) {
                    ForEach(Constants.activityCategories, id: \.self) { cat in
                        Text(cat).tag(cat)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .foregroundColor(.white)
                .accentColor(.white)
            } else {
                HStack {
                    Text("Kategorie").font(.subheadline).foregroundColor(.gray)
                    Spacer()
                    Text(category).foregroundColor(.white)
                }
            }
        }
    }

    // Kommentare-Sektion
    private var commentsSection: some View {
        Section(header: Text("Kommentare").foregroundColor(.white)) {
            if comments.isEmpty {
                Text("Keine Kommentare vorhanden.").foregroundColor(.gray)
            } else {
                ForEach(comments, id: \.self) { comment in
                    Text(comment).foregroundColor(.white)
                }
            }
            if showingEditMode { commentInputField }
        }
    }

    private var commentInputField: some View {
        HStack {
            TextField("Neuer Kommentar", text: $newComment).foregroundColor(.white)
            Button(action: {
                if !newComment.isEmpty {
                    comments.append("\(authManager.userEmail ?? "Unbekannt"): \(newComment)")
                    newComment = ""
                }
            }) {
                Image(systemName: "plus.circle").foregroundColor(.white)
            }
        }
    }

    // Edit-Aktionen-Sektion
    private var editActionsSection: some View {
        Section {
            Button("Speichern") {
                Task { await saveChanges() }
            }
            .foregroundColor(.white)
            Button("Abbrechen") {
                editedDescription = activity.description
                category = activity.category ?? "Sonstiges"
                comments = activity.comments ?? []
                showingEditMode = false
            }
            .foregroundColor(.gray)
        }
    }

    // Lösch-Sektion
    private var deleteSection: some View {
        Section {
            Button("Aktivität löschen") {
                showingDeleteConfirmation = true
            }
            .foregroundColor(.red)
        }
    }

    // Löschen-Bestätigungs-Alert
    private var deleteConfirmationAlert: Alert {
        Alert(
            title: Text("Aktivität löschen").foregroundColor(.white),
            message: Text("Möchtest du diese Aktivität wirklich löschen?").foregroundColor(.white),
            primaryButton: .destructive(Text("Löschen").foregroundColor(.red)) {
                Task { await deleteActivity() }
            },
            secondaryButton: .cancel(Text("Abbrechen").foregroundColor(.white))
        )
    }

    // Fehler-Alert
    private var errorAlert: Alert {
        Alert(
            title: Text("Fehler").foregroundColor(.white),
            message: Text(errorMessage).foregroundColor(.white),
            dismissButton: .default(Text("OK").foregroundColor(.white)) { errorMessage = "" }
        )
    }

    private func enterEditMode() {
        showingEditMode = true
    }

    private func saveChanges() async {
        guard let activityID = activity.id else {
            await MainActor.run { errorMessage = "Keine Aktivitäts-ID vorhanden" }
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
            await MainActor.run { showingEditMode = false }
        } catch {
            await MainActor.run { errorMessage = "Fehler beim Speichern: \(error.localizedDescription)" }
        }
    }

    private func deleteActivity() async {
        guard let activityID = activity.id else {
            await MainActor.run { errorMessage = "Keine Aktivitäts-ID vorhanden" }
            return
        }
        do {
            try await FirestoreManager.shared.deleteActivity(activityID: activityID)
            await MainActor.run { dismiss() }
        } catch {
            await MainActor.run { errorMessage = "Fehler beim Löschen: \(error.localizedDescription)" }
        }
    }
}

#Preview("Activity Detail") {
    ActivityDetailView(activity: Activity(id: "1", clientID: "client1", description: "Besprechung mit Trainer", timestamp: Date()))
        .environmentObject(AuthManager())
}
