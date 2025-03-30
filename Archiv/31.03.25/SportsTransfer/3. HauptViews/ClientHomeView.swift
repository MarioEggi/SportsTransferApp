    import SwiftUI
    import FirebaseFirestore

    struct ClientHomeView: View {
        @EnvironmentObject var authManager: AuthManager
        @StateObject private var clientViewModel: ClientViewModel
        @StateObject private var contractViewModel = ContractViewModel()
        @State private var diaryEntries: [DiaryEntry] = []
        @State private var errorMessage = ""
        @State private var isLoading = true
        @State private var selectedTab = 0
        @State private var showingLeadSheet = false
        @State private var showingSearchSheet = false
        @State private var showingContactsSheet = false

        init() {
            _clientViewModel = StateObject(wrappedValue: ClientViewModel(authManager: AuthManager()))
        }

        private var tabs: [(title: String, icon: String, view: AnyView)] {
            [
                ("Home", "house", AnyView(ClientHomeDashboardView(
                    client: clientViewModel.clients.first(where: { $0.userID == authManager.userID }),
                    clientViewModel: clientViewModel,
                    sendEmergencyAlert: sendEmergencyAlert
                ))),
                ("Chat", "bubble.left", AnyView(ChatView())),
                ("Tagebuch", "book.fill", AnyView(DiaryView(diaryEntries: $diaryEntries, saveDiaryEntry: saveDiaryEntry)))
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
                                    .foregroundColor(selectedTab == index ? .white : .gray) // Weiße Schrift bei Auswahl
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(selectedTab == index ? Color.gray.opacity(0.2) : Color.clear) // Dunklerer Hintergrund bei Auswahl
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .background(Color.black) // Schwarzer Hintergrund für die Tab-Leiste

                ZStack {
                    ForEach(tabs.indices, id: \.self) { index in
                        tabs[index].view
                            .environmentObject(authManager)
                            .opacity(selectedTab == index ? 1 : 0)
                            .animation(.easeInOut(duration: 0.3), value: selectedTab)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black) // Schwarzer Hintergrund für die Inhalte

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
            .sheet(isPresented: $showingLeadSheet) {
                ClientContactView(authManager: authManager, isPresented: $showingLeadSheet)
            }
            .sheet(isPresented: $showingSearchSheet) {
                Text("Appübergreifende Suche (Platzhalter)")
                    .foregroundColor(.white) // Weiße Schrift
                    .background(Color.black) // Schwarzer Hintergrund
                    .onDisappear { showingSearchSheet = false }
            }
            .sheet(isPresented: $showingContactsSheet) {
                ContactsView()
                    .environmentObject(authManager)
                    .onDisappear { showingContactsSheet = false }
            }
            .alert(isPresented: .constant(!errorMessage.isEmpty)) {
                Alert(
                    title: Text("Fehler").foregroundColor(.white),
                    message: Text(errorMessage).foregroundColor(.white),
                    dismissButton: .default(Text("OK").foregroundColor(.white)) { errorMessage = "" }
                )
            }
            .task {
                await loadClientData()
                await loadDiaryEntries()
            }
            .background(Color.black) // Schwarzer Hintergrund für die gesamte View
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
                        .foregroundColor(selectedTab == 0 ? .white : .gray) // Weiße Schrift bei Auswahl
                        .frame(maxWidth: .infinity)
                    }

                    Menu {
                        Button(action: { showingLeadSheet = true }) {
                            Label("Kontakt aufnehmen", systemImage: "envelope")
                                .foregroundColor(.white) // Weiße Schrift
                        }
                    } label: {
                        VStack {
                            Image(systemName: "plus.circle")
                                .font(.title2)
                            Text("Create")
                                .font(.caption)
                                .lineLimit(1)
                        }
                        .foregroundColor(.white) // Weiße Schrift
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

                    Button(action: { withAnimation(.easeInOut(duration: 0.3)) { selectedTab = 1 } }) {
                        VStack {
                            Image(systemName: "bubble.left")
                                .font(.title2)
                            Text("Chat")
                                .font(.caption)
                                .lineLimit(1)
                        }
                        .foregroundColor(selectedTab == 1 ? .white : .gray) // Weiße Schrift bei Auswahl
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
                .background(Color.black) // Schwarzer Hintergrund für die Leiste
                .foregroundColor(.white) // Weiße Schrift und Symbole
            }
        }

        private func loadClientData() async {
            guard let userID = authManager.userID else {
                await MainActor.run {
                    errorMessage = "Nicht angemeldet"
                    isLoading = false
                }
                return
            }
            await clientViewModel.loadClients(userID: userID, loadMore: false)
            await contractViewModel.loadContracts()
            await MainActor.run {
                isLoading = false
                if clientViewModel.clients.first(where: { $0.userID == userID }) == nil {
                    errorMessage = "Kein Klient mit Ihrer UserID gefunden."
                }
            }
        }

        private func loadDiaryEntries() async {
            guard let client = clientViewModel.clients.first(where: { $0.userID == authManager.userID }),
                  let clientID = client.id else { return }
            do {
                let snapshot = try await Firestore.firestore().collection("diaryEntries")
                    .whereField("clientID", isEqualTo: clientID)
                    .order(by: "timestamp", descending: true)
                    .getDocuments()
                await MainActor.run {
                    self.diaryEntries = snapshot.documents.compactMap { try? $0.data(as: DiaryEntry.self) }
                    self.analyzeDiaryEntries()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Fehler beim Laden der Tagebucheinträge: \(error.localizedDescription)"
                }
            }
        }

        private func saveDiaryEntry(_ entry: DiaryEntry) {
            Task {
                guard let clientID = clientViewModel.clients.first(where: { $0.userID == authManager.userID })?.id else { return }
                var newEntry = entry
                newEntry.clientID = clientID
                do {
                    try Firestore.firestore().collection("diaryEntries").addDocument(from: newEntry)
                    await loadDiaryEntries()
                } catch {
                    await MainActor.run {
                        errorMessage = "Fehler beim Speichern: \(error.localizedDescription)"
                    }
                }
            }
        }

        private func sendEmergencyAlert() {
            Task {
                guard let client = clientViewModel.clients.first(where: { $0.userID == authManager.userID }),
                      let clientID = client.id,
                      let userEmail = authManager.userEmail else { return }
                let activity = Activity(
                    clientID: clientID,
                    description: "Notfall-Alarm von \(userEmail)",
                    timestamp: Date(),
                    category: "Emergency"
                )
                do {
                    try await FirestoreManager.shared.createActivity(activity: activity)
                } catch {
                    await MainActor.run {
                        errorMessage = "Fehler: \(error.localizedDescription)"
                    }
                }
            }
        }

        private func analyzeDiaryEntries() {
            let text = diaryEntries.map { $0.content }.joined(separator: " ")
            let positiveWords = ["gut", "glücklich", "super"]
            let negativeWords = ["schlecht", "traurig", "problem"]
            let positiveCount = positiveWords.reduce(0) { $0 + (text.lowercased().contains($1) ? 1 : 0) }
            let negativeCount = negativeWords.reduce(0) { $0 + (text.lowercased().contains($1) ? 1 : 0) }
            let mood = positiveCount > negativeCount ? "positiv" : (negativeCount > positiveCount ? "negativ" : "neutral")
            notifyStaffAboutMood(mood: mood)
        }

        private func notifyStaffAboutMood(mood: String) {
            Task {
                guard let clientID = clientViewModel.clients.first(where: { $0.userID == authManager.userID })?.id else { return }
                let activity = Activity(
                    clientID: clientID,
                    description: "KI-Analyse: Stimmung des Klienten ist \(mood)",
                    timestamp: Date(),
                    category: "MoodAnalysis"
                )
                do {
                    try await FirestoreManager.shared.createActivity(activity: activity)
                } catch {
                    await MainActor.run {
                        errorMessage = "Fehler: \(error.localizedDescription)"
                    }
                }
            }
        }
    }

    struct ClientHomeDashboardView: View {
        let client: Client?
        let clientViewModel: ClientViewModel
        let sendEmergencyAlert: () -> Void
        @EnvironmentObject var authManager: AuthManager
        @State private var showingEditProfile = false
        @State private var editableClient: Client?

        var body: some View {
            ScrollView {
                VStack(spacing: 20) {
                    if let client = client {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Mein Profil")
                                .font(.headline)
                                .foregroundColor(.white) // Weiße Schrift
                            HStack {
                                if let url = client.profilbildURL, let imageUrl = URL(string: url) {
                                    AsyncImage(url: imageUrl) { image in
                                        image.resizable().scaledToFit().frame(width: 60, height: 60).clipShape(Circle())
                                    } placeholder: {
                                        ProgressView()
                                            .tint(.white) // Weißer Ladeindikator
                                    }
                                } else {
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 60, height: 60)
                                        .foregroundColor(.gray)
                                }
                                VStack(alignment: .leading) {
                                    Text("\(client.vorname) \(client.name)")
                                        .font(.title3)
                                        .bold()
                                        .foregroundColor(.white) // Weiße Schrift
                                    if let verein = client.vereinID {
                                        Text(verein)
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            Button("Profil bearbeiten") {
                                editableClient = client
                                showingEditProfile = true
                            }
                            .foregroundColor(.white) // Weiße Schrift
                        }
                        .padding()
                        .background(Color.gray.opacity(0.2)) // Dunklerer Hintergrund
                        .cornerRadius(10)
                    } else {
                        Text("Klientendaten werden geladen...")
                            .foregroundColor(.gray)
                    }

                    Button(action: sendEmergencyAlert) {
                        Text("Notfall-Alarm")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white) // Weiße Schrift
                            .cornerRadius(10)
                    }
                    .padding()
                }
                .padding()
                .background(Color.black) // Schwarzer Hintergrund
            }
            .sheet(isPresented: $showingEditProfile) {
                if let editableClient = editableClient {
                    NavigationView {
                        AddClientView()
                            .environmentObject(authManager)
                            .onAppear {
                                // Hier können wir den bestehenden Klienten in AddClientView laden, falls nötig
                                // Da AddClientView keine Parameter akzeptiert, müssen wir dies manuell handhaben
                            }
                            .toolbar {
                                ToolbarItem(placement: .cancellationAction) {
                                    Button("Abbrechen") {
                                        showingEditProfile = false
                                    }
                                    .foregroundColor(.white) // Weiße Schrift
                                }
                                ToolbarItem(placement: .confirmationAction) {
                                    Button("Speichern") {
                                        showingEditProfile = false
                                        Task {
                                            if let userID = authManager.userID {
                                                await clientViewModel.loadClients(userID: userID, loadMore: false)
                                            }
                                        }
                                    }
                                    .foregroundColor(.white) // Weiße Schrift
                                }
                            }
                            .background(Color.black) // Schwarzer Hintergrund
                    }
                }
            }
        }
    }

    struct DiaryView: View {
        @Binding var diaryEntries: [DiaryEntry]
        let saveDiaryEntry: (DiaryEntry) -> Void
        @EnvironmentObject var authManager: AuthManager
        @State private var showingDiaryEntry = false

        var body: some View {
            VStack {
                List {
                    ForEach(diaryEntries) { entry in
                        DiaryCard(entry: entry)
                    }
                    .listRowBackground(Color.gray.opacity(0.2)) // Dunklerer Hintergrund für Listenelemente
                }
                .scrollContentBackground(.hidden) // Standard-Hintergrund der Liste ausblenden
                .background(Color.black) // Schwarzer Hintergrund für die Liste

                Button(action: { showingDiaryEntry = true }) {
                    Text("Neuen Eintrag erstellen")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white) // Weiße Schrift
                        .cornerRadius(10)
                }
                .padding()
            }
            .background(Color.black) // Schwarzer Hintergrund für die gesamte View
            .sheet(isPresented: $showingDiaryEntry) {
                DiaryEntryView(onSave: saveDiaryEntry, onCancel: { showingDiaryEntry = false })
            }
        }
    }

    struct DiaryEntryView: View {
        @State private var content = ""
        let onSave: (DiaryEntry) -> Void
        let onCancel: () -> Void

        var body: some View {
            NavigationView {
                Form {
                    TextField("Wie geht es dir heute?", text: $content, axis: .vertical)
                        .lineLimit(5)
                        .foregroundColor(.white) // Weiße Schrift
                }
                .scrollContentBackground(.hidden) // Standard-Hintergrund der Form ausblenden
                .background(Color.black) // Schwarzer Hintergrund für die Form
                .navigationTitle("Neuer Tagebucheintrag")
                .foregroundColor(.white) // Weiße Schrift für den Titel
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Abbrechen") { onCancel() }
                            .foregroundColor(.white) // Weiße Schrift
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Speichern") {
                            let entry = DiaryEntry(content: content, timestamp: Date())
                            onSave(entry)
                        }
                        .disabled(content.isEmpty)
                        .foregroundColor(.white) // Weiße Schrift
                    }
                }
            }
        }
    }

    struct DiaryEntry: Identifiable, Codable {
        @DocumentID var id: String?
        var clientID: String?
        var content: String
        var timestamp: Date
    }

    struct DiaryCard: View {
        let entry: DiaryEntry

        var body: some View {
            VStack(alignment: .leading, spacing: 5) {
                Text(entry.content)
                    .lineLimit(2)
                    .foregroundColor(.white) // Weiße Schrift
                Text(entry.timestamp, style: .date)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.gray.opacity(0.2)) // Dunklerer Hintergrund
            .cornerRadius(10)
        }
    }

    #Preview {
        ClientHomeView()
            .environmentObject(AuthManager())
    }                                                                                                                       
