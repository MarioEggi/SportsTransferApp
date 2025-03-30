import SwiftUI
import FirebaseFirestore

struct GuestView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var clientViewModel: ClientViewModel
    @StateObject private var contractViewModel = ContractViewModel()
    @StateObject private var transferProcessViewModel: TransferProcessViewModel
    @StateObject private var activityViewModel = ActivityViewModel()
    @State private var selectedTab = 0
    @State private var showingContactsSheet = false
    @State private var showingSearchSheet = false

    init() {
        _clientViewModel = StateObject(wrappedValue: ClientViewModel(authManager: AuthManager()))
        _transferProcessViewModel = StateObject(wrappedValue: TransferProcessViewModel(authManager: AuthManager()))
    }

    private var tabs: [(title: String, icon: String, view: AnyView)] {
        [
            ("Dashboard", "chart.bar", AnyView(DashboardView())),
            ("Klienten", "person.2", AnyView(ClientListView())),
            ("Verträge", "doc.text", AnyView(ContractListView())),
            ("Vereine", "building.2", AnyView(ClubListView())),
            ("Transfers", "arrow.left.arrow.right", AnyView(TransferProcessListView(viewModel: transferProcessViewModel))), // Platzhalter ersetzt
            ("Spiele", "sportscourt", AnyView(MatchListView())),
            ("Sponsoren", "dollarsign.circle", AnyView(SponsorListView())),
            ("Funktionäre", "person.badge.key", AnyView(FunktionärListView())),
            ("Chat", "bubble.left", AnyView(ChatView()))
        ]
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(tabs.indices, id: \.self) { index in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                selectedTab = index
                            }
                        }) {
                            Label(tabs[index].title, systemImage: tabs[index].icon)
                                .foregroundColor(selectedTab == index ? .white : .gray)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(selectedTab == index ? Color.gray.opacity(0.2) : Color.clear)
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .background(Color.black)

            ZStack {
                ForEach(tabs.indices, id: \.self) { index in
                    tabs[index].view
                        .environmentObject(authManager)
                        .environmentObject(clientViewModel)
                        .environmentObject(contractViewModel)
                        .environmentObject(transferProcessViewModel)
                        .environmentObject(activityViewModel)
                        .opacity(selectedTab == index ? 1 : 0)
                        .animation(.easeInOut(duration: 0.3), value: selectedTab)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)

            Spacer()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { authManager.signOut() }) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .foregroundColor(.red)
                }
            }
        }
        .overlay(customBar, alignment: .bottom)
        .sheet(isPresented: $showingSearchSheet) {
            Text("Appübergreifende Suche (Platzhalter)")
                .foregroundColor(.white)
                .background(Color.black)
                .onDisappear { showingSearchSheet = false }
        }
        .sheet(isPresented: $showingContactsSheet) {
            ContactsView()
                .environmentObject(authManager)
                .onDisappear { showingContactsSheet = false }
        }
        .task {
            await contractViewModel.loadContracts()
            await transferProcessViewModel.loadTransferProcesses()
            await activityViewModel.loadActivities()
        }
    }

    private var customBar: some View {
        VStack {
            Spacer()
            HStack(spacing: 0) {
                Button(action: { withAnimation(.easeInOut(duration: 0.3)) { selectedTab = 0 } }) {
                    VStack {
                        Image(systemName: "house")
                            .font(.title2)
                        Text("Home")
                            .font(.caption)
                            .lineLimit(1)
                    }
                    .foregroundColor(selectedTab == 0 ? .white : .gray)
                    .frame(maxWidth: .infinity)
                }

                Button(action: { showingSearchSheet = true }) {
                    VStack {
                        Image(systemName: "magnifyingglass")
                            .font(.title2)
                        Text("Suche")
                            .font(.caption)
                            .lineLimit(1)
                    }
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                }

                Button(action: { withAnimation(.easeInOut(duration: 0.3)) { selectedTab = tabs.count - 1 } }) {
                    VStack {
                        Image(systemName: "bubble.left")
                            .font(.title2)
                        Text("Chat")
                            .font(.caption)
                            .lineLimit(1)
                    }
                    .foregroundColor(selectedTab == tabs.count - 1 ? .white : .gray)
                    .frame(maxWidth: .infinity)
                }

                Button(action: { showingContactsSheet = true }) {
                    VStack {
                        Image(systemName: "person.2.fill")
                            .font(.title2)
                        Text("Kontakte")
                            .font(.caption)
                            .lineLimit(1)
                    }
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 70)
            .background(Color.black)
            .foregroundColor(.white)
        }
    }
}

#Preview {
    GuestView()
        .environmentObject(AuthManager())
}
