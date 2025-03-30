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

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundColor.edgesIgnoringSafeArea(.all)

                VStack(spacing: 0) {
                    // Filter
                    HStack(spacing: 12) {
                        Picker("Mitarbeiter", selection: $filterMitarbeiter) {
                            Text("Alle").tag(String?.none)
                            ForEach(viewModel.funktionäre) { funktionär in
                                Text("\(funktionär.vorname) \(funktionär.name)")
                                    .tag(String?.some(funktionär.id!))
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

                    ScrollView {
                        VStack(spacing: 12) {
                            if filteredTransferProcesses.isEmpty {
                                Text("Keine Transferprozesse vorhanden.")
                                    .foregroundColor(secondaryTextColor)
                                    .font(.subheadline)
                                    .padding(.top, 20)
                            } else {
                                ForEach(filteredTransferProcesses) { process in
                                    NavigationLink(destination: TransferProcessDetailView(transferProcess: process)) {
                                        TransferProcessCard(process: process)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }
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
                AddTransferProcessView()
                    .environmentObject(viewModel)
            }
            .task {
                await viewModel.loadTransferProcesses()
                print("TransferProcesses: \(viewModel.transferProcesses.count), Clients: \(viewModel.clients.count), Clubs: \(viewModel.clubs.count)")
            }
        }
    }

    private func TransferProcessCard(process: TransferProcess) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Klient: \(viewModel.clients.first { $0.id == process.clientID }?.name ?? "Unbekannt")")
                .foregroundColor(textColor)
                .font(.headline)
            Text("Verein: \(viewModel.clubs.first { $0.id == process.vereinID }?.name ?? "Unbekannt")")
                .foregroundColor(secondaryTextColor)
                .font(.subheadline)

            HStack {
                Text("Status: \(process.status)")
                    .foregroundColor(secondaryTextColor)
                    .font(.subheadline)
                Spacer()
                if let priority = process.priority {
                    Text("Priorität: \(priorityToString(priority))")
                        .foregroundColor(priorityColor(priority))
                        .font(.subheadline)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(priorityColor(priority).opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
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
    }

    private var filteredTransferProcesses: [TransferProcess] {
        var filtered = viewModel.transferProcesses
        if let mitarbeiterID = filterMitarbeiter {
            filtered = filtered.filter { process in
                viewModel.clients.first { $0.id == process.clientID }?.createdBy == mitarbeiterID
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
