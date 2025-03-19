import SwiftUI
import FirebaseFirestore

struct ClientHomeView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var client: Client? // Zentral verwaltete Client-Daten
    @State private var diaryEntries: [DiaryEntry] = [] // Zentral verwaltete Tagebucheinträge
    @State private var errorMessage = ""
    @State private var isLoading = true
    @State private var selectedTab = 0
    @State private var showingLeadSheet = false
    @State private var showingSearchSheet = false
    @State private var showingContactsSheet = false

    // Definiere die Tabs außerhalb der body-Eigenschaft
    private var tabs: [(title: String, icon: String, view: AnyView)] {
        [
            (title: "Home", icon: "house", view: AnyView(ClientHomeDashboardView(client: $client, sendEmergencyAlert: sendEmergencyAlert))),
            (title: "Chat", icon: "bubble.left", view: AnyView(ChatView())),
            (title: "Tagebuch", icon: "book.fill", view: AnyView(DiaryView(diaryEntries: $diaryEntries, saveDiaryEntry: saveDiaryEntry))),
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
        .overlay(customBar, alignment: .bottom) // Hier war der Fehler: bottomBar -> customBar
        .sheet(isPresented: $showingLeadSheet) {
            ClientContactView(authManager: authManager, isPresented: $showingLeadSheet)
        }
        .sheet(isPresented: $showingSearchSheet) {
            Text("Appübergreifende Suche (Platzhalter)")
                .onDisappear {
                    showingSearchSheet = false
                }
        }
        .sheet(isPresented: $showingContactsSheet) {
            ContactsView()
                .environmentObject(authManager)
                .onDisappear {
                    showingContactsSheet = false
                }
        }
        .alert(isPresented: .constant(!errorMessage.isEmpty)) {
            Alert(title: Text("Fehler"), message: Text(errorMessage), dismissButton: .default(Text("OK")) {
                errorMessage = ""
            })
        }
        .task {
            Task {
                await loadClientData()
                await loadDiaryEntries()
            }
        }
    }

    private var customBar: some View { // Name auf customBar geändert, um Konsistenz mit meiner vorherigen Anpassung zu wahren
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

                Menu {
                    Button(action: { showingLeadSheet = true }) {
                        Label("Kontakt aufnehmen", systemImage: "envelope")
                    }
                } label: {
                    VStack {
                        Image(systemName: "plus.circle")
                            .font(.title2)
                        Text("Create")
                            .font(.caption)
                            .lineLimit(1)
                    }
                    .foregroundColor(.blue)
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
                    .foregroundColor(selectedTab == 1 ? .blue : .gray)
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

    private func loadClientData() async {
        guard let userID = authManager.userID else {
            await MainActor.run {
                errorMessage = "Nicht angemeldet"
                isLoading = false
            }
            return
        }
        do {
            let snapshot = try await Firestore.firestore().collection("users").document(userID).getDocument()
            guard let data = snapshot.data(),
                  let clientID = data["clientID"] as? String else {
                await MainActor.run {
                    errorMessage = "Keine Client-ID gefunden."
                    isLoading = false
                }
                return
            }

            let clientSnapshot = try await Firestore.firestore().collection("clients").document(clientID).getDocument()
            if clientSnapshot.exists,
               let foundClient = try? clientSnapshot.data(as: Client.self) {
                await MainActor.run {
                    self.client = foundClient
                    isLoading = false
                }
            } else {
                await MainActor.run {
                    errorMessage = "Kein Klient mit der ID \(clientID) gefunden."
                    isLoading = false
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = "Fehler beim Laden der Benutzerdaten: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }

    private func loadDiaryEntries() async {
        guard let clientID = client?.id else { return }
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
            guard let clientID = client?.id else { return }
            var newEntry = entry
            newEntry.clientID = clientID
            do {
                try await Firestore.firestore().collection("diaryEntries").addDocument(from: newEntry)
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
            guard let clientID = client?.id, let userEmail = authManager.userEmail else { return }
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
            guard let clientID = client?.id else { return }
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
    @Binding var client: Client?
    let sendEmergencyAlert: () -> Void
    @State private var showingEditProfile = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let client = client {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Mein Profil")
                            .font(.headline)
                        HStack {
                            if let url = client.profilbildURL, let imageUrl = URL(string: url) {
                                AsyncImage(url: imageUrl) { image in
                                    image.resizable().scaledToFit().frame(width: 60, height: 60).clipShape(Circle())
                                } placeholder: { ProgressView() }
                            } else {
                                Image(systemName: "person.circle.fill").resizable().scaledToFit().frame(width: 60, height: 60).foregroundColor(.gray)
                            }
                            VStack(alignment: .leading) {
                                Text("\(client.vorname) \(client.name)").font(.title3).bold()
                                if let verein = client.vereinID { Text(verein).font(.subheadline).foregroundColor(.gray) }
                            }
                        }
                        Button("Profil anzeigen") {
                            showingEditProfile = true
                        }
                        .foregroundColor(.blue)
                    }
                    .padding()
                    .background(Color(.systemGray6))
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
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
            }
            .padding()
        }
        .sheet(isPresented: $showingEditProfile) {
            if let client = client {
                AddClientView(
                    client: Binding.constant(client),
                    isEditing: true,
                    onSave: { updatedClient in
                        Task {
                            do {
                                try await FirestoreManager.shared.updateClient(client: updatedClient)
                                await MainActor.run {
                                    self.client = updatedClient
                                    showingEditProfile = false
                                }
                            } catch {
                                await MainActor.run {
                                    print("Fehler: \(error.localizedDescription)")
                                }
                            }
                        }
                    },
                    onCancel: { showingEditProfile = false }
                )
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
            }
            Button(action: { showingDiaryEntry = true }) {
                Text("Neuen Eintrag erstellen")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
        }
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
            }
            .navigationTitle("Neuer Tagebucheintrag")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { onCancel() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        let entry = DiaryEntry(content: content, timestamp: Date())
                        onSave(entry)
                    }
                    .disabled(content.isEmpty)
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
            Text(entry.timestamp, style: .date)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

#Preview {
    ClientHomeView()
        .environmentObject(AuthManager())
}
