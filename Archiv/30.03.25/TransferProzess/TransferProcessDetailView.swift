import SwiftUI

struct TransferProcessDetailView: View {
    @State var transferProcess: TransferProcess
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var transferProcessViewModel: TransferProcessViewModel
    @State private var client: Client?
    @State private var club: Club?
    @State private var errorMessage = ""
    @State private var showingAddStepSheet = false
    @State private var showingAddReminderSheet = false
    @State private var showingAddNoteSheet = false
    @State private var showingAddTransferDetailsSheet = false
    @State private var editingStep: Step?
    @State private var editingReminder: Reminder?
    @State private var editingNote: Note?
    @State private var showingDeleteConfirmation = false
    @State private var reminderToDelete: Reminder?
    @State private var noteToDelete: Note?
    @State private var stepToDelete: Step?

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

                ScrollView {
                    VStack(spacing: 16) {
                        // Titel
                        Text("Transferprozess Details")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(textColor)
                            .padding(.top, 16)
                            .padding(.horizontal)

                        // Basisinformationen
                        VStack(alignment: .leading, spacing: 12) {
                            if let client = client {
                                Text("Klient: \(client.vorname) \(client.name)")
                                    .font(.headline)
                                    .foregroundColor(textColor)
                            }
                            if let club = club {
                                Text("Verein: \(club.name)")
                                    .font(.headline)
                                    .foregroundColor(textColor)
                            }
                            Text("Art: \(transferProcess.art ?? "Nicht angegeben")")
                                .font(.headline)
                                .foregroundColor(textColor)
                            HStack {
                                Text("Status:")
                                    .font(.headline)
                                    .foregroundColor(textColor)
                                if authManager.userRole == .mitarbeiter {
                                    Menu {
                                        Button("In Bearbeitung") { updateStatus(to: "in Bearbeitung") }
                                        Button("Abgeschlossen") { updateStatus(to: "abgeschlossen") }
                                        Button("Abgebrochen") { updateStatus(to: "abgebrochen") }
                                    } label: {
                                        Text(transferProcess.status)
                                            .foregroundColor(statusColor)
                                            .padding(.vertical, 6)
                                            .padding(.horizontal, 12)
                                            .background(cardBackgroundColor)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                } else {
                                    Text(transferProcess.status)
                                        .foregroundColor(statusColor)
                                        .font(.headline)
                                }
                            }
                            Text("Startdatum: \(dateFormatter.string(from: transferProcess.startDatum))")
                                .font(.subheadline)
                                .foregroundColor(secondaryTextColor)
                        }
                        .padding()
                        .background(cardBackgroundColor)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(accentColor.opacity(0.2), lineWidth: 1)
                        )
                        .padding(.horizontal)

                        // Transferdetails (nur wenn abgeschlossen)
                        if transferProcess.status == "abgeschlossen" {
                            SectionHeader(
                                title: "Transferdetails",
                                action: authManager.userRole == .mitarbeiter ? { showingAddTransferDetailsSheet = true } : nil,
                                icon: transferProcess.transferDetails == nil ? "plus.circle" : "pencil.circle"
                            )
                            if let details = transferProcess.transferDetails {
                                TransferDetailsItemView(transferDetails: details)
                            } else {
                                Text("Keine Transferdetails vorhanden.")
                                    .foregroundColor(secondaryTextColor)
                                    .font(.subheadline)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                        }

                        // Schritte
                        SectionHeader(
                            title: "Schritte",
                            action: authManager.userRole == .mitarbeiter ? { editingStep = nil; showingAddStepSheet = true } : nil,
                            icon: "plus.circle"
                        )
                        if transferProcess.schritte.isEmpty {
                            Text("Keine Schritte vorhanden.")
                                .foregroundColor(secondaryTextColor)
                                .font(.subheadline)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            ForEach(transferProcess.schritte) { step in
                                StepCard(step: step)
                                    .onTapGesture {
                                        if authManager.userRole == .mitarbeiter {
                                            editingStep = step
                                            showingAddStepSheet = true
                                        }
                                    }
                                    .contextMenu {
                                        if authManager.userRole == .mitarbeiter {
                                            Button(role: .destructive, action: {
                                                stepToDelete = step
                                                showingDeleteConfirmation = true
                                            }) {
                                                Label("Löschen", systemImage: "trash")
                                            }
                                        }
                                    }
                            }
                        }

                        // Erinnerungen
                        SectionHeader(
                            title: "Erinnerungen",
                            action: authManager.userRole == .mitarbeiter ? { editingReminder = nil; showingAddReminderSheet = true } : nil,
                            icon: "plus.circle"
                        )
                        if let erinnerungen = transferProcess.erinnerungen, !erinnerungen.isEmpty {
                            ForEach(erinnerungen) { erinnerung in
                                ReminderCard(erinnerung: erinnerung)
                                    .onTapGesture {
                                        if authManager.userRole == .mitarbeiter {
                                            editingReminder = erinnerung
                                            showingAddReminderSheet = true
                                        }
                                    }
                                    .contextMenu {
                                        if authManager.userRole == .mitarbeiter {
                                            Button(role: .destructive, action: {
                                                reminderToDelete = erinnerung
                                                showingDeleteConfirmation = true
                                            }) {
                                                Label("Löschen", systemImage: "trash")
                                            }
                                            Button(action: {
                                                Task {
                                                    do {
                                                        try await transferProcessViewModel.addReminderToCalendar(reminder: erinnerung, for: transferProcess)
                                                    } catch {
                                                        errorMessage = "Fehler beim Hinzufügen zum Kalender: \(error.localizedDescription)"
                                                    }
                                                }
                                            }) {
                                                Label("Zum Kalender hinzufügen", systemImage: "calendar")
                                            }
                                        }
                                    }
                            }
                        } else {
                            Text("Keine Erinnerungen vorhanden.")
                                .foregroundColor(secondaryTextColor)
                                .font(.subheadline)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .center)
                        }

                        // Hinweise
                        SectionHeader(
                            title: "Hinweise",
                            action: authManager.userRole == .mitarbeiter ? { editingNote = nil; showingAddNoteSheet = true } : nil,
                            icon: "plus.circle"
                        )
                        if let hinweise = transferProcess.hinweise, !hinweise.isEmpty {
                            ForEach(hinweise) { hinweis in
                                NoteCard(hinweis: hinweis)
                                    .onTapGesture {
                                        if authManager.userRole == .mitarbeiter {
                                            editingNote = hinweis
                                            showingAddNoteSheet = true
                                        }
                                    }
                                    .contextMenu {
                                        if authManager.userRole == .mitarbeiter {
                                            Button(role: .destructive, action: {
                                                noteToDelete = hinweis
                                                showingDeleteConfirmation = true
                                            }) {
                                                Label("Löschen", systemImage: "trash")
                                            }
                                        }
                                    }
                            }
                        } else {
                            Text("Keine Hinweise vorhanden.")
                                .foregroundColor(secondaryTextColor)
                                .font(.subheadline)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .center)
                        }

                        Spacer(minLength: 80) // Platz für die untere Leiste
                    }
                    .padding(.bottom, 16)
                }
            }
            .ignoresSafeArea(.all, edges: .bottom)
            .navigationTitle("Transferprozess")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        // Hier könnte eine Aktion wie "Teilen" oder "E-Mail generieren" hinzugefügt werden
                    }) {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(accentColor)
                            .font(.system(size: 20, weight: .medium))
                    }
                }
            }
            .sheet(isPresented: $showingAddStepSheet) {
                AddEditStepView(
                    transferProcess: $transferProcess,
                    step: editingStep,
                    onSave: saveStep
                )
            }
            .sheet(isPresented: $showingAddReminderSheet) {
                AddEditReminderView(
                    transferProcess: $transferProcess,
                    reminder: editingReminder,
                    onSave: saveReminder
                )
            }
            .sheet(isPresented: $showingAddNoteSheet) {
                AddEditNoteView(
                    transferProcess: $transferProcess,
                    note: editingNote,
                    onSave: saveNote
                )
            }
            .sheet(isPresented: $showingAddTransferDetailsSheet) {
                AddEditTransferDetailsView(
                    transferProcess: $transferProcess,
                    transferDetails: transferProcess.transferDetails,
                    onSave: saveTransferDetails
                )
            }
            .alert("Löschen bestätigen", isPresented: $showingDeleteConfirmation) {
                Button("Abbrechen", role: .cancel) { clearDeleteSelection() }
                Button("Löschen", role: .destructive) { deleteSelectedItem() }
            } message: {
                if reminderToDelete != nil { Text("Möchten Sie diese Erinnerung wirklich löschen?") }
                else if noteToDelete != nil { Text("Möchten Sie diesen Hinweis wirklich löschen?") }
                else if stepToDelete != nil { Text("Möchten Sie diesen Schritt wirklich löschen?") }
            }
            .task { await loadClientAndClub() }
            .alert(isPresented: Binding(get: { !errorMessage.isEmpty }, set: { if !$0 { errorMessage = "" } })) {
                Alert(
                    title: Text("Fehler").foregroundColor(textColor),
                    message: Text(errorMessage).foregroundColor(secondaryTextColor),
                    dismissButton: .default(Text("OK").foregroundColor(accentColor))
                )
            }
        }
    }

    // Section-Header mit Titel und optionalem Button
    private func SectionHeader(title: String, action: (() -> Void)?, icon: String?) -> some View {
        HStack {
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(textColor)
            Spacer()
            if let action = action, let icon = icon {
                Button(action: action) {
                    Image(systemName: icon)
                        .foregroundColor(accentColor)
                        .font(.system(size: 20, weight: .medium))
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    // Card für Schritte
    private func StepCard(step: Step) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: step.status == "abgeschlossen" ? "checkmark.circle.fill" : "circle")
                .foregroundColor(step.status == "abgeschlossen" ? .green : secondaryTextColor)
                .font(.system(size: 20))
            VStack(alignment: .leading, spacing: 6) {
                Text(step.typ)
                    .font(.headline)
                    .foregroundColor(textColor)
                Text("Datum: \(dateFormatter.string(from: step.datum))")
                    .font(.subheadline)
                    .foregroundColor(secondaryTextColor)
                if let notizen = step.notizen {
                    Text("Notizen: \(notizen)")
                        .font(.caption)
                        .foregroundColor(secondaryTextColor)
                        .lineLimit(2)
                }
            }
        }
        .padding()
        .background(cardBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(accentColor.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal)
    }

    // Card für Erinnerungen
    private func ReminderCard(erinnerung: Reminder) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "bell.fill")
                .foregroundColor(accentColor)
                .font(.system(size: 20))
            VStack(alignment: .leading, spacing: 6) {
                Text("Datum: \(dateFormatter.string(from: erinnerung.datum))")
                    .font(.subheadline)
                    .foregroundColor(secondaryTextColor)
                Text(erinnerung.beschreibung)
                    .font(.headline)
                    .foregroundColor(textColor)
            }
            Spacer()
            if authManager.userRole == .mitarbeiter {
                Button(action: {
                    Task {
                        do {
                            try await transferProcessViewModel.addReminderToCalendar(reminder: erinnerung, for: transferProcess)
                        } catch {
                            errorMessage = "Fehler beim Hinzufügen zum Kalender: \(error.localizedDescription)"
                        }
                    }
                }) {
                    Image(systemName: "calendar")
                        .foregroundColor(accentColor)
                        .font(.system(size: 20))
                }
            }
        }
        .padding()
        .background(cardBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(accentColor.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal)
    }

    // Card für Hinweise
    private func NoteCard(hinweis: Note) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "note.text")
                .foregroundColor(accentColor)
                .font(.system(size: 20))
            Text(hinweis.beschreibung)
                .font(.body)
                .foregroundColor(textColor)
                .lineLimit(3)
            Spacer()
        }
        .padding()
        .background(cardBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(accentColor.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal)
    }

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    private var statusColor: Color {
        switch transferProcess.status {
        case "in Bearbeitung": return .orange
        case "abgeschlossen": return .green
        case "abgebrochen": return .red
        default: return secondaryTextColor
        }
    }

    private func loadClientAndClub() async {
        do {
            let (clients, _) = try await FirestoreManager.shared.getClients(limit: 1000)
            await MainActor.run {
                self.client = clients.first { $0.id == transferProcess.clientID }
            }

            let (clubs, _) = try await FirestoreManager.shared.getClubs(limit: 1000)
            await MainActor.run {
                self.club = clubs.first { $0.id == transferProcess.vereinID }
            }
        } catch {
            errorMessage = "Fehler beim Laden: \(error.localizedDescription)"
        }
    }

    private func updateStatus(to newStatus: String) {
        transferProcess.status = newStatus
        saveTransferProcess()
    }

    private func saveStep(_ updatedStep: Step) {
        if let index = transferProcess.schritte.firstIndex(where: { $0.id == updatedStep.id }) {
            transferProcess.schritte[index] = updatedStep
        } else {
            transferProcess.schritte.append(updatedStep)
        }
        saveTransferProcess()
    }

    private func saveReminder(_ updatedReminder: Reminder) {
        var updatedErinnerungen = transferProcess.erinnerungen ?? []
        if let index = updatedErinnerungen.firstIndex(where: { $0.id == updatedReminder.id }) {
            updatedErinnerungen[index] = updatedReminder
        } else {
            updatedErinnerungen.append(updatedReminder)
        }
        transferProcess.erinnerungen = updatedErinnerungen
        saveTransferProcess()
    }

    private func saveNote(_ updatedNote: Note) {
        var updatedHinweise = transferProcess.hinweise ?? []
        if let index = updatedHinweise.firstIndex(where: { $0.id == updatedNote.id }) {
            updatedHinweise[index] = updatedNote
        } else {
            updatedHinweise.append(updatedNote)
        }
        transferProcess.hinweise = updatedHinweise
        saveTransferProcess()
    }

    private func saveTransferDetails(_ updatedDetails: TransferDetails) {
        transferProcess.transferDetails = updatedDetails
        saveTransferProcess()
    }

    private func saveTransferProcess() {
        Task {
            do {
                try await FirestoreManager.shared.updateTransferProcess(transferProcess: transferProcess)
            } catch {
                errorMessage = "Fehler beim Speichern: \(error.localizedDescription)"
            }
        }
    }

    private func deleteSelectedItem() {
        if let reminder = reminderToDelete {
            transferProcess.erinnerungen = transferProcess.erinnerungen?.filter { $0.id != reminder.id }
        } else if let note = noteToDelete {
            transferProcess.hinweise = transferProcess.hinweise?.filter { $0.id != note.id }
        } else if let step = stepToDelete {
            transferProcess.schritte = transferProcess.schritte.filter { $0.id != step.id }
        }
        saveTransferProcess()
        clearDeleteSelection()
    }

    private func clearDeleteSelection() {
        reminderToDelete = nil
        noteToDelete = nil
        stepToDelete = nil
    }
}

struct TransferDetailsItemView: View {
    let transferDetails: TransferDetails

    // Farben für das dunkle Design
    private let cardBackgroundColor = Color(hex: "#2A3439")
    private let textColor = Color(hex: "#E0E0E0")
    private let secondaryTextColor = Color(hex: "#B0BEC5")
    private let accentColor = Color(hex: "#00C4B4")

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Datum: \(dateFormatter.string(from: transferDetails.datum))")
                .font(.subheadline)
                .foregroundColor(secondaryTextColor)
            if let ablöse = transferDetails.ablösesumme {
                Text("Ablösesumme: \(ablöse, specifier: "%.2f")")
                    .font(.body)
                    .foregroundColor(textColor)
            }
            Text("Ablösefrei: \(transferDetails.isAblösefrei ? "Ja" : "Nein")")
                .font(.body)
                .foregroundColor(textColor)
            if let details = transferDetails.transferdetails {
                Text("Details: \(details)")
                    .font(.body)
                    .foregroundColor(secondaryTextColor)
                    .lineLimit(3)
            }
        }
        .padding()
        .background(cardBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(accentColor.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal)
    }

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
}
