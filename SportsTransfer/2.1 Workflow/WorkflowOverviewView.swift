import SwiftUI

struct WorkflowOverviewView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var viewModel = WorkflowViewModel()
    @State private var showingAddProcess = false
    @State private var selectedFilter: FilterOption = .all
    
    // Farben für dunkles Design
    private let backgroundColor = Color(hex: "#1C2526")
    private let cardBackgroundColor = Color(hex: "#2A3439")
    private let accentColor = Color(hex: "#00C4B4")
    private let textColor = Color(hex: "#E0E0E0")
    private let secondaryTextColor = Color(hex: "#B0BEC5")
    private let inactiveTabColor = Color(hex: "#FFFFFF")
    
    enum FilterOption: String, CaseIterable, Identifiable {
        case all = "Alle"
        case transfer = "Transfer"
        case sponsoring = "Sponsoring"
        case profile = "Profil-Anfragen"
        var id: String { rawValue }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundColor.edgesIgnoringSafeArea(.all)
                VStack(spacing: 0) {
                    headerView
                    filterView
                    processListView
                }
                .sheet(isPresented: $showingAddProcess) {
                    AddProcessView(onSave: {
                        Task {
                            await viewModel.loadProcesses()
                        }
                    })
                }
                .alert(isPresented: .constant(!viewModel.errorMessage.isEmpty)) {
                    Alert(
                        title: Text("Fehler").foregroundColor(textColor),
                        message: Text(viewModel.errorMessage).foregroundColor(secondaryTextColor),
                        dismissButton: .default(Text("OK").foregroundColor(accentColor)) { viewModel.errorMessage = "" }
                    )
                }
                .task {
                    await viewModel.loadProcesses()
                }
            }
        }
    }
    
    private var headerView: some View {
        HStack {
            Text("Workflow")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(textColor)
            Spacer()
            Button(action: { showingAddProcess = true }) {
                Image(systemName: "plus")
                    .foregroundColor(accentColor)
            }
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }
    
    private var filterView: some View {
        Picker("Filter", selection: $selectedFilter) {
            ForEach(FilterOption.allCases) { option in
                Text(option.rawValue)
                    .foregroundColor(inactiveTabColor)
                    .tag(option)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .padding(.bottom, 10)
    }
    
    private var processListView: some View {
        List {
            if viewModel.processes.isEmpty && !viewModel.isLoading {
                Text("Keine Prozesse vorhanden.")
                    .foregroundColor(secondaryTextColor)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowBackground(backgroundColor)
            } else {
                processItems
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .tint(accentColor)
                        .listRowBackground(backgroundColor)
                }
            }
        }
        .listStyle(PlainListStyle())
        .scrollContentBackground(.hidden)
        .background(backgroundColor)
        .padding(.horizontal)
    }
    
    private var processItems: some View {
        ForEach(filteredProcesses) { process in
            NavigationLink(destination: ProcessDetailView(process: process)) {
                ProcessRowView(process: process, isLast: process.id == filteredProcesses.last?.id)
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
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 3, leading: 13, bottom: 3, trailing: 13))
        }
    }
    
    private var filteredProcesses: [AnyProcess] {
        switch selectedFilter {
        case .all:
            return viewModel.processes
        case .transfer:
            return viewModel.processes.filter { $0.type == .transfer }
        case .sponsoring:
            return viewModel.processes.filter { $0.type == .sponsoring }
        case .profile:
            return viewModel.processes.filter { $0.type == .profile }
        }
    }
}

struct ProcessRowView: View {
    let process: AnyProcess
    let isLast: Bool
    @StateObject private var viewModel = WorkflowViewModel()
    
    private let textColor = Color(hex: "#E0E0E0")
    private let secondaryTextColor = Color(hex: "#B0BEC5")
    private let accentColor = Color(hex: "#00C4B4")
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: process.icon)
                .foregroundColor(process.color)
                .padding(.leading, -5)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(process.displayTitle)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(textColor)
                
                if let note = process.note {
                    Text(note)
                        .font(.subheadline)
                        .foregroundColor(secondaryTextColor)
                }
                
                Text("Status: \(process.status)")
                    .font(.caption)
                    .foregroundColor(secondaryTextColor)
            }
            Spacer()
            Text(process.priority.map { "Prio: \($0)" } ?? "")
                .font(.caption)
                .foregroundColor(accentColor)
        }
        .padding()
        .onAppear {
            if isLast {
                Task { await viewModel.loadProcesses(loadMore: true) }
            }
        }
    }
}

#Preview {
    WorkflowOverviewView()
        .environmentObject(AuthManager())
}
