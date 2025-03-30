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

    // Farben für das dunkle Design
    private let backgroundColor = Color(hex: "#1C2526")
    private let cardBackgroundColor = Color(hex: "#2A3439")
    private let accentColor = Color(hex: "#00C4B4")
    private let textColor = Color(hex: "#E0E0E0")
    private let secondaryTextColor = Color(hex: "#B0BEC5")

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundColor.edgesIgnoringSafeArea(.all)

                ScrollView {
                    VStack(spacing: 16) {
                        // Titel
                        Text("Transferdetails bearbeiten")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(textColor)
                            .padding(.top, 16)

                        // Transferdetails
                        VStack(alignment: .leading, spacing: 12) {
                            // Von Verein ID
                            TextField("Von Verein ID", text: $vonVereinID)
                                .padding()
                                .background(cardBackgroundColor)
                                .foregroundColor(textColor)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(accentColor.opacity(0.2), lineWidth: 1)
                                )

                            // Zu Verein ID
                            TextField("Zu Verein ID", text: $zuVereinID)
                                .padding()
                                .background(cardBackgroundColor)
                                .foregroundColor(textColor)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(accentColor.opacity(0.2), lineWidth: 1)
                                )

                            // Funktionär ID
                            TextField("Funktionär ID", text: $funktionärID)
                                .padding()
                                .background(cardBackgroundColor)
                                .foregroundColor(textColor)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(accentColor.opacity(0.2), lineWidth: 1)
                                )

                            // Datum
                            DatePicker("Datum", selection: $datum, displayedComponents: [.date])
                                .foregroundColor(textColor)
                                .accentColor(accentColor)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(cardBackgroundColor)
                                .clipShape(RoundedRectangle(cornerRadius: 8))

                            // Ablösesumme
                            TextField("Ablösesumme", text: $ablösesumme)
                                .keyboardType(.decimalPad)
                                .padding()
                                .background(cardBackgroundColor)
                                .foregroundColor(textColor)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(accentColor.opacity(0.2), lineWidth: 1)
                                )

                            // Ablösefrei
                            Toggle("Ablösefrei", isOn: $isAblösefrei)
                                .foregroundColor(textColor)
                                .tint(accentColor)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(cardBackgroundColor)
                                .clipShape(RoundedRectangle(cornerRadius: 8))

                            // Details
                            TextField("Details", text: $transferdetails)
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

                        Spacer(minLength: 80) // Platz für die untere Leiste
                    }
                    .padding(.bottom, 16)
                }
            }
            .ignoresSafeArea(edges: .bottom)
            .navigationTitle("Transferdetails bearbeiten")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        Text("Abbrechen")
                            .foregroundColor(accentColor)
                            .font(.system(size: 16, weight: .medium))
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
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
                    }) {
                        Text("Speichern")
                            .foregroundColor(accentColor)
                            .font(.system(size: 16, weight: .medium))
                    }
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
