import SwiftUI

struct AddEditStepView: View {
    @Binding var transferProcess: TransferProcess
    @State var step: Step?
    let onSave: (Step) -> Void
    @Environment(\.dismiss) var dismiss

    @State private var typ = ""
    @State private var status = "geplant"
    @State private var datum = Date()
    @State private var notizen = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Schritt Details")) {
                    TextField("Typ (z. B. Kontaktaufnahme)", text: $typ)
                    Picker("Status", selection: $status) {
                        Text("Geplant").tag("geplant")
                        Text("Abgeschlossen").tag("abgeschlossen")
                    }
                    DatePicker("Datum", selection: $datum, displayedComponents: [.date, .hourAndMinute])
                    TextField("Notizen", text: $notizen)
                }
            }
            .foregroundColor(.white)
            .navigationTitle(step == nil ? "Schritt hinzufügen" : "Schritt bearbeiten")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        let updatedStep = Step(
                            id: step?.id ?? UUID().uuidString,
                            typ: typ,
                            status: status,
                            datum: datum,
                            notizen: notizen.isEmpty ? nil : notizen
                        )
                        onSave(updatedStep)
                        dismiss()
                    }
                    .disabled(typ.isEmpty)
                }
            }
            .background(Color.black)
        }
        .onAppear {
            if let step = step {
                typ = step.typ
                status = step.status
                datum = step.datum
                notizen = step.notizen ?? ""
            }
        }
    }
}
