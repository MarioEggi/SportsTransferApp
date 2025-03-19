import SwiftUI
import FirebaseFirestore

struct ClientContactView: View {
    @ObservedObject var authManager: AuthManager
    @Binding var isPresented: Bool // Bindung zum Steuern des Sheets
    @State private var clients: [Client] = []
    @State private var selectedClient: Client?
    @State private var searchText: String = ""
    @State private var contactType: String = "Telefon"
    @State private var contactTopic: String = "Besuch"
    @State private var notes: String = ""
    @State private var errorMessage: String = ""
    @Environment(\.dismiss) var dismiss

    let contactTypes = ["Telefon", "Email", "Videocall", "Treffen"]
    let contactTopics = ["Besuch", "Coaching", "Vertrag", "Problem", "Analyse", "Sonstiges"]

    var filteredClients: [Client] {
        if searchText.isEmpty {
            return clients
        } else {
            return clients.filter { client in
                "\(client.vorname) \(client.name)".lowercased().contains(searchText.lowercased())
            }
        }
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Klient auswählen")) {
                    TextField("Suche nach Name", text: $searchText)
                    Picker("Klient", selection: $selectedClient) {
                        Text("Kein Klient ausgewählt").tag(Client?.none)
                        ForEach(filteredClients, id: \.self) { client in // id: \.self für Hashable
                            Text("\(client.vorname) \(client.name)")
                                .tag(client as Client?)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }

                Section(header: Text("Kontaktdetails")) {
                    Picker("Art des Kontakts", selection: $contactType) {
                        ForEach(contactTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())

                    Picker("Thema", selection: $contactTopic) {
                        ForEach(contactTopics, id: \.self) { topic in
                            Text(topic).tag(topic)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())

                    TextField("Notizen", text: $notes, axis: .vertical)
                        .lineLimit(5)
                }
            }
            .navigationTitle("Klienten Kontakt")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        isPresented = false // Synchroner Abbruch
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        Task {
                            await saveContact()
                            isPresented = false // Schließen nach erfolgreichem Speichern
                        }
                    }
                    .disabled(selectedClient == nil)
                }
            }
            .task {
                await loadClients()
            }
            .alert(isPresented: .constant(!errorMessage.isEmpty)) {
                Alert(title: Text("Fehler"), message: Text(errorMessage), dismissButton: .default(Text("OK")) {
                    errorMessage = ""
                })
            }
        }
    }

    private func loadClients() async {
        do {
            let loadedClients = try await FirestoreManager.shared.getClients()
            await MainActor.run {
                self.clients = loadedClients
            }
        } catch {
            await MainActor.run {
                errorMessage = "Fehler beim Laden der Klienten: \(error.localizedDescription)"
            }
        }
    }

    private func saveContact() async {
        guard let selectedClient = selectedClient, let employeeName = authManager.userEmail else {
            await MainActor.run {
                errorMessage = "Klient oder Mitarbeitername nicht verfügbar"
            }
            return
        }
        let activity = Activity(
            id: nil,
            clientID: selectedClient.id ?? UUID().uuidString,
            description: "\(contactType) - \(contactTopic): \(notes) (von \(employeeName))",
            timestamp: Date()
        )
        do {
            try await FirestoreManager.shared.createActivity(activity: activity)
            print("Kontakt erfolgreich gespeichert")
        } catch {
            await MainActor.run {
                errorMessage = "Fehler beim Speichern des Kontakts: \(error.localizedDescription)"
            }
        }
    }
}

#Preview {
    ClientContactView(authManager: AuthManager(), isPresented: .constant(true))
}
