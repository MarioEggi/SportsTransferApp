import SwiftUI
import FirebaseFirestore

struct ClientContactView: View {
    @ObservedObject var authManager: AuthManager
    @Binding var isPresented: Bool
    @State private var clients: [Client] = []
    @State private var selectedClient: Client?
    @State private var searchText: String = ""
    @State private var contactType: String = "Telefon"
    @State private var contactTopic: String = "Besuch"
    @State private var notes: String = ""
    @State private var errorMessage: String = ""
    @State private var errorQueue: [String] = []
    @State private var isShowingError = false
    @Environment(\.dismiss) var dismiss

    // Farben für das dunkle Design
    private let backgroundColor = Color(hex: "#1C2526")
    private let cardBackgroundColor = Color(hex: "#2A3439")
    private let accentColor = Color(hex: "#00C4B4")
    private let textColor = Color(hex: "#E0E0E0")
    private let secondaryTextColor = Color(hex: "#B0BEC5")

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
            ZStack {
                backgroundColor.edgesIgnoringSafeArea(.all)
                Form {
                    clientSelectionSection
                    contactDetailsSection
                }
                .scrollContentBackground(.hidden)
                .background(backgroundColor)
                .navigationTitle("Klienten Kontakt")
                .foregroundColor(textColor)
                .toolbar { toolbarContent }
                .task {
                    await loadClients()
                }
                .alert(isPresented: $isShowingError) {
                    Alert(
                        title: Text("Fehler").foregroundColor(textColor),
                        message: Text(errorMessage).foregroundColor(secondaryTextColor),
                        dismissButton: .default(Text("OK").foregroundColor(accentColor)) {
                            if !errorQueue.isEmpty {
                                errorMessage = errorQueue.removeFirst()
                                isShowingError = true
                            } else {
                                isShowingError = false
                            }
                        }
                    )
                }
            }
        }
    }

    // Sub-Views

    private var clientSelectionSection: some View {
        Section(header: Text("Klient auswählen").foregroundColor(textColor)) {
            TextField("Suche nach Name", text: $searchText)
                .foregroundColor(textColor)
                .background(cardBackgroundColor)
                .cornerRadius(8)
            Picker("Klient", selection: $selectedClient) {
                Text("Kein Klient ausgewählt").tag(Client?.none)
                ForEach(filteredClients, id: \.self) { client in
                    Text("\(client.vorname) \(client.name)")
                        .tag(client as Client?)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .foregroundColor(textColor)
            .accentColor(accentColor)
        }
    }

    private var contactDetailsSection: some View {
        Section(header: Text("Kontaktdetails").foregroundColor(textColor)) {
            Picker("Art des Kontakts", selection: $contactType) {
                ForEach(Constants.contactTypes, id: \.self) { type in
                    Text(type).tag(type)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .foregroundColor(textColor)
            .accentColor(accentColor)

            Picker("Thema", selection: $contactTopic) {
                ForEach(Constants.contactTopics, id: \.self) { topic in
                    Text(topic).tag(topic)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .foregroundColor(textColor)
            .accentColor(accentColor)

            TextField("Notizen", text: $notes, axis: .vertical)
                .lineLimit(5)
                .foregroundColor(textColor)
                .background(cardBackgroundColor)
                .cornerRadius(8)
        }
    }

    private var toolbarContent: some ToolbarContent {
        Group {
            ToolbarItem(placement: .cancellationAction) {
                Button("Abbrechen") {
                    isPresented = false
                }
                .foregroundColor(accentColor)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Speichern") {
                    Task {
                        await saveContact()
                        isPresented = false
                    }
                }
                .disabled(selectedClient == nil)
                .foregroundColor(accentColor)
            }
        }
    }

    private func loadClients() async {
        do {
            let (loadedClients, _) = try await FirestoreManager.shared.getClients(limit: 1000)
            await MainActor.run {
                self.clients = loadedClients
                print("Geladene Klienten in ClientContactView: \(loadedClients.count), IDs: \(loadedClients.map { $0.id ?? "unbekannt" })")
            }
        } catch {
            await MainActor.run {
                addErrorToQueue("Fehler beim Laden der Klienten: \(error.localizedDescription)")
            }
        }
    }

    private func saveContact() async {
        guard let selectedClient = selectedClient, let employeeName = authManager.userEmail else {
            await MainActor.run {
                addErrorToQueue("Klient oder Mitarbeitername nicht verfügbar")
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
                addErrorToQueue("Fehler beim Speichern des Kontakts: \(error.localizedDescription)")
            }
        }
    }

    private func addErrorToQueue(_ message: String) {
        errorQueue.append(message)
        if !isShowingError {
            errorMessage = errorQueue.removeFirst()
            isShowingError = true
        }
    }
}

#Preview {
    ClientContactView(
        authManager: AuthManager(),
        isPresented: .constant(true)
    )
}
