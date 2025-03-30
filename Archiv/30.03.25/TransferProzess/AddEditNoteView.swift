import SwiftUI

struct AddEditNoteView: View {
    @Binding var transferProcess: TransferProcess
    @State var note: Note?
    let onSave: (Note) -> Void
    @Environment(\.dismiss) var dismiss

    @State private var beschreibung = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Hinweis Details")) {
                    TextField("Beschreibung", text: $beschreibung)
                }
            }
            .foregroundColor(.white)
            .navigationTitle(note == nil ? "Hinweis hinzufügen" : "Hinweis bearbeiten")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        let updatedNote = Note(
                            id: note?.id ?? UUID().uuidString,
                            beschreibung: beschreibung
                        )
                        onSave(updatedNote)
                        dismiss()
                    }
                    .disabled(beschreibung.isEmpty)
                }
            }
            .background(Color.black)
        }
        .onAppear {
            if let note = note {
                beschreibung = note.beschreibung
            }
        }
    }
}
