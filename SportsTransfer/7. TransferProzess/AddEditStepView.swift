import SwiftUI

struct AddEditStepView: View {
    @Binding var transferProcess: TransferProcess
    @State var step: Step?
    let onSave: (Step) -> Void
    @Environment(\.dismiss) var dismiss

    @State private var typ: String
    @State private var status: String
    @State private var datum: Date
    @State private var notizen: String
    @State private var erfolgschance: String
    @State private var checklisteText: String // Für die Eingabe als kommagetrennte Liste

    // Farben für das helle Design
    private let backgroundColor = Color(hex: "#F5F5F5")
    private let cardBackgroundColor = Color(hex: "#E0E0E0")
    private let accentColor = Color(hex: "#00C4B4")
    private let textColor = Color(hex: "#333333")
    private let secondaryTextColor = Color(hex: "#666666")

    init(transferProcess: Binding<TransferProcess>, step: Step?, onSave: @escaping (Step) -> Void) {
        self._transferProcess = transferProcess
        self.step = step
        self.onSave = onSave

        let initialStep = step ?? Step(typ: "Kontaktaufnahme", status: "geplant", datum: Date())
        _typ = State(initialValue: initialStep.typ)
        _status = State(initialValue: initialStep.status)
        _datum = State(initialValue: initialStep.datum)
        _notizen = State(initialValue: initialStep.notizen ?? "")
        _erfolgschance = State(initialValue: initialStep.erfolgschance.map { String($0) } ?? "")
        _checklisteText = State(initialValue: initialStep.checkliste?.joined(separator: ", ") ?? "")
    }

    var body: some View {
        NavigationView {
            ZStack {
                backgroundColor.edgesIgnoringSafeArea(.all)
                List {
                    Section(header: Text("Schritt").foregroundColor(textColor)) {
                        VStack(spacing: 10) {
                            Picker("Typ", selection: $typ) {
                                Text("Kontaktaufnahme").tag("Kontaktaufnahme")
                                Text("Zweiter Kontakt").tag("zweitKontakt")
                                Text("Klient informieren").tag("klientInfo")
                                Text("Vertrag verhandeln").tag("vertragVerhandeln")
                            }
                            .pickerStyle(.menu)
                            .foregroundColor(textColor)
                            .tint(accentColor)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            Picker("Status", selection: $status) {
                                Text("Geplant").tag("geplant")
                                Text("Abgeschlossen").tag("abgeschlossen")
                            }
                            .pickerStyle(.menu)
                            .foregroundColor(textColor)
                            .tint(accentColor)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            DatePicker("Datum", selection: $datum, displayedComponents: [.date, .hourAndMinute])
                                .foregroundColor(textColor)
                                .tint(accentColor)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                            TextField("Notizen", text: $notizen, axis: .vertical)
                                .foregroundColor(textColor)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                            TextField("Erfolgschance (%)", text: $erfolgschance)
                                .keyboardType(.numberPad)
                                .foregroundColor(textColor)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                            TextField("Checkliste (kommagetrennt)", text: $checklisteText, axis: .vertical)
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
                .navigationTitle(step == nil ? "Schritt hinzufügen" : "Schritt bearbeiten")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Abbrechen") { dismiss() }
                            .foregroundColor(accentColor)
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Speichern") {
                            let checkliste = checklisteText.split(separator: ",")
                                .map { String($0.trimmingCharacters(in: .whitespaces)) }
                                .filter { !$0.isEmpty }
                            let updatedStep = Step(
                                id: step?.id ?? UUID().uuidString,
                                typ: typ,
                                status: status,
                                datum: datum,
                                notizen: notizen.isEmpty ? nil : notizen,
                                erfolgschance: Int(erfolgschance),
                                checkliste: checkliste.isEmpty ? nil : checkliste
                            )
                            onSave(updatedStep)
                            dismiss()
                        }
                        .disabled(typ.isEmpty)
                        .foregroundColor(accentColor)
                    }
                }
            }
        }
    }
}

#Preview {
    AddEditStepView(
        transferProcess: .constant(TransferProcess(clientID: "1", vereinID: "1")),
        step: Step(typ: "Kontaktaufnahme", status: "geplant", datum: Date(), erfolgschance: 80, checkliste: ["Gehalt abfragen"]),
        onSave: { _ in }
    )
}
