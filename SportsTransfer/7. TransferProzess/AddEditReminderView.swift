import SwiftUI

struct AddEditReminderView: View {
    @Binding var transferProcess: TransferProcess
    @State var reminder: Reminder?
    let onSave: (Reminder) -> Void
    @Environment(\.dismiss) var dismiss

    @State private var datum: Date
    @State private var beschreibung: String
    @State private var kategorie: String

    // Farben für das dunkle Design
    private let backgroundColor = Color(hex: "#1C2526")
    private let cardBackgroundColor = Color(hex: "#2A3439")
    private let accentColor = Color(hex: "#00C4B4")
    private let textColor = Color(hex: "#E0E0E0")
    private let secondaryTextColor = Color(hex: "#B0BEC5")

    init(transferProcess: Binding<TransferProcess>, reminder: Reminder?, onSave: @escaping (Reminder) -> Void) {
        self._transferProcess = transferProcess
        self.reminder = reminder
        self.onSave = onSave

        // Initialisierung der Zustandsvariablen
        let initialReminder = reminder ?? Reminder(datum: Date(), beschreibung: "")
        _datum = State(initialValue: initialReminder.datum)
        _beschreibung = State(initialValue: initialReminder.beschreibung)
        _kategorie = State(initialValue: initialReminder.kategorie ?? "")
    }

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundColor.edgesIgnoringSafeArea(.all)

                ScrollView {
                    VStack(spacing: 16) {
                        // Titel
                        Text(reminder == nil ? "Erinnerung hinzufügen" : "Erinnerung bearbeiten")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(textColor)
                            .padding(.top, 16)

                        // Erinnerung-Details
                        VStack(alignment: .leading, spacing: 12) {
                            // Datum
                            DatePicker("Datum", selection: $datum, displayedComponents: [.date, .hourAndMinute])
                                .foregroundColor(textColor)
                                .accentColor(accentColor)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(cardBackgroundColor)
                                .clipShape(RoundedRectangle(cornerRadius: 8))

                            // Beschreibung
                            TextField("Beschreibung", text: $beschreibung)
                                .padding()
                                .background(cardBackgroundColor)
                                .foregroundColor(textColor)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(accentColor.opacity(0.2), lineWidth: 1)
                                )

                            // Kategorie
                            Picker("Kategorie", selection: $kategorie) {
                                Text("Keine").tag("")
                                Text("Nachfrage").tag("nachfrageErinnerung")
                                Text("Vertragsprüfung").tag("vertragsprüfung")
                                Text("Termin").tag("termin")
                            }
                            .pickerStyle(.menu)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(cardBackgroundColor)
                            .foregroundColor(textColor)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
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
            .navigationTitle(reminder == nil ? "Erinnerung hinzufügen" : "Erinnerung bearbeiten")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                        .foregroundColor(accentColor)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        let updatedReminder = Reminder(
                            id: reminder?.id ?? UUID().uuidString,
                            datum: datum,
                            beschreibung: beschreibung,
                            kategorie: kategorie.isEmpty ? nil : kategorie
                        )
                        onSave(updatedReminder)
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
    AddEditReminderView(
        transferProcess: .constant(TransferProcess(clientID: "1", vereinID: "1")),
        reminder: Reminder(datum: Date(), beschreibung: "Nachfragen", kategorie: "nachfrageErinnerung"),
        onSave: { _ in }
    )
}
