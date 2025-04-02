import SwiftUI

struct AddEditReminderView: View {
    @Binding var transferProcess: TransferProcess
    @State var reminder: Reminder?
    let onSave: (Reminder) -> Void
    @Environment(\.dismiss) var dismiss

    @State private var datum: Date
    @State private var beschreibung: String
    @State private var kategorie: String

    // Farben für das helle Design
    private let backgroundColor = Color(hex: "#F5F5F5")
    private let cardBackgroundColor = Color(hex: "#E0E0E0")
    private let accentColor = Color(hex: "#00C4B4")
    private let textColor = Color(hex: "#333333")
    private let secondaryTextColor = Color(hex: "#666666")

    init(transferProcess: Binding<TransferProcess>, reminder: Reminder?, onSave: @escaping (Reminder) -> Void) {
        self._transferProcess = transferProcess
        self.reminder = reminder
        self.onSave = onSave

        let initialReminder = reminder ?? Reminder(datum: Date(), beschreibung: "")
        _datum = State(initialValue: initialReminder.datum)
        _beschreibung = State(initialValue: initialReminder.beschreibung)
        _kategorie = State(initialValue: initialReminder.kategorie ?? "")
    }

    var body: some View {
        NavigationView {
            ZStack {
                backgroundColor.edgesIgnoringSafeArea(.all)
                List {
                    Section(header: Text("Erinnerung").foregroundColor(textColor)) {
                        VStack(spacing: 10) {
                            DatePicker("Datum", selection: $datum, displayedComponents: [.date, .hourAndMinute])
                                .foregroundColor(textColor)
                                .tint(accentColor)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                            TextField("Beschreibung", text: $beschreibung)
                                .foregroundColor(textColor)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                            Picker("Kategorie", selection: $kategorie) {
                                Text("Keine").tag("")
                                Text("Nachfrage").tag("nachfrageErinnerung")
                                Text("Vertragsprüfung").tag("vertragsprüfung")
                                Text("Termin").tag("termin")
                            }
                            .pickerStyle(.menu)
                            .foregroundColor(textColor)
                            .tint(accentColor)
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
                        .disabled(beschreibung.isEmpty)
                        .foregroundColor(accentColor)
                    }
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
