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
    @State private var showingEmailPreview = false
    @State private var generatedEmail = ""

    // Farben für das dunkle Design (definiert in Extensions.swift)
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
                        headerView
                        basicInfoView
                        if transferProcess.status == "abgeschlossen" {
                            transferDetailsView
                        }
                        stepsView
                        remindersView
                        notesView
                        Spacer(minLength: 80) // Platz für die untere Leiste
                    }
                    .padding(.bottom, 16)
                }
            }
            .ignoresSafeArea(edges: .bottom)
            .navigationTitle("Transferprozess")
            .toolbar { toolbarContent }
            .sheet(isPresented: $showingEmailPreview) {
                EmailPreviewView(
                    isPresented: $showingEmailPreview,
                    emailContent: generatedEmail, // Änderung: Binding entfernt, nur den Wert übergeben
                    process: transferProcess,
                    step: transferProcess.schritte.first ?? Step(typ: "Unbekannt", status: "geplant", datum: Date()),
                    viewModel: transferProcessViewModel,
                    onCopy: { content in
                        UIPasteboard.general.string = content
                        errorMessage = "E-Mail in Zwischenablage kopiert"
                    }
                )
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

    // Sub-Views für Modularität

    private var headerView: some View {
        Text("Transferprozess Details")
            .font(.title2)
            .fontWeight(.bold)
            .foregroundColor(textColor)
            .padding(.top, 16)
            .padding(.horizontal)
    }

    private var basicInfoView: some View {
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
            statusView
            Text("Startdatum: \(dateFormatter.string(from: transferProcess.startDatum))")
                .font(.subheadline)
                .foregroundColor(secondaryTextColor)
            if authManager.userRole == .mitarbeiter {
                mitarbeiterPicker
                priorityPicker
            } else {
                if let mitarbeiterID = transferProcess.mitarbeiterID {
                    Text("Mitarbeiter: \(mitarbeiterID)")
                        .font(.subheadline)
                        .foregroundColor(secondaryTextColor)
                }
                if let priority = transferProcess.priority {
                    Text("Priorität: \(priority)")
                        .font(.subheadline)
                        .foregroundColor(secondaryTextColor)
                }
            }
        }
        .padding()
        .background(cardBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(accentColor, lineWidth: 1)
        )
        .opacity(0.2)
        .padding(.horizontal)
    }

    private var statusView: some View {
        HStack {
            Text("Status:")
                .font(.headline)
                .foregroundColor(textColor)
            if authManager.userRole == .mitarbeiter {
                Picker("Status", selection: $transferProcess.status) {
                    Text("In Bearbeitung").tag("in Bearbeitung")
                    Text("Abgeschlossen").tag("abgeschlossen")
                    Text("Abgebrochen").tag("abgebrochen")
                }
                .pickerStyle(.menu)
                .foregroundColor(statusColor)
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(cardBackgroundColor)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .onChange(of: transferProcess.status) { _ in
                    saveTransferProcess()
                }
            } else {
                Text(transferProcess.status)
                    .foregroundColor(statusColor)
                    .font(.headline)
            }
        }
    }

    private var mitarbeiterPicker: some View {
        Picker("Mitarbeiter", selection: $transferProcess.mitarbeiterID) {
            Text("Nicht zugewiesen").tag(String?.none)
            ForEach(transferProcessViewModel.mitarbeiter, id: \.self) { mitarbeiter in
                Text(mitarbeiter).tag(mitarbeiter as String?)
            }
        }
        .pickerStyle(.menu)
        .foregroundColor(textColor)
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(cardBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .onChange(of: transferProcess.mitarbeiterID) { _ in
            saveTransferProcess()
        }
    }

    private var priorityPicker: some View {
        Picker("Priorität", selection: $transferProcess.priority) {
            Text("Keine").tag(Int?.none)
            ForEach(1...5, id: \.self) { value in
                Text("\(value)").tag(value as Int?)
            }
        }
        .pickerStyle(.menu)
        .foregroundColor(textColor)
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(cardBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .onChange(of: transferProcess.priority) { _ in
            saveTransferProcess()
        }
    }

    private var transferDetailsView: some View {
        VStack(spacing: 8) {
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
    }

    private var stepsView: some View {
        VStack(spacing: 8) {
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
        }
    }

    private var remindersView: some View {
        VStack(spacing: 8) {
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
        }
    }

    private var notesView: some View {
        VStack(spacing: 8) {
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
        }
    }

    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button(action: {
                    Task {
                        if let firstStep = transferProcess.schritte.first {
                            let emailContent = await transferProcessViewModel.generateEmail(for: transferProcess, step: firstStep)
                            await MainActor.run {
                                generatedEmail = emailContent
                                showingEmailPreview = true
                            }
                        } else {
                            await MainActor.run {
                                errorMessage = "Keine Schritte vorhanden, um eine E-Mail zu generieren"
                            }
                        }
                    }
                }) {
                    Label("E-Mail generieren", systemImage: "envelope")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundColor(accentColor)
                    .font(.system(size: 20, weight: .medium))
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
                if let chance = step.erfolgschance {
                    Text("Erfolgschance: \(chance)%")
                        .font(.caption)
                        .foregroundColor(.yellow)
                }
                if let checkliste = step.checkliste, !checkliste.isEmpty {
                    Text("Checkliste: \(checkliste.joined(separator: ", "))")
                        .font(.caption)
                        .foregroundColor(secondaryTextColor)
                        .lineLimit(1)
                }
            }
        }
        .padding()
        .background(cardBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(accentColor, lineWidth: 1)
        )
        .opacity(0.2)
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
                if let category = erinnerung.kategorie {
                    Text("Kategorie: \(category)")
                        .font(.caption)
                        .foregroundColor(.yellow)
                }
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
                .stroke(accentColor, lineWidth: 1)
        )
        .opacity(0.2)
        .padding(.horizontal)
    }

    // Card für Hinweise
    private func NoteCard(hinweis: Note) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "note.text")
                .foregroundColor(accentColor)
                .font(.system(size: 20))
            VStack(alignment: .leading, spacing: 6) {
                Text(hinweis.beschreibung)
                    .font(.body)
                    .foregroundColor(textColor)
                    .lineLimit(3)
                if let docs = hinweis.vereinsDokumente, !docs.isEmpty {
                    Text("Dokumente: \(docs.joined(separator: ", "))")
                        .font(.caption)
                        .foregroundColor(.yellow)
                        .lineLimit(1)
                }
            }
            Spacer()
        }
        .padding()
        .background(cardBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(accentColor, lineWidth: 1)
        )
        .opacity(0.2)
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
                transferProcessViewModel.updateTransferProcessLocally(transferProcess)
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

    // Farben für das dunkle Design (definiert in Extensions.swift)
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
                .stroke(accentColor, lineWidth: 1)
        )
        .opacity(0.2)
        .padding(.horizontal)
    }

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
}

#Preview {
    TransferProcessDetailView(
        transferProcess: TransferProcess(
            id: "1",
            clientID: "client1",
            vereinID: "club1",
            status: "in Bearbeitung",
            startDatum: Date(),
            schritte: [
                Step(typ: "Kontaktaufnahme", status: "abgeschlossen", datum: Date(), erfolgschance: 80, checkliste: ["Gehalt abfragen"])
            ],
            erinnerungen: [
                Reminder(datum: Date().addingTimeInterval(86400), beschreibung: "Nachfragen", kategorie: "nachfrageErinnerung")
            ],
            hinweise: [
                Note(beschreibung: "Verein interessiert", vereinsDokumente: ["doc1.pdf"])
            ],
            mitarbeiterID: "mitarbeiter_a",
            priority: 2
        )
    )
    .environmentObject(AuthManager())
    .environmentObject(TransferProcessViewModel(authManager: AuthManager()))
}
