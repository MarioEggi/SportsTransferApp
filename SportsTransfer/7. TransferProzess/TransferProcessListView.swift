import SwiftUI

struct TransferProcessListView: View {
    @ObservedObject var viewModel: TransferProcessViewModel
    @State private var filterMitarbeiter: String? = nil
    @State private var filterPriorität: String? = nil
    @State private var showingAddTransferSheet = false
    
    // Farben für das dunkle Design
    private let backgroundColor = Color(hex: "#1C2526")
    private let cardBackgroundColor = Color(hex: "#2A3439")
    private let accentColor = Color(hex: "#00C4B4")
    private let textColor = Color(hex: "#E0E0E0")
    private let secondaryTextColor = Color(hex: "#B0BEC5")
    
    var filteredTransferProcesses: [TransferProcess] {
        var filtered = viewModel.transferProcesses
        if let mitarbeiterID = filterMitarbeiter {
            filtered = filtered.filter { process in
                process.mitarbeiterID == mitarbeiterID
            }
        }
        if let priorität = filterPriorität {
            filtered = filtered.filter { process in
                process.priority.map { priorityToString($0) } == priorität
            }
        }
        return filtered.sorted { (p1, p2) in
            let priority1 = p1.priority ?? 0
            let priority2 = p2.priority ?? 0
            return priority1 > priority2
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundColor.edgesIgnoringSafeArea(.all)
                VStack(spacing: 0) {
                    filterView
                    processListView
                }
            }
            .navigationTitle("Transferprozesse")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingAddTransferSheet = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(accentColor)
                            .font(.system(size: 20, weight: .medium))
                    }
                }
            }
            .sheet(isPresented: $showingAddTransferSheet) {
                AddProcessView(onSave: {
                    Task {
                        await viewModel.loadTransferProcesses()
                    }
                })
                .environmentObject(viewModel)
            }
            .task {
                await viewModel.loadTransferProcesses()
                print("TransferProcesses: \(viewModel.transferProcesses.count), Clients: \(viewModel.clients.count), Clubs: \(viewModel.clubs.count)")
            }
        }
    }
    
    private var filterView: some View {
        HStack(spacing: 12) {
            Picker("Mitarbeiter", selection: $filterMitarbeiter) {
                Text("Alle").tag(String?.none)
                ForEach(viewModel.mitarbeiter, id: \.self) { mitarbeiter in
                    Text(mitarbeiter)
                        .tag(mitarbeiter as String?)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(cardBackgroundColor)
            .foregroundColor(textColor)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            Picker("Priorität", selection: $filterPriorität) {
                Text("Alle").tag(String?.none)
                Text("Hoch").tag(String?.some("hoch"))
                Text("Mittel").tag(String?.some("mittel"))
                Text("Niedrig").tag(String?.some("niedrig"))
            }
            .pickerStyle(MenuPickerStyle())
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(cardBackgroundColor)
            .foregroundColor(textColor)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private var processListView: some View {
        ScrollView {
            VStack(spacing: 12) {
                if filteredTransferProcesses.isEmpty {
                    Text("Keine Transferprozesse vorhanden.")
                        .foregroundColor(secondaryTextColor)
                        .font(.subheadline)
                        .padding(.top, 20)
                } else {
                    processItems
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
    }
    
    private var processItems: some View {
        ForEach(filteredTransferProcesses) { process in
            NavigationLink(destination: ProcessDetailView(process: AnyProcess(transfer: process, clients: viewModel.clients, clubs: viewModel.clubs))) {
                TransferProcessCard(process: process)
            }
        }
    }
    
    private func TransferProcessCard(process: TransferProcess) -> some View {
        let clientName = viewModel.clients.first { $0.id == process.clientID }?.name ?? "Unbekannt"
        let clubName = viewModel.clubs.first { $0.id == process.vereinID }?.name ?? "Unbekannt"
        let priorityText = process.priority.map { "Priorität: \(priorityToString($0))" } ?? "Priorität: Unbekannt"
        let priorityColorValue = process.priority.map { priorityColor($0) } ?? .gray
        
        return VStack(alignment: .leading, spacing: 8) {
            Text("Klient: \(clientName)")
                .foregroundColor(textColor)
                .font(.headline)
            Text("Verein: \(clubName)")
                .foregroundColor(secondaryTextColor)
                .font(.subheadline)
            
            HStack {
                Text("Status: \(process.status)")
                    .foregroundColor(secondaryTextColor)
                    .font(.subheadline)
                Spacer()
                Text(priorityText)
                    .foregroundColor(priorityColorValue)
                    .font(.subheadline)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(priorityColorValue.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
        }
        .padding()
        .background(cardBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(accentColor.opacity(0.2), lineWidth: 1)
        )
    }
    
    private func priorityToString(_ priority: Int) -> String {
        switch priority {
        case 1..<3: return "niedrig"
        case 3..<5: return "mittel"
        case 5: return "hoch"
        default: return "niedrig"
        }
    }
    
    private func priorityColor(_ priority: Int) -> Color {
        switch priority {
        case 1..<3: return .green
        case 3..<5: return .yellow
        case 5: return .red
        default: return .gray
        }
    }
}

#Preview {
    TransferProcessListView(viewModel: TransferProcessViewModel(authManager: AuthManager()))
        .environmentObject(AuthManager())
}
