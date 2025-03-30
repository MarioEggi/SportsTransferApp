import SwiftUI

struct AddEditNoteView: View {
    @Binding var transferProcess: TransferProcess
    @State var note: Note?
    let onSave: (Note) -> Void
    @Environment(\.dismiss) var dismiss

    @State private var beschreibung: String
    @State private var vereinsDokumenteText: String // Für die Eingabe als kommagetrennte Liste

    // Farben für das dunkle Design
    private let backgroundColor = Color(hex: "#1C2526")
    private let cardBackgroundColor = Color(hex: "#2A3439")
    private let accentColor = Color(hex: "#00C4B4")
    private let textColor = Color(hex: "#E0E0E0")
    private let secondaryTextColor = Color(hex: "#B0BEC5")

    init(transferProcess: Binding<TransferProcess>, note: Note?, onSave: @escaping (Note) -> Void) {
        self._transferProcess = transferProcess
        self.note = note
        self.onSave = onSave

        // Initialisierung der Zustandsvariablen
        let initialNote = note ?? Note(beschreibung: "")
        _beschreibung = State(initialValue: initialNote.beschreibung)
        _vereinsDokumenteText = State(initialValue: initialNote.vereinsDokumente?.joined(separator: ", ") ?? "")
    }

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundColor.edgesIgnoringSafeArea(.all)

                ScrollView {
                    VStack(spacing: 16) {
                        // Titel
                        Text(note == nil ? "Hinweis hinzufügen" : "Hinweis bearbeiten")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(textColor)
                            .padding(.top, 16)

                        // Hinweis-Details
                        VStack(alignment: .leading, spacing: 12) {
                            // Beschreibung
                            TextField("Beschreibung", text: $beschreibung, axis: .vertical)
                                .padding()
                                .background(cardBackgroundColor)
                                .foregroundColor(textColor)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(accentColor.opacity(0.2), lineWidth: 1)
                                )

                            // Vereinsdokumente
                            TextField("Dokumente (URLs, kommagetrennt)", text: $vereinsDokumenteText, axis: .vertical)
                                .padding()
                                .background(cardBackgroundColor)
                                .foregroundColor(textColor)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(accentColor.opacity(0.2), lineWidth: 1)
                                )
                        }
                        .padding()
                        .background(cardBackgroundColor)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(accentColor.opacity(0.2), lineWidth: 1)
                        )
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 16)
                }
            }
            .navigationTitle(note == nil ? "Hinweis hinzufügen" : "Hinweis bearbeiten")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                        .foregroundColor(accentColor)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        let vereinsDokumente = vereinsDokumenteText.split(separator: ",")
                            .map { String($0.trimmingCharacters(in: .whitespaces)) }
                            .filter { !$0.isEmpty }
                        let updatedNote = Note(
                            id: note?.id ?? UUID().uuidString,
                            beschreibung: beschreibung,
                            vereinsDokumente: vereinsDokumente.isEmpty ? nil : vereinsDokumente
                        )
                        onSave(updatedNote)
                        dismiss()
                    }
                    .foregroundColor(beschreibung.isEmpty ? secondaryTextColor : accentColor)
                    .disabled(beschreibung.isEmpty)
                }
            }
        }
    }
}

#Preview {
    AddEditNoteView(
        transferProcess: .constant(TransferProcess(clientID: "1", vereinID: "1")),
        note: Note(beschreibung: "Verein interessiert", vereinsDokumente: ["doc1.pdf"]),
        onSave: { _ in }
    )
}
