import SwiftUI

struct AddEditNoteView: View {
    @Binding var transferProcess: TransferProcess
    @State var note: Note?
    let onSave: (Note) -> Void
    @Environment(\.dismiss) var dismiss

    @State private var beschreibung: String
    @State private var vereinsDokumenteText: String // Für die Eingabe als kommagetrennte Liste

    // Farben für das helle Design
    private let backgroundColor = Color(hex: "#F5F5F5")
    private let cardBackgroundColor = Color(hex: "#E0E0E0")
    private let accentColor = Color(hex: "#00C4B4")
    private let textColor = Color(hex: "#333333")
    private let secondaryTextColor = Color(hex: "#666666")

    init(transferProcess: Binding<TransferProcess>, note: Note?, onSave: @escaping (Note) -> Void) {
        self._transferProcess = transferProcess
        self.note = note
        self.onSave = onSave

        let initialNote = note ?? Note(beschreibung: "")
        _beschreibung = State(initialValue: initialNote.beschreibung)
        _vereinsDokumenteText = State(initialValue: initialNote.vereinsDokumente?.joined(separator: ", ") ?? "")
    }

    var body: some View {
        NavigationView {
            ZStack {
                backgroundColor.edgesIgnoringSafeArea(.all)
                List {
                    Section(header: Text("Hinweis").foregroundColor(textColor)) {
                        VStack(spacing: 10) {
                            TextField("Beschreibung", text: $beschreibung, axis: .vertical)
                                .foregroundColor(textColor)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                            TextField("Dokumente (URLs, kommagetrennt)", text: $vereinsDokumenteText, axis: .vertical)
                                .foregroundColor(textColor)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                        }
                        .padding(.vertical, 8)
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
                }
                .listStyle(PlainListStyle())
                .listRowInsets(EdgeInsets(top: 3, leading: 13, bottom: 3, trailing: 13))
                .scrollContentBackground(.hidden)
                .background(backgroundColor)
                .tint(accentColor)
                .foregroundColor(textColor)
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
                        .disabled(beschreibung.isEmpty)
                        .foregroundColor(accentColor)
                    }
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
