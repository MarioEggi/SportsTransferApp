import SwiftUI
import UIKit
import Foundation
import FirebaseFirestore

struct FunktionärListView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var funktionäre: [Funktionär] = []
    @State private var errorMessage: String = ""
    @State private var showingEditSheet = false
    @State private var selectedFunktionär: Funktionär? = nil
    @State private var imageCache: [String: UIImage] = [:]
    @State private var clubs: [Club] = []

    var body: some View {
        NavigationStack {
            List {
                ForEach(Array(funktionäre.enumerated()), id: \.element) { index, funktionär in
                    NavigationLink(destination: FunktionärView(funktionär: $funktionäre[index])) {
                        HStack(spacing: 10) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(funktionär.vorname) \(funktionär.name)")
                                    .font(.headline)
                                    .scaleEffect(0.7)
                                if let geburtsdatum = funktionär.geburtsdatum {
                                    Text(dateFormatter.string(from: geburtsdatum))
                                        .font(.caption)
                                }
                                if let vereinID = funktionär.vereinID,
                                   let club = clubs.first(where: { $0.name == vereinID }) {
                                    Text("Verein: \(club.name)")
                                        .font(.caption)
                                } else {
                                    Text("Ohne Verein")
                                        .font(.caption)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.vertical, 5)
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            Task {
                                await deleteFunktionär(funktionär)
                            }
                        } label: {
                            Label("Löschen", systemImage: "trash")
                        }
                        Button {
                            selectedFunktionär = funktionär
                            showingEditSheet = true
                        } label: {
                            Label("Bearbeiten", systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
                }
            }
            .navigationTitle("Funktionäre verwalten")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        selectedFunktionär = nil
                        showingEditSheet = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingEditSheet) {
                editSheetContent()
            }
            .alert(isPresented: .constant(!errorMessage.isEmpty)) {
                Alert(title: Text("Fehler"), message: Text(errorMessage), dismissButton: .default(Text("OK")) {
                    errorMessage = ""
                })
            }
            .task {
                await loadFunktionäre()
                await loadClubs()
            }
        }
    }

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    private func loadFunktionäre() async {
        do {
            let loadedFunktionäre = try await FirestoreManager.shared.getFunktionäre()
            await MainActor.run {
                funktionäre = loadedFunktionäre
                for funktionär in loadedFunktionäre {
                    if let profilbildURL = funktionär.profilbildURL {
                        loadImage(for: funktionär)
                    }
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = "Fehler beim Laden der Funktionäre: \(error.localizedDescription)"
            }
        }
    }

    private func loadClubs() async {
        do {
            let loadedClubs = try await FirestoreManager.shared.getClubs()
            await MainActor.run {
                clubs = loadedClubs
                for club in loadedClubs {
                    if let logoURL = club.logoURL {
                        loadClubLogo(for: club.name)
                    }
                }
            }
        } catch {
            await MainActor.run {
                print("Fehler beim Laden der Vereine: \(error.localizedDescription)")
            }
        }
    }

    private func deleteFunktionär(_ funktionär: Funktionär) async {
        guard let id = funktionär.id else { return }
        do {
            try await FirestoreManager.shared.deleteFunktionär(funktionärID: id)
            await loadFunktionäre()
        } catch {
            await MainActor.run {
                errorMessage = "Fehler beim Löschen des Funktionärs: \(error.localizedDescription)"
            }
        }
    }

    private func loadImage(from url: URL, forKey key: String) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.imageCache[key] = image
                }
            }
        }.resume()
    }

    private func loadImage(for funktionär: Funktionär) {
        if let profilbildURL = funktionär.profilbildURL, let url = URL(string: profilbildURL) {
            loadImage(from: url, forKey: profilbildURL)
        }
    }

    private func loadClubLogo(for vereinID: String?) {
        guard let vereinID = vereinID, let club = clubs.first(where: { $0.name == vereinID }), let logoURL = club.logoURL, let url = URL(string: logoURL) else { return }
        loadImage(from: url, forKey: logoURL)
    }

    @ViewBuilder
    private func editSheetContent() -> some View {
        let defaultFunktionär = Funktionär(
            id: nil,
            name: "",
            vorname: "",
            abteilung: nil,
            vereinID: nil,
            kontaktTelefon: nil,
            kontaktEmail: nil,
            adresse: nil,
            clients: nil,
            profilbildURL: nil,
            geburtsdatum: nil,
            positionImVerein: nil,
            mannschaft: nil
        )

        AddFunktionärView(
            funktionär: Binding(
                get: { selectedFunktionär ?? defaultFunktionär },
                set: { selectedFunktionär = $0 }
            ),
            onSave: { newFunktionär in
                Task {
                    if let id = newFunktionär.id {
                        do {
                            try await FirestoreManager.shared.updateFunktionär(funktionär: newFunktionär)
                            await loadFunktionäre()
                        } catch {
                            await MainActor.run {
                                errorMessage = "Fehler beim Aktualisieren: \(error.localizedDescription)"
                            }
                        }
                    } else {
                        do {
                            try await FirestoreManager.shared.createFunktionär(funktionär: newFunktionär)
                            await loadFunktionäre()
                        } catch {
                            await MainActor.run {
                                errorMessage = "Fehler beim Erstellen: \(error.localizedDescription)"
                            }
                        }
                    }
                    await MainActor.run {
                        showingEditSheet = false
                        selectedFunktionär = nil
                    }
                }
            },
            onCancel: {
                showingEditSheet = false
                selectedFunktionär = nil
            }
        )
    }
}

#Preview {
    FunktionärListView()
        .environmentObject(AuthManager())
}

// Hinzugefügte AddFunktionärView
struct AddFunktionärView: View {
    @Binding var funktionär: Funktionär
    let onSave: (Funktionär) -> Void
    let onCancel: () -> Void

    @State private var name: String
    @State private var vorname: String
    @State private var abteilung: String?
    @State private var vereinID: String?
    @State private var kontaktTelefon: String?
    @State private var kontaktEmail: String?
    @State private var adresse: String?
    @State private var geburtsdatum: Date?
    @State private var positionImVerein: String?
    @State private var mannschaft: String?

    init(funktionär: Binding<Funktionär>, onSave: @escaping (Funktionär) -> Void, onCancel: @escaping () -> Void) {
        self._funktionär = funktionär
        self.onSave = onSave
        self.onCancel = onCancel
        self._name = State(initialValue: funktionär.wrappedValue.name)
        self._vorname = State(initialValue: funktionär.wrappedValue.vorname)
        self._abteilung = State(initialValue: funktionär.wrappedValue.abteilung)
        self._vereinID = State(initialValue: funktionär.wrappedValue.vereinID)
        self._kontaktTelefon = State(initialValue: funktionär.wrappedValue.kontaktTelefon)
        self._kontaktEmail = State(initialValue: funktionär.wrappedValue.kontaktEmail)
        self._adresse = State(initialValue: funktionär.wrappedValue.adresse)
        self._geburtsdatum = State(initialValue: funktionär.wrappedValue.geburtsdatum)
        self._positionImVerein = State(initialValue: funktionär.wrappedValue.positionImVerein)
        self._mannschaft = State(initialValue: funktionär.wrappedValue.mannschaft)
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Funktionär-Daten")) {
                    TextField("Name", text: $name)
                    TextField("Vorname", text: $vorname)
                    TextField("Abteilung", text: Binding(
                        get: { abteilung ?? "" },
                        set: { abteilung = $0.isEmpty ? nil : $0 }
                    ))
                    TextField("Verein-ID", text: Binding(
                        get: { vereinID ?? "" },
                        set: { vereinID = $0.isEmpty ? nil : $0 }
                    ))
                    TextField("Telefon", text: Binding(
                        get: { kontaktTelefon ?? "" },
                        set: { kontaktTelefon = $0.isEmpty ? nil : $0 }
                    ))
                    TextField("E-Mail", text: Binding(
                        get: { kontaktEmail ?? "" },
                        set: { kontaktEmail = $0.isEmpty ? nil : $0 }
                    ))
                    TextField("Adresse", text: Binding(
                        get: { adresse ?? "" },
                        set: { adresse = $0.isEmpty ? nil : $0 }
                    ))
                    DatePicker("Geburtsdatum", selection: Binding(
                        get: { geburtsdatum ?? Date() },
                        set: { geburtsdatum = $0 }
                    ), displayedComponents: .date)
                    TextField("Position im Verein", text: Binding(
                        get: { positionImVerein ?? "" },
                        set: { positionImVerein = $0.isEmpty ? nil : $0 }
                    ))
                    TextField("Mannschaft", text: Binding(
                        get: { mannschaft ?? "" },
                        set: { mannschaft = $0.isEmpty ? nil : $0 }
                    ))
                }
            }
            .navigationTitle("Funktionär hinzufügen/bearbeiten")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        onCancel()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        let updatedFunktionär = Funktionär(
                            id: funktionär.id,
                            name: name,
                            vorname: vorname,
                            abteilung: abteilung,
                            vereinID: vereinID,
                            kontaktTelefon: kontaktTelefon,
                            kontaktEmail: kontaktEmail,
                            adresse: adresse,
                            clients: nil, // Hier könnten Sie die Clients dynamisch setzen
                            profilbildURL: nil, // Profilbild-URL könnte hier hinzugefügt werden
                            geburtsdatum: geburtsdatum,
                            positionImVerein: positionImVerein,
                            mannschaft: mannschaft
                        )
                        onSave(updatedFunktionär)
                    }
                }
            }
        }
    }
}

#Preview {
    AddFunktionärView(
        funktionär: .constant(Funktionär(
            id: nil,
            name: "Mustermann",
            vorname: "Max",
            abteilung: "Männer",
            vereinID: nil,
            kontaktTelefon: nil,
            kontaktEmail: nil,
            adresse: nil,
            clients: nil,
            profilbildURL: nil,
            geburtsdatum: nil,
            positionImVerein: "Trainer",
            mannschaft: nil
        )),
        onSave: { _ in },
        onCancel: {}
    )
}
