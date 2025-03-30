import SwiftUI
import FirebaseFirestore
import EventKit
import UserNotifications

class TransferProcessViewModel: ObservableObject {
    @Published var transferProcesses: [TransferProcess] = []
    @Published var clients: [Client] = []
    @Published var clubs: [Club] = []
    @Published var funktionäre: [Funktionär] = []
    @Published var mitarbeiter: [String] = []
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var dueReminders: [Reminder] = []
    private var lastDocument: DocumentSnapshot?
    private let pageSize = 20
    private let authManager: AuthManager
    private var notificationTimer: Timer?

    // OpenAI API-Schlüssel
    private let openAIAPIKey = "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"
    private let openAIEndpoint = "https://api.openai.com/v1/chat/completions"

    init(authManager: AuthManager) {
        self.authManager = authManager
        Task { await loadInitialData() }
        setupNotificationTimer()
    }

    func loadInitialData() async {
        await MainActor.run { isLoading = true }
        do {
            let loadedClients: [Client]
            if authManager.userRole == .mitarbeiter {
                let (clients, _) = try await FirestoreManager.shared.getAllClients(lastDocument: nil, limit: 1000)
                loadedClients = clients
            } else if let userID = authManager.userID {
                let (clients, _) = try await FirestoreManager.shared.getClients(forUserID: userID, lastDocument: nil, limit: 1000)
                loadedClients = clients
            } else {
                loadedClients = []
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Benutzer-ID nicht verfügbar"])
            }

            let (loadedClubs, _) = try await FirestoreManager.shared.getClubs(lastDocument: nil, limit: 1000)
            let (loadedFunktionäre, _) = try await FirestoreManager.shared.getFunktionäre(lastDocument: nil, limit: 1000)
            let (loadedProcesses, _) = try await FirestoreManager.shared.getTransferProcesses(lastDocument: nil, limit: 1000)

            let mitarbeiterListe = loadedClients.compactMap { $0.createdBy }.uniqued()

            await MainActor.run {
                clients = loadedClients
                clubs = loadedClubs
                funktionäre = loadedFunktionäre
                transferProcesses = loadedProcesses
                mitarbeiter = mitarbeiterListe
                isLoading = false
                updateDueReminders()
            }
        } catch {
            await MainActor.run {
                errorMessage = "Fehler beim Laden der Initialdaten: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }

    func loadTransferProcesses(loadMore: Bool = false) async {
        await MainActor.run { isLoading = true }
        do {
            let (newProcesses, newLastDoc) = try await FirestoreManager.shared.getTransferProcesses(
                lastDocument: loadMore ? lastDocument : nil,
                limit: pageSize
            )
            await MainActor.run {
                if loadMore {
                    transferProcesses.append(contentsOf: newProcesses)
                } else {
                    transferProcesses = newProcesses
                }
                lastDocument = newLastDoc
                isLoading = false
                updateDueReminders()
            }
        } catch {
            await MainActor.run {
                errorMessage = "Fehler beim Laden der Transferprozesse: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }

    func saveTransferProcess(_ process: TransferProcess) async {
        do {
            if let id = process.id {
                try await FirestoreManager.shared.updateTransferProcess(transferProcess: process)
                updateTransferProcessLocally(process)
            } else {
                let newID = try await FirestoreManager.shared.createTransferProcess(transferProcess: process)
                var updatedProcess = process
                updatedProcess.id = newID
                await MainActor.run {
                    transferProcesses.append(updatedProcess)
                }
            }
            updateDueReminders()
            scheduleNotificationsForReminders(process.erinnerungen ?? [])
        } catch {
            await MainActor.run {
                errorMessage = "Fehler beim Speichern: \(error.localizedDescription)"
            }
        }
    }

    func deleteTransferProcess(_ process: TransferProcess) async {
        guard let id = process.id else { return }
        do {
            try await FirestoreManager.shared.deleteTransferProcess(id: id)
            await MainActor.run {
                transferProcesses.removeAll { $0.id == id }
                updateDueReminders()
            }
        } catch {
            await MainActor.run {
                errorMessage = "Fehler beim Löschen: \(error.localizedDescription)"
            }
        }
    }

    func updateTransferProcessLocally(_ process: TransferProcess) {
        if let index = transferProcesses.firstIndex(where: { $0.id == process.id }) {
            DispatchQueue.main.async {
                self.transferProcesses[index] = process
                self.updateDueReminders()
            }
        }
    }

    func generateEmail(for process: TransferProcess, step: Step, language: String = "Deutsch") async -> String {
        guard let client = clients.first(where: { $0.id == process.clientID }),
              let club = clubs.first(where: { $0.id == process.vereinID }) else {
            return "Daten nicht verfügbar"
        }

        let mitarbeiterName = process.mitarbeiterID ?? "Sports Transfer Team"
        let clientName = "\(client.vorname) \(client.name)"
        let clubName = club.name
        let dateStr = dateFormatter.string(from: step.datum)

        let prompt = """
        Erstelle eine kurze, professionelle E-Mail auf \(language) für einen Sport-Transferprozess. Die E-Mail richtet sich an einen Funktionär des Fußballvereins \(clubName) und beschreibt den aktuellen Stand einer Phase im potenziellen Wechsel oder der Vertragsverlängerung von \(clientName). Verwende eine höfliche, prägnante Sprache und folgende Struktur: kurze Einleitung, Status der Gespräche, Erfolgschancen, Checkliste, nächste Schritte, Hinweise, optionale Anhänge. Hier sind die Details (ignoriere "Keine" oder "Nicht angegeben", wenn nicht relevant):
        - Betreff: \(step.typ) für \(clientName) - \(clubName)
        - Status: Stand der Gespräche zum \(dateStr) (\(step.notizen ?? "Kein Recap verfügbar"))
        - Erfolgschancen: Kurze Einschätzung der Erfolgschancen (\(step.erfolgschance?.description ?? "Nicht angegeben"))
        - Checkliste: Bereits besprochene Punkte und offene Punkte (\(step.checkliste?.joined(separator: ", ") ?? "Keine"))
        - Nächste Schritte: Vorschlag für ein weiteres Gespräch im Zeitraum (\(process.erinnerungen?.min { $0.datum < $1.datum }?.beschreibung ?? "Kein Vorschlag") am \(process.erinnerungen?.min { $0.datum < $1.datum }.map { dateFormatter.string(from: $0.datum) } ?? "Nicht angegeben"))
        - Hinweise: Weitere Anmerkungen (\(process.hinweise?.map { $0.beschreibung }.joined(separator: "; ") ?? "Keine"))
        - Optionale Anhänge: Vereinsdokumente, Spieler-CV oder Videomaterial (\(process.hinweise?.flatMap { $0.vereinsDokumente ?? [] }.joined(separator: ", ") ?? "Keine") - biete drei Optionen zum Anklicken)
        Absender: \(mitarbeiterName), Kontakt: \(authManager.userEmail ?? "info@sportstransfer.com")
        """

        do {
            var request = URLRequest(url: URL(string: openAIEndpoint)!)
            request.httpMethod = "POST"
            request.setValue("Bearer \(openAIAPIKey)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let requestBody: [String: Any] = [
                "model": "gpt-4",
                "messages": [
                    ["role": "system", "content": "Du bist ein hilfreicher Assistent, der professionelle E-Mails erstellt."],
                    ["role": "user", "content": prompt]
                ],
                "max_tokens": 300,
                "temperature": 0.6
            ]
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(OpenAIResponse.self, from: data)
            return response.choices.first?.message.content ?? "Fehler bei der E-Mail-Generierung"
        } catch {
            print("Fehler beim API-Aufruf: \(error.localizedDescription)")
            return "Fehler beim Generieren der E-Mail: \(error.localizedDescription)"
        }
    }

    func addReminderToCalendar(reminder: Reminder, for process: TransferProcess) async throws {
        let eventStore = EKEventStore()
        let authorizationStatus = EKEventStore.authorizationStatus(for: .event)
        
        if authorizationStatus != .authorized {
            let granted = try await eventStore.requestAccess(to: .event)
            if !granted {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Kalenderzugriff verweigert"])
            }
        }

        let event = EKEvent(eventStore: eventStore)
        event.title = "Transferprozess: \(reminder.beschreibung)"
        event.startDate = reminder.datum
        event.endDate = reminder.datum.addingTimeInterval(3600)
        event.notes = """
        Transferprozess für \(clients.first { $0.id == process.clientID }?.name ?? "Unbekannt") -> \(clubs.first { $0.id == process.vereinID }?.name ?? "Unbekannt")
        Kategorie: \(reminder.kategorie ?? "Keine")
        """
        event.calendar = eventStore.defaultCalendarForNewEvents
        
        let alarm = EKAlarm(relativeOffset: -15 * 60)
        event.addAlarm(alarm)
        
        try eventStore.save(event, span: .thisEvent)
        print("Erinnerung zum Kalender hinzugefügt: \(reminder.beschreibung)")
    }

    private func scheduleNotificationsForReminders(_ reminders: [Reminder]) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Fehler bei der Berechtigungsanfrage für Benachrichtigungen: \(error.localizedDescription)")
                return
            }
            guard granted else { return }

            for reminder in reminders {
                let content = UNMutableNotificationContent()
                content.title = "Transferprozess Erinnerung"
                content.body = reminder.beschreibung
                content.sound = .default
                if let kategorie = reminder.kategorie {
                    content.subtitle = "Kategorie: \(kategorie)"
                }
                
                let triggerDate = Calendar.current.dateComponents(
                    [.year, .month, .day, .hour, .minute],
                    from: reminder.datum
                )
                let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
                
                let request = UNNotificationRequest(
                    identifier: reminder.id,
                    content: content,
                    trigger: trigger
                )
                
                UNUserNotificationCenter.current().add(request) { error in
                    if let error = error {
                        print("Fehler beim Planen der Benachrichtigung: \(error.localizedDescription)")
                    } else {
                        print("Benachrichtigung geplant für: \(reminder.beschreibung) am \(self.dateFormatter.string(from: reminder.datum))")
                    }
                }
            }
        }
    }

    private func setupNotificationTimer() {
        notificationTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            self.updateDueReminders()
            let now = Date()
            for reminder in self.dueReminders {
                if now >= reminder.datum {
                    self.scheduleNotificationsForReminders([reminder])
                }
            }
        }
    }

    private func updateDueReminders() {
        let today = Date()
        var allDueReminders: [Reminder] = []
        for process in transferProcesses {
            if let reminders = process.erinnerungen {
                let due = reminders.filter { Calendar.current.startOfDay(for: $0.datum) <= Calendar.current.startOfDay(for: today) }
                allDueReminders.append(contentsOf: due)
            }
        }
        DispatchQueue.main.async {
            self.dueReminders = allDueReminders.sorted { $0.datum < $1.datum }
        }
    }

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    deinit {
        notificationTimer?.invalidate()
    }
}

struct OpenAIResponse: Codable {
    let choices: [OpenAIChoice]
}

struct OpenAIChoice: Codable {
    let message: OpenAIMessage
}

struct OpenAIMessage: Codable {
    let content: String
}
