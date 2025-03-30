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

    // Farben für das dunkle Design
    private let backgroundColor = Color(hex: "#1C2526")
    private let cardBackgroundColor = Color(hex: "#2A3439")
    private let accentColor = Color(hex: "#00C4B4")
    private let textColor = Color(hex: "#E0E0E0")
    private let secondaryTextColor = Color(hex: "#B0BEC5")

    init(transferProcess: Binding<TransferProcess>, step: Step?, onSave: @escaping (Step) -> Void) {
        self._transferProcess = transferProcess
        self.step = step
        self.onSave = onSave

        // Initialisierung der Zustandsvariablen
        let initialStep = step ?? Step(typ: "Kontaktaufnahme", status: "geplant", datum: Date())
        _typ = State(initialValue: initialStep.typ)
        _status = State(initialValue: initialStep.status)
        _datum = State(initialValue: initialStep.datum)
        _notizen = State(initialValue: initialStep.notizen ?? "")
        _erfolgschance = State(initialValue: initialStep.erfolgschance.map { String($0) } ?? "")
        _checklisteText = State(initialValue: initialStep.checkliste?.joined(separator: ", ") ?? "")
    }

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundColor.edgesIgnoringSafeArea(.all)

                ScrollView {
                    VStack(spacing: 16) {
                        // Titel
                        Text(step == nil ? "Schritt hinzufügen" : "Schritt bearbeiten")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(textColor)
                            .padding(.top, 16)

                        // Schritt-Details
                        VStack(alignment: .leading, spacing: 12) {
                            // Typ
                            Picker("Typ", selection: $typ) {
                                Text("Kontaktaufnahme").tag("Kontaktaufnahme")
                                Text("Zweiter Kontakt").tag("zweitKontakt")
                                Text("Klient informieren").tag("klientInfo")
                                Text("Vertrag verhandeln").tag("vertragVerhandeln")
                            }
                            .pickerStyle(.menu)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(cardBackgroundColor)
                            .foregroundColor(textColor)
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                            // Status
                            Picker("Status", selection: $status) {
                                Text("Geplant").tag("geplant")
                                Text("Abgeschlossen").tag("abgeschlossen")
                            }
                            .pickerStyle(.menu)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(cardBackgroundColor)
                            .foregroundColor(textColor)
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                            // Datum
                            DatePicker("Datum", selection: $datum, displayedComponents: [.date, .hourAndMinute])
                                .foregroundColor(textColor)
                                .accentColor(accentColor)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(cardBackgroundColor)
                                .clipShape(RoundedRectangle(cornerRadius: 8))

                            // Notizen
                            TextField("Notizen", text: $notizen, axis: .vertical)
                                .padding()
                                .background(cardBackgroundColor)
                                .foregroundColor(textColor)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(accentColor.opacity(0.2), lineWidth: 1)
                                )

                            // Erfolgschance
                            TextField("Erfolgschance (%)", text: $erfolgschance)
                                .keyboardType(.numberPad)
                                .padding()
                                .background(cardBackgroundColor)
                                .foregroundColor(textColor)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(accentColor.opacity(0.2), lineWidth: 1)
                                )

                            // Checkliste
                            TextField("Checkliste (kommagetrennt)", text: $checklisteText, axis: .vertical)
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
                    .foregroundColor(typ.isEmpty ? secondaryTextColor : accentColor)
                    .disabled(typ.isEmpty)
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
