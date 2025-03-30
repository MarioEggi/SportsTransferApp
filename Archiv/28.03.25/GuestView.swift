import SwiftUI
import FirebaseFirestore

struct GuestView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var clientViewModel = ClientViewModel()
    @StateObject private var contractViewModel = ContractViewModel()
    @StateObject private var transferViewModel = TransferViewModel()
    @StateObject private var activityViewModel = ActivityViewModel()
    @State private var selectedTab = 0
    @State private var showingContactsSheet = false
    @State private var showingSearchSheet = false

    private var tabs: [(title: String, icon: String, view: AnyView)] {
        [
            ("Dashboard", "chart.bar", AnyView(DashboardView())),
            ("Klienten", "person.2", AnyView(ClientListView())),
            ("Verträge", "doc.text", AnyView(ContractListView())),
            ("Vereine", "building.2", AnyView(ClubListView())),
            ("Transfers", "arrow.left.arrow.right", AnyView(TransferListView())),
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
                                .foregroundColor(selectedTab == index ? .blue : .gray)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(selectedTab == index ? Color.blue.opacity(0.1) : Color.clear)
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .background(Color(.systemGray6))

            ZStack {
                ForEach(tabs.indices, id: \.self) { index in
                    tabs[index].view
                        .environmentObject(authManager)
                        .environmentObject(clientViewModel)
                        .environmentObject(contractViewModel)
                        .environmentObject(transferViewModel)
                        .environmentObject(activityViewModel)
                        .opacity(selectedTab == index ? 1 : 0)
                        .animation(.easeInOut(duration: 0.3), value: selectedTab)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

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
                .onDisappear { showingSearchSheet = false }
        }
        .sheet(isPresented: $showingContactsSheet) {
            ContactsView()
                .environmentObject(authManager)
                .onDisappear { showingContactsSheet = false }
        }
        .task {
            // Kein expliziter loadClients()-Aufruf nötig wegen Realtime-Listener
            await contractViewModel.loadContracts()
            await transferViewModel.loadTransfers()
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
                    .foregroundColor(selectedTab == 0 ? .blue : .gray)
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
                    .foregroundColor(selectedTab == tabs.count - 1 ? .blue : .gray)
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
