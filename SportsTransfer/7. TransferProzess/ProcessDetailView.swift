import SwiftUI

struct ProcessDetailView: View {
    let process: AnyProcess
    @StateObject private var viewModel: TransferProcessViewModel
    @Environment(\.dismiss) var dismiss
    
    // Farben für helles Design
    private let backgroundColor = Color(hex: "#F5F5F5")
    private let cardBackgroundColor = Color(hex: "#E0E0E0")
    private let accentColor = Color(hex: "#00C4B4")
    private let textColor = Color(hex: "#333333")
    private let secondaryTextColor = Color(hex: "#666666")
    
    init(process: AnyProcess) {
        self.process = process
        self._viewModel = StateObject(wrappedValue: TransferProcessViewModel(authManager: AuthManager()))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundColor.edgesIgnoringSafeArea(.all)
                List {
                    Section(header: Text("Prozessdetails").foregroundColor(textColor)) {
                        HStack {
                            Text("Titel:")
                                .foregroundColor(textColor)
                            Spacer()
                            Text(process.displayTitle)
                                .foregroundColor(secondaryTextColor)
                        }
                        HStack {
                            Text("Status:")
                                .foregroundColor(textColor)
                            Spacer()
                            Text(process.status)
                                .foregroundColor(secondaryTextColor)
                        }
                        if let priority = process.priority {
                            HStack {
                                Text("Priorität:")
                                    .foregroundColor(textColor)
                                Spacer()
                                Text("\(priority)")
                                    .foregroundColor(secondaryTextColor)
                            }
                        }
                        if let note = process.note {
                            HStack {
                                Text("Notiz:")
                                    .foregroundColor(textColor)
                                Spacer()
                                Text(note)
                                    .foregroundColor(secondaryTextColor)
                            }
                        }
                    }
                    .listRowBackground(cardBackgroundColor)
                }
                .listStyle(PlainListStyle())
                .scrollContentBackground(.hidden)
                .background(backgroundColor)
                .navigationTitle("Prozessdetails")
                .foregroundColor(textColor)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Zurück") { dismiss() }
                            .foregroundColor(accentColor)
                    }
                }
            }
            .onAppear {
                Task {
                    await viewModel.loadTransferProcesses()
                }
            }
        }
    }
}

struct ProcessDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleTransfer = TransferProcess(clientID: "client1", vereinID: "club1")
        let sampleProcess = AnyProcess(
            transfer: sampleTransfer,
            clients: [Client(id: "client1", typ: "Spieler", name: "Mustermann", vorname: "Max", geschlecht: "männlich")],
            clubs: [Club(id: "club1", name: "FC Example")]
        )
        ProcessDetailView(process: sampleProcess)
    }
}
