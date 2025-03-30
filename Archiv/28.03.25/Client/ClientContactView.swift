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
    @State private var errorQueue: [String] = [] // Warteschlange für Fehlermeldungen
    @State private var isShowingError = false
    @Environment(\.dismiss) var dismiss

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
                        ForEach(filteredClients, id: \.self) { client in
                            Text("\(client.vorname) \(client.name)")
                                .tag(client as Client?)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }

                Section(header: Text("Kontaktdetails")) {
                    Picker("Art des Kontakts", selection: $contactType) {
                        ForEach(Constants.contactTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())

                    Picker("Thema", selection: $contactTopic) {
                        ForEach(Constants.contactTopics, id: \.self) { topic in
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
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        Task {
                            await saveContact()
                            isPresented = false
                        }
                    }
                    .disabled(selectedClient == nil)
                }
            }
            .task {
                await loadClients()
            }
            .alert(isPresented: $isShowingError) {
                Alert(
                    title: Text("Fehler"),
                    message: Text(errorMessage),
                    dismissButton: .default(Text("OK")) {
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
import SwiftUI
import FirebaseFirestore

struct ClientDetailView: View {
    let client: Client
    @StateObject private var contractViewModel = ContractViewModel()
    @State private var isLoading = true

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let profilbildURL = client.profilbildURL, let url = URL(string: profilbildURL) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                    } placeholder: {
                        ProgressView()
                    }
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.gray)
                }

                Text("\(client.vorname) \(client.name)")
                    .font(.title)

                if let vereinID = client.vereinID {
                    Text("Verein: \(vereinID)")
                        .font(.headline)
                }

                if let geburtsdatum = client.geburtsdatum {
                    Text("Geburtsdatum: \(dateFormatter.string(from: geburtsdatum))")
                        .font(.subheadline)
                }

                if let groesse = client.groesse {
                    Text("Größe: \(groesse) cm")
                        .font(.subheadline)
                }

                if let nationalitaet = client.nationalitaet, !nationalitaet.isEmpty {
                    Text("Nationalität: \(nationalitaet.joined(separator: ", "))")
                        .font(.subheadline)
                }

                if let positionFeld = client.positionFeld, !positionFeld.isEmpty {
                    Text("Positionen: \(positionFeld.joined(separator: ", "))")
                        .font(.subheadline)
                }

                Section(header: Text("Vertrag").font(.headline)) {
                    if isLoading {
                        ProgressView("Lade Vertrag...")
                    } else if let contract = contractViewModel.contracts.first(where: { $0.clientID == client.id }) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Verein: \(contract.vereinID ?? "Kein Verein")")
                            Text("Start: \(dateFormatter.string(from: contract.startDatum))")
                            if let endDatum = contract.endDatum {
                                Text("Ende: \(dateFormatter.string(from: endDatum))")
                            }
                            if let gehalt = contract.gehalt {
                                Text("Gehalt: \(gehalt) €")
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    } else {
                        Text("Kein Vertrag vorhanden.")
                            .foregroundColor(.gray)
                    }
                }

                Spacer()
            }
            .padding()
            .navigationTitle("\(client.vorname) \(client.name)")
            .task {
                await loadContracts()
            }
            .alert(isPresented: Binding(
                get: { !contractViewModel.errorMessage.isEmpty },
                set: { newValue in
                    if !newValue {
                        contractViewModel.resetError() // Korrekt ohne $ aufgerufen
                    }
                }
            )) {
                Alert(
                    title: Text("Fehler"),
                    message: Text(contractViewModel.errorMessage),
                    dismissButton: .default(Text("OK")) {
                        contractViewModel.resetError() // Korrekt ohne $ aufgerufen
                    }
                )
            }
        }
    }

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    private func loadContracts() async {
        await contractViewModel.loadContracts()
        await MainActor.run {
            isLoading = false
        }
    }
}

#Preview {
    ClientDetailView(client: Client(
        id: "1",
        typ: "Spieler",
        name: "Müller",
        vorname: "Thomas",
        geschlecht: "männlich",
        vereinID: "Bayern Munich",
        nationalitaet: ["Deutschland"],
        geburtsdatum: Date().addingTimeInterval(-25 * 365 * 24 * 60 * 60)
    ))
}
