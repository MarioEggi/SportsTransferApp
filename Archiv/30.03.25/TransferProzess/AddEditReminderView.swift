import SwiftUI

struct AddEditReminderView: View {
    @Binding var transferProcess: TransferProcess
    @State var reminder: Reminder?
    let onSave: (Reminder) -> Void
    @Environment(\.dismiss) var dismiss

    @State private var datum = Date()
    @State private var beschreibung = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Erinnerung Details")) {
                    DatePicker("Datum", selection: $datum, displayedComponents: [.date, .hourAndMinute])
                    TextField("Beschreibung", text: $beschreibung)
                }
            }
            .foregroundColor(.white)
            .navigationTitle(reminder == nil ? "Erinnerung hinzufügen" : "Erinnerung bearbeiten")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        let updatedReminder = Reminder(
                            id: reminder?.id ?? UUID().uuidString,
                            datum: datum,
                            beschreibung: beschreibung
                        )
                        onSave(updatedReminder)
                        dismiss()
                    }
                    .disabled(beschreibung.isEmpty)
                }
            }
            .background(Color.black)
        }
        .onAppear {
            if let reminder = reminder {
                datum = reminder.datum
                beschreibung = reminder.beschreibung
            }
        }
    }
}
