import SwiftUI

struct TransferProcessListView: View {
    @ObservedObject var viewModel: TransferProcessViewModel
    @State private var filterMitarbeiter: String? = nil
    @State private var filterPriorität: String? = nil
    @State private var showingAddTransferSheet = false

    // Farben für das dunkle Design
    private let backgroundColor = Color(hex: "#1C2526") // Dunkles Grau/Schwarz
    private let cardBackgroundColor = Color(hex: "#2A3439") // Etwas helleres Grau für Karten
    private let accentColor = Color(hex: "#00C4B4") // Türkis als Akzentfarbe
    private let textColor = Color(hex: "#E0E0E0") // Helles Grau für Text
    private let secondaryTextColor = Color(hex: "#B0BEC5") // Etwas dunkleres Grau für sekundären Text

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundColor.edgesIgnoringSafeArea(.all)

                VStack(spacing: 0) {
                    // Filter
                    HStack(spacing: 12) {
                        // Mitarbeiter-Filter
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

                        // Priorität-Filter
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

                    // Liste der Transferprozesse
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

    // Custom Card für jeden Transferprozess
    private func TransferProcessCard(process: TransferProcess) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Klient und Verein
            Text("Klient: \(viewModel.clients.first { $0.id == process.clientID }?.name ?? "Unbekannt")")
                .foregroundColor(textColor)
                .font(.headline)
            Text("Verein: \(viewModel.clubs.first { $0.id == process.vereinID }?.name ?? "Unbekannt")")
                .foregroundColor(secondaryTextColor)
                .font(.subheadline)

            // Status und Priorität
            HStack {
                Text("Status: \(process.status)")
                    .foregroundColor(secondaryTextColor)
                    .font(.subheadline)
                Spacer()
                if let priorität = process.priorität {
                    Text("Priorität: \(priorität.capitalized)")
                        .foregroundColor(prioritätColor(priorität))
                        .font(.subheadline)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(prioritätColor(priorität).opacity(0.2))
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
            filtered = filtered.filter { $0.priorität == priorität }
        }
        return filtered.sorted { ($0.priorität ?? "niedrig") > ($1.priorität ?? "niedrig") }
    }

    private func prioritätColor(_ priorität: String) -> Color {
        switch priorität.lowercased() {
        case "hoch": return .red
        case "mittel": return .yellow
        case "niedrig": return .green
        default: return .gray
        }
    }
}

// Erweiterung für Hex-Farben
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
