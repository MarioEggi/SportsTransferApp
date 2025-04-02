import SwiftUI
import FirebaseFirestore

struct ContractDetailView: View {
    let contract: Contract
    @EnvironmentObject var authManager: AuthManager
    @State private var showingEditSheet = false
    @State private var client: Client? = nil
    @State private var club: Club? = nil
    @State private var errorMessage = ""

    // Farben für das helle Design
    private let backgroundColor = Color(hex: "#F5F5F5")
    private let cardBackgroundColor = Color(hex: "#E0E0E0")
    private let accentColor = Color(hex: "#00C4B4")
    private let textColor = Color(hex: "#333333")
    private let secondaryTextColor = Color(hex: "#666666")

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 15) {
                    List {
                        Section(header: Text("Vertragsdetails").foregroundColor(textColor)) {
                            VStack(spacing: 10) {
                                if let client = client {
                                    labeledField(label: "Klient", value: "\(client.vorname) \(client.name)")
                                }
                                if let club = club {
                                    labeledField(label: "Verein", value: club.name)
                                }
                                labeledField(label: "Startdatum", value: dateFormatter.string(from: contract.startDatum))
                                if let endDatum = contract.endDatum {
                                    labeledField(label: "Enddatum", value: dateFormatter.string(from: endDatum))
                                }
                                if let gehalt = contract.gehalt {
                                    labeledField(label: "Gehalt", value: String(format: "%.2f €", gehalt))
                                }
                                if let vertragsdetails = contract.vertragsdetails {
                                    labeledField(label: "Details", value: vertragsdetails)
                                }
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
                    .foregroundColor(textColor)

                    if authManager.userRole == .mitarbeiter {
                        Button(action: { showingEditSheet = true }) {
                            Text("Bearbeiten")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(accentColor)
                                .foregroundColor(textColor)
                                .cornerRadius(10)
                        }
                        .padding()
                    }
                }
                .background(backgroundColor)
                .navigationTitle("Vertrag")
                .navigationBarTitleDisplayMode(.inline)
                .foregroundColor(textColor)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        if authManager.userRole == .mitarbeiter {
                            Button(action: { showingEditSheet = true }) {
                                Image(systemName: "pencil")
                                    .foregroundColor(accentColor)
                            }
                        }
                    }
                }
                .sheet(isPresented: $showingEditSheet) {
                    AddContractView(
                        contract: .constant(contract),
                        isEditing: true,
                        onSave: { _ in
                            showingEditSheet = false
                        },
                        onCancel: { showingEditSheet = false }
                    )
                }
                .alert(isPresented: .constant(!errorMessage.isEmpty)) {
                    Alert(
                        title: Text("Fehler").foregroundColor(textColor),
                        message: Text(errorMessage).foregroundColor(secondaryTextColor),
                        dismissButton: .default(Text("OK").foregroundColor(accentColor)) {
                            errorMessage = ""
                        }
                    )
                }
                .task {
                    await loadClientAndClub()
                }
            }
        }
    }

    private func labeledField(label: String, value: String?) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(secondaryTextColor)
            Spacer()
            Text(value ?? "Nicht angegeben")
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .foregroundColor(textColor)
        }
    }

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    private func loadClientAndClub() async {
        do {
            if let clientID = contract.clientID {
                let (clients, _) = try await FirestoreManager.shared.getClients(lastDocument: nil, limit: 1000)
                await MainActor.run {
                    self.client = clients.first { $0.id == clientID }
                }
            }
            if let vereinID = contract.vereinID {
                let (clubs, _) = try await FirestoreManager.shared.getClubs(lastDocument: nil, limit: 1000)
                await MainActor.run {
                    self.club = clubs.first { $0.name == vereinID }
                }
            }
        } catch {
            errorMessage = "Fehler beim Laden der Daten: \(error.localizedDescription)"
        }
    }
}

#Preview {
    ContractDetailView(contract: Contract(
        id: "1",
        clientID: "client1",
        vereinID: "Verein1",
        startDatum: Date(),
        endDatum: Date().addingTimeInterval(3600 * 24 * 365),
        gehalt: 50000.0,
        vertragsdetails: "Standardvertrag"
    ))
    .environmentObject(AuthManager())
}
