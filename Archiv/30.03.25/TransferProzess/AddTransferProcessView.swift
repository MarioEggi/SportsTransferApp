import SwiftUI
import FirebaseFirestore

struct AddTransferProcessView: View {
    @EnvironmentObject var viewModel: TransferProcessViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var clientID: String?
    @State private var vereinID: String?
    @State private var status: String = "in Bearbeitung"
    @State private var startDatum: Date = Date()
    @State private var priorität: String = "mittel"
    @State private var art: String = "Vereinswechsel"
    @State private var errorMessage: String = ""
    @State private var localClients: [Client] = []
    @State private var selectedParallelProcess: TransferProcess?

    // Farben für das dunkle Design
    private let backgroundColor = Color(hex: "#1C2526")
    private let cardBackgroundColor = Color(hex: "#2A3439")
    private let accentColor = Color(hex: "#00C4B4")
    private let textColor = Color(hex: "#E0E0E0")
    private let secondaryTextColor = Color(hex: "#B0BEC5")

    var parallelProcesses: [TransferProcess] {
        guard let selectedClientID = clientID else { return [] }
        return viewModel.transferProcesses.filter { $0.clientID == selectedClientID && $0.status == "in Bearbeitung" }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundColor.edgesIgnoringSafeArea(.all)

                ScrollView {
                    VStack(spacing: 16) {
                        // Titel
                        Text("Neuer Transferprozess")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(textColor)
                            .padding(.top, 16)

                        // Transferprozess Details
                        VStack(alignment: .leading, spacing: 12) {
                            // Klient
                            Picker("Klient", selection: $clientID) {
                                Text("Kein Klient ausgewählt").tag(String?.none)
                                ForEach(localClients.isEmpty ? viewModel.clients : localClients) { client in
                                    Text("\(client.vorname) \(client.name)").tag(client.id as String?)
                                }
                            }
                            .pickerStyle(.menu)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(cardBackgroundColor)
                            .foregroundColor(textColor)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .onChange(of: clientID) { _ in
                                selectedParallelProcess = nil
                            }

                            // Parallele Prozesse
                            if let selectedClientID = clientID, !parallelProcesses.isEmpty {
                                Menu {
                                    ForEach(parallelProcesses) { process in
                                        Button(action: {
                                            selectedParallelProcess = process
                                            vereinID = process.vereinID
                                            status = process.status
                                            startDatum = process.startDatum
                                            priorität = process.priorität ?? "mittel"
                                            art = process.art ?? "Vereinswechsel"
                                        }) {
                                            Text("Prozess vom \(dateFormatter.string(from: process.startDatum))")
                                        }
                                    }
                                } label: {
                                    Text(selectedParallelProcess != nil ? "Prozess vom \(dateFormatter.string(from: selectedParallelProcess!.startDatum))" : "Parallele Prozesse (\(parallelProcesses.count))")
                                        .foregroundColor(textColor)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 12)
                                        .background(cardBackgroundColor)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }

                            // Verein
                            Picker("Verein", selection: $vereinID) {
                                Text("Kein Verein ausgewählt").tag(String?.none)
                                ForEach(viewModel.clubs) { club in
                                    Text(club.name).tag(club.id as String?)
                                }
                            }
                            .pickerStyle(.menu)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(cardBackgroundColor)
                            .foregroundColor(textColor)
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                            // Status
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Status")
                                    .foregroundColor(secondaryTextColor)
                                    .font(.subheadline)
                                Picker("Status", selection: $status) {
                                    Text("In Bearbeitung").tag("in Bearbeitung")
                                    Text("Abgeschlossen").tag("abgeschlossen")
                                    Text("Abgebrochen").tag("abgebrochen")
                                }
                                .pickerStyle(.segmented)
                                .colorScheme(.dark) // Für dunkles Design
                            }

                            // Priorität
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Priorität")
                                    .foregroundColor(secondaryTextColor)
                                    .font(.subheadline)
                                Picker("Priorität", selection: $priorität) {
                                    Text("Hoch").tag("hoch")
                                    Text("Mittel").tag("mittel")
                                    Text("Niedrig").tag("niedrig")
                                }
                                .pickerStyle(.segmented)
                                .colorScheme(.dark)
                            }

                            // Art
                            Picker("Art", selection: $art) {
                                Text("Vereinswechsel").tag("Vereinswechsel")
                                Text("Vertragsverlängerung").tag("Vertragsverlängerung")
                            }
                            .pickerStyle(.menu)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(cardBackgroundColor)
                            .foregroundColor(textColor)
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                            // Startdatum
                            DatePicker("Startdatum", selection: $startDatum, displayedComponents: [.date])
                                .foregroundColor(textColor)
                                .accentColor(accentColor)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(cardBackgroundColor)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .padding()
                        .background(cardBackgroundColor)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(accentColor.opacity(0.2), lineWidth: 1)
                        )
                        .padding(.horizontal)

                        Spacer(minLength: 80) // Platz für die untere Leiste
                    }
                    .padding(.bottom, 16)
                }
            }
            .ignoresSafeArea(.all, edges: .bottom)
            .navigationTitle("Neuer Transferprozess")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        Text("Abbrechen")
                            .foregroundColor(accentColor)
                            .font(.system(size: 16, weight: .medium))
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { saveTransferProcess() }) {
                        Text("Speichern")
                            .foregroundColor(clientID == nil || vereinID == nil ? secondaryTextColor : accentColor)
                            .font(.system(size: 16, weight: .medium))
                    }
                    .disabled(clientID == nil || vereinID == nil)
                }
            }
            .alert(isPresented: .constant(!errorMessage.isEmpty)) {
                Alert(
                    title: Text("Fehler").foregroundColor(textColor),
                    message: Text(errorMessage).foregroundColor(secondaryTextColor),
                    dismissButton: .default(Text("OK").foregroundColor(accentColor)) { errorMessage = "" }
                )
            }
            .onAppear {
                Task {
                    if viewModel.clients.isEmpty || viewModel.clubs.isEmpty {
                        await viewModel.loadTransferProcesses()
                        await MainActor.run {
                            localClients = viewModel.clients
                        }
                    }
                }
            }
        }
    }

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    private func saveTransferProcess() {
        guard let clientID = clientID, let vereinID = vereinID else {
            errorMessage = "Bitte wählen Sie einen Klienten und einen Verein aus."
            return
        }

        let newProcess = TransferProcess(
            id: selectedParallelProcess?.id,
            clientID: clientID,
            vereinID: vereinID,
            status: status,
            startDatum: startDatum,
            schritte: selectedParallelProcess?.schritte ?? [],
            erinnerungen: selectedParallelProcess?.erinnerungen,
            hinweise: selectedParallelProcess?.hinweise,
            transferDetails: selectedParallelProcess?.transferDetails,
            art: art,
            priorität: priorität
        )

        Task {
            await viewModel.saveTransferProcess(newProcess)
            dismiss()
        }
    }
}

#Preview {
    AddTransferProcessView()
        .environmentObject(TransferProcessViewModel(authManager: AuthManager()))
}
