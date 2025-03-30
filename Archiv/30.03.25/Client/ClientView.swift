import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import UIKit

struct ClientView: View {
    @EnvironmentObject var authManager: AuthManager
    @Binding var client: Client
    @StateObject private var viewModel: ClientViewModel
    @StateObject private var contractViewModel = ContractViewModel()
    @State private var showingImagePicker = false
    @State private var showingEditSheet = false
    @State private var showingCreateLoginSheet = false
    @State private var loginEmail = ""
    @State private var loginPassword = ""
    @State private var selectedTab: Int = 0
    @State private var activities: [Activity] = []
    @State private var isLoadingContracts = true
    @State private var errorMessage: String = ""
    @State private var errorQueue: [String] = []
    @State private var isShowingError = false
    @State private var clubName: String? = nil
    @State private var clubLogoURL: String? = nil

    var previousClientAction: (() -> Void)?
    var nextClientAction: (() -> Void)?

    init(client: Binding<Client>) {
        self._client = client
        self._viewModel = StateObject(wrappedValue: ClientViewModel(authManager: AuthManager()))
    }

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    private var detailsTab: some View {
        Form {
            Section(header: Text("Spieldaten").foregroundColor(.white)) {
                labeledField(label: "Positionen", value: client.positionFeld?.joined(separator: ", "))
                labeledField(label: "Nationalmannschaft", value: client.nationalmannschaft)
                labeledField(label: "Größe", value: client.groesse.map { "\($0) cm" })
                labeledField(label: "Starker Fuß", value: client.starkerFuss)
            }
        }
        .scrollContentBackground(.hidden) // Standard-Hintergrund der Form ausblenden
        .background(Color.black) // Schwarzer Hintergrund für die Form
    }

    private var contractTab: some View {
        VStack(spacing: 20) {
            Section(header: Text("Vertragsübersicht")
                .font(.headline)
                .foregroundColor(.white) // Weiße Schrift
                .padding(.top)) {
                if isLoadingContracts {
                    ProgressView("Lade Verträge...")
                        .tint(.white) // Weißer Ladeindikator
                } else if let contract = contractViewModel.contracts.first(where: { $0.clientID == client.id }) {
                    NavigationLink(destination: ContractDetailView(contract: contract)) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Verein: \(contract.vereinID ?? "Kein Verein")")
                                .font(.subheadline)
                                .foregroundColor(.white) // Weiße Schrift
                            Text("Start: \(dateFormatter.string(from: contract.startDatum))")
                                .font(.subheadline)
                                .foregroundColor(.white) // Weiße Schrift
                            if let endDatum = contract.endDatum {
                                Text("Ende: \(dateFormatter.string(from: endDatum))")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                            if let gehalt = contract.gehalt {
                                Text("Gehalt: \(gehalt) €")
                                    .font(.subheadline)
                                    .foregroundColor(.white) // Weiße Schrift
                            }
                            labeledField(label: "Vertragsoptionen", value: contract.vertragsdetails)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.2)) // Dunklerer Hintergrund
                        .cornerRadius(10)
                    }
                } else {
                    Text("Kein Vertrag vorhanden.")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(Color.black) // Schwarzer Hintergrund
    }

    private var contactTab: some View {
        Form {
            Section(header: Text("Kontaktdaten").foregroundColor(.white)) {
                if let phone = client.kontaktTelefon {
                    HStack {
                        labeledField(label: "Telefon", value: phone)
                        Spacer()
                        Button(action: { openURL("tel:\(phone)") }) {
                            Image(systemName: "phone.fill")
                                .foregroundColor(.white) // Weißes Symbol
                        }
                    }
                }
                if let email = client.kontaktEmail {
                    HStack {
                        labeledField(label: "E-Mail", value: email)
                        Spacer()
                        Button(action: { openURL("mailto:\(email)") }) {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(.white) // Weißes Symbol
                        }
                    }
                }
                labeledField(label: "Adresse", value: client.adresse)
            }
        }
        .scrollContentBackground(.hidden) // Standard-Hintergrund der Form ausblenden
        .background(Color.black) // Schwarzer Hintergrund für die Form
    }

    private var activitiesTab: some View {
        VStack(spacing: 20) {
            Section(header: Text("Aktivitäten")
                .font(.headline)
                .foregroundColor(.white) // Weiße Schrift
                .padding(.top)) {
                if activities.isEmpty {
                    Text("Keine Aktivitäten vorhanden.")
                        .foregroundColor(.gray)
                } else {
                    ForEach(activities) { activity in
                        NavigationLink(destination: ActivityDetailView(activity: activity)) {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(activity.description)
                                    .font(.subheadline)
                                    .foregroundColor(.white) // Weiße Schrift
                                    .lineLimit(1)
                                Text(dateFormatter.string(from: activity.timestamp))
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.2)) // Dunklerer Hintergrund
                            .cornerRadius(10)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.black) // Schwarzer Hintergrund
    }

    private func labeledField(label: String, value: String?) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.gray)
            Spacer()
            Text(value ?? "Nicht angegeben")
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(value != nil ? Color.gray.opacity(0.2) : Color.clear) // Dunklerer Hintergrund
                .cornerRadius(4)
                .foregroundColor(.white) // Weiße Schrift
        }
    }

    private var genderSymbol: String {
        switch client.typ {
        case "Spieler": return "♂"
        case "Spielerin": return "♀"
        default: return ""
        }
    }

    private func calculateAge() -> Int? {
        guard let birthDate = client.geburtsdatum else { return nil }
        let calendar = Calendar.current
        let now = Date()
        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: now)
        return ageComponents.year
    }

    private func openURL(_ urlString: String) {
        if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 15) {
                    VStack(spacing: 10) {
                        if let urlString = client.profilbildURL, let url = URL(string: urlString) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                                case .failure, .empty:
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 100, height: 100)
                                        .foregroundColor(.gray)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                                @unknown default:
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 100, height: 100)
                                        .foregroundColor(.gray)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                                }
                            }
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .foregroundColor(.gray)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                        }

                        Button(action: { showingImagePicker = true }) {
                            Image(systemName: "arrow.up.circle")
                                .font(.system(size: 24))
                                .foregroundColor(.white) // Weißes Symbol
                                .opacity(0.6)
                        }
                        .sheet(isPresented: $showingImagePicker) {
                            ImagePicker(selectedImage: .constant(nil), isPresented: $showingImagePicker) { selectedImage in
                                Task {
                                    if let clientID = client.id {
                                        do {
                                            let url = try await FirestoreManager.shared.uploadImage(
                                                documentID: clientID,
                                                image: selectedImage,
                                                collection: "profile_images"
                                            )
                                            client.profilbildURL = url
                                            await viewModel.saveClient(client)
                                        } catch {
                                            addErrorToQueue("Fehler beim Hochladen des Bildes: \(error.localizedDescription)")
                                        }
                                    }
                                }
                            }
                        }

                        Text("\(client.vorname) \(client.name)\(calculateAge().map { ", \($0) Jahre" } ?? "")")
                            .font(.title2)
                            .bold()
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white) // Weiße Schrift

                        // Vereinsname und Logo anzeigen
                        HStack(spacing: 10) {
                            if let logoURL = clubLogoURL, let url = URL(string: logoURL) {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 20, height: 20)
                                            .clipShape(Circle())
                                    case .failure, .empty:
                                        Image(systemName: "building.fill")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 20, height: 20)
                                            .foregroundColor(.gray)
                                            .clipShape(Circle())
                                    @unknown default:
                                        Image(systemName: "building.fill")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 20, height: 20)
                                            .foregroundColor(.gray)
                                            .clipShape(Circle())
                                    }
                                }
                            } else {
                                Image(systemName: "building.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 20, height: 20)
                                    .foregroundColor(.gray)
                                    .clipShape(Circle())
                            }
                            Text(clubName ?? "Kein Verein")
                                .font(.headline)
                                .foregroundColor(.white) // Weiße Schrift
                        }

                        if let abteilung = client.abteilung {
                            Text("Abteilung: \(abteilung)")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }

                        if let vertragBis = client.vertragBis {
                            Text("Vertragslaufzeit: \(dateFormatter.string(from: vertragBis))")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        if let vertragsOptionen = client.vertragsOptionen {
                            Text("Vertragsoptionen: \(vertragsOptionen)")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()

                    TabView(selection: $selectedTab) {
                        detailsTab.tag(0)
                        contractTab.tag(1)
                        contactTab.tag(2)
                        activitiesTab.tag(3)
                    }
                    .frame(height: 300)
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))

                    Picker("Abschnitt", selection: $selectedTab) {
                        Text("Details").tag(0)
                        Text("Vertrag").tag(1)
                        Text("Kontaktdaten").tag(2)
                        Text("Aktivitäten").tag(3)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .foregroundColor(.white) // Weiße Schrift
                    .accentColor(.white) // Weiße Akzente
                    .padding()

                    if client.userID == nil {
                        Button(action: { showingCreateLoginSheet = true }) {
                            Text("Klienten-Login erstellen")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white) // Weiße Schrift
                                .cornerRadius(10)
                        }
                        .padding()
                    } else {
                        Text("Klienten-Login bereits erstellt (UserID: \(client.userID!))")
                            .foregroundColor(.green)
                            .padding()
                    }
                }
                .background(Color.black) // Schwarzer Hintergrund für die gesamte View
                .navigationTitle("\(client.vorname) \(client.name)")
                .navigationBarTitleDisplayMode(.inline)
                .foregroundColor(.white) // Weiße Schrift für den Titel
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        HStack {
                            if let previous = previousClientAction {
                                Button(action: previous) {
                                    Image(systemName: "chevron.left")
                                        .foregroundColor(.white) // Weißes Symbol
                                }
                            }
                            if let next = nextClientAction {
                                Button(action: next) {
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.white) // Weißes Symbol
                                }
                            }
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack {
                            Text(genderSymbol)
                                .font(.system(size: 14))
                                .foregroundColor(client.typ == "Spieler" ? .blue : .pink)
                            Button(action: { showingEditSheet = true }) {
                                Image(systemName: "pencil")
                                    .foregroundColor(.white) // Weißes Symbol
                            }
                        }
                    }
                }
                .sheet(isPresented: $showingEditSheet) {
                    EditClientView(
                        client: $client,
                        onSave: { updatedClient in
                            Task {
                                print("ClientView - Client zum Speichern: \(updatedClient)")
                                await viewModel.saveClient(updatedClient)
                                // Synchrone UI-Updates in MainActor.run
                                await MainActor.run {
                                    client = updatedClient
                                    print("ClientView - Client nach Update: \(client)")
                                    showingEditSheet = false
                                }
                                // Asynchrone Aufrufe außerhalb von MainActor.run
                                await loadContracts()
                                await loadClubDetails()
                            }
                        },
                        onCancel: { showingEditSheet = false }
                    )
                }
                .sheet(isPresented: $showingCreateLoginSheet) {
                    CreateClientLoginView(
                        email: $loginEmail,
                        password: $loginPassword,
                        onSave: {
                            guard !loginEmail.isEmpty, !loginPassword.isEmpty else {
                                addErrorToQueue("E-Mail und Passwort dürfen nicht leer sein.")
                                return
                            }
                            guard let clientID = client.id else {
                                addErrorToQueue("Klienten-ID nicht verfügbar.")
                                return
                            }
                            Task { await createClientLogin(email: loginEmail, password: loginPassword, clientID: clientID) }
                        },
                        onCancel: {
                            showingCreateLoginSheet = false
                            loginEmail = ""
                            loginPassword = ""
                        }
                    )
                }
                .alert(isPresented: $isShowingError) {
                    Alert(
                        title: Text("Fehler").foregroundColor(.white),
                        message: Text(errorMessage).foregroundColor(.white),
                        dismissButton: .default(Text("OK").foregroundColor(.white)) {
                            if !errorQueue.isEmpty {
                                errorMessage = errorQueue.removeFirst()
                                isShowingError = true
                            } else {
                                isShowingError = false
                            }
                        }
                    )
                }
                .task {
                    await loadContracts()
                    await loadActivities()
                    await loadClubDetails()
                }
            }
        }
    }

    private func loadContracts() async {
        guard let clientID = client.id else { return }
        do {
            let (loadedContracts, _) = try await FirestoreManager.shared.getContracts(lastDocument: nil, limit: 1000)
            await MainActor.run {
                contractViewModel.contracts = loadedContracts.filter { $0.clientID == clientID }
                if let contract = contractViewModel.contracts.first {
                    client.vertragBis = contract.endDatum
                    client.vertragsOptionen = contract.vertragsdetails
                } else {
                    client.vertragBis = nil
                    client.vertragsOptionen = nil
                }
                isLoadingContracts = false
            }
        } catch {
            await MainActor.run {
                addErrorToQueue("Fehler beim Laden der Verträge: \(error.localizedDescription)")
            }
        }
    }

    private func loadActivities() async {
        guard let clientID = client.id else {
            addErrorToQueue("Klienten-ID nicht verfügbar.")
            return
        }
        do {
            let loadedActivities = try await FirestoreManager.shared.getActivities(forClientID: clientID)
            await MainActor.run {
                activities = loadedActivities
            }
        } catch {
            await MainActor.run {
                addErrorToQueue("Fehler beim Laden der Aktivitäten: \(error.localizedDescription)")
            }
        }
    }

    private func loadClubDetails() async {
        guard let vereinID = client.vereinID else {
            await MainActor.run {
                clubName = nil
                clubLogoURL = nil
            }
            return
        }
        do {
            let (clubs, _) = try await FirestoreManager.shared.getClubs(lastDocument: nil, limit: 1000)
            if let club = clubs.first(where: { $0.id == vereinID }) {
                await MainActor.run {
                    clubName = club.name
                    clubLogoURL = club.sharedInfo?.logoURL
                }
            } else {
                await MainActor.run {
                    clubName = nil
                    clubLogoURL = nil
                }
            }
        } catch {
            await MainActor.run {
                addErrorToQueue("Fehler beim Laden der Vereinsdetails: \(error.localizedDescription)")
                clubName = nil
                clubLogoURL = nil
            }
        }
    }

    private func createClientLogin(email: String, password: String, clientID: String) async {
        print("Erstelle Klienten-Login für ClientID: \(clientID) mit E-Mail: \(email)")
        guard let userID = client.userID else {
            await MainActor.run {
                addErrorToQueue("Keine userID für den Klienten vorhanden.")
            }
            return
        }
        authManager.createClientLogin(email: email, password: password, clientID: clientID, userID: userID) { result in
            Task {
                switch result {
                case .success:
                    print("Klienten-Login erfolgreich erstellt. UserID: \(userID)")
                    await MainActor.run {
                        showingCreateLoginSheet = false
                        loginEmail = ""
                        loginPassword = ""
                    }
                case .failure(let error):
                    print("Fehler beim Erstellen des Klienten-Logins: \(error.localizedDescription)")
                    await MainActor.run {
                        addErrorToQueue("Fehler beim Erstellen des Logins: \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    private func addErrorToQueue(_ message: String) {
        errorQueue.append(message)
        if !isShowingError {
            errorMessage = errorQueue.removeFirst()
            isShowingError = true
        }
    }

    struct CreateClientLoginView: View {
        @Binding var email: String
        @Binding var password: String
        let onSave: () -> Void
        let onCancel: () -> Void

        var body: some View {
            NavigationView {
                Form {
                    Section(header: Text("Klienten-Login erstellen").foregroundColor(.white)) {
                        TextField("E-Mail", text: $email)
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                            .foregroundColor(.white) // Weiße Schrift
                        SecureField("Passwort", text: $password)
                            .autocapitalization(.none)
                            .foregroundColor(.white) // Weiße Schrift
                    }
                }
                .scrollContentBackground(.hidden) // Standard-Hintergrund der Form ausblenden
                .background(Color.black) // Schwarzer Hintergrund für die Form
                .navigationTitle("Login erstellen")
                .foregroundColor(.white) // Weiße Schrift für den Titel
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Abbrechen") { onCancel() }
                            .foregroundColor(.white) // Weiße Schrift
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Erstellen") { onSave() }
                            .foregroundColor(.white) // Weiße Schrift
                    }
                }
            }
        }
    }

    struct ImagePicker: UIViewControllerRepresentable {
        @Binding var selectedImage: UIImage?
        @Binding var isPresented: Bool
        var onImageSelected: (UIImage) -> Void

        func makeUIViewController(context: Context) -> UIImagePickerController {
            let picker = UIImagePickerController()
            picker.delegate = context.coordinator
            picker.sourceType = .photoLibrary
            return picker
        }

        func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

        func makeCoordinator() -> Coordinator {
            Coordinator(self)
        }

        class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
            let parent: ImagePicker

            init(_ parent: ImagePicker) {
                self.parent = parent
            }

            func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
                if let uiImage = info[.originalImage] as? UIImage {
                    parent.selectedImage = uiImage
                    parent.onImageSelected(uiImage)
                }
                parent.isPresented = false
            }

            func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
                parent.isPresented = false
            }
        }
    }
}

#Preview {
    ClientView(client: .constant(Client(
        id: "1",
        typ: "Spieler",
        name: "Müller",
        vorname: "Thomas",
        geschlecht: "männlich",
        abteilung: "Männer",
        vereinID: "Bayern Munich",
        nationalitaet: ["Deutschland"],
        geburtsdatum: Date().addingTimeInterval(-25 * 365 * 24 * 60 * 60)
    )))
    .environmentObject(AuthManager())
}
