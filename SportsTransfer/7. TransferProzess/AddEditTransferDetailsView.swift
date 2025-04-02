import SwiftUI

struct AddEditTransferDetailsView: View {
    @Binding var transferProcess: TransferProcess
    @State var transferDetails: TransferDetails?
    let onSave: (TransferDetails) -> Void
    @Environment(\.dismiss) var dismiss

    @State private var vonVereinID = ""
    @State private var zuVereinID = ""
    @State private var funktionärID = ""
    @State private var datum = Date()
    @State private var ablösesumme = ""
    @State private var isAblösefrei = false
    @State private var transferdetails = ""

    // Farben für das helle Design
    private let backgroundColor = Color(hex: "#F5F5F5")
    private let cardBackgroundColor = Color(hex: "#E0E0E0")
    private let accentColor = Color(hex: "#00C4B4")
    private let textColor = Color(hex: "#333333")
    private let secondaryTextColor = Color(hex: "#666666")

    var body: some View {
        NavigationView {
            ZStack {
                backgroundColor.edgesIgnoringSafeArea(.all)
                List {
                    Section(header: Text("Transferdetails").foregroundColor(textColor)) {
                        VStack(spacing: 10) {
                            TextField("Von Verein ID", text: $vonVereinID)
                                .foregroundColor(textColor)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                            TextField("Zu Verein ID", text: $zuVereinID)
                                .foregroundColor(textColor)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                            TextField("Funktionär ID", text: $funktionärID)
                                .foregroundColor(textColor)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                            DatePicker("Datum", selection: $datum, displayedComponents: [.date])
                                .foregroundColor(textColor)
                                .tint(accentColor)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                            TextField("Ablösesumme", text: $ablösesumme)
                                .keyboardType(.decimalPad)
                                .foregroundColor(textColor)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                            Toggle("Ablösefrei", isOn: $isAblösefrei)
                                .foregroundColor(textColor)
                                .tint(accentColor)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                            TextField("Details", text: $transferdetails)
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
                .navigationTitle("Transferdetails bearbeiten")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Abbrechen") { dismiss() }
                            .foregroundColor(accentColor)
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Speichern") {
                            let updatedDetails = TransferDetails(
                                id: transferDetails?.id ?? UUID().uuidString,
                                vonVereinID: vonVereinID.isEmpty ? nil : vonVereinID,
                                zuVereinID: zuVereinID.isEmpty ? nil : zuVereinID,
                                funktionärID: funktionärID.isEmpty ? nil : funktionärID,
                                datum: datum,
                                ablösesumme: Double(ablösesumme),
                                isAblösefrei: isAblösefrei,
                                transferdetails: transferdetails.isEmpty ? nil : transferdetails
                            )
                            onSave(updatedDetails)
                            dismiss()
                        }
                        .foregroundColor(accentColor)
                    }
                }
                .onAppear {
                    if let details = transferDetails {
                        vonVereinID = details.vonVereinID ?? ""
                        zuVereinID = details.zuVereinID ?? ""
                        funktionärID = details.funktionärID ?? ""
                        datum = details.datum
                        ablösesumme = details.ablösesumme?.description ?? ""
                        isAblösefrei = details.isAblösefrei
                        transferdetails = details.transferdetails ?? ""
                    }
                }
            }
        }
    }
}
