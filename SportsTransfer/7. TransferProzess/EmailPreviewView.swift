import SwiftUI
import MessageUI

struct EmailPreviewView: View {
    @Binding var isPresented: Bool
    @Binding var emailContent: String
    let process: TransferProcess
    let step: Step
    let viewModel: TransferProcessViewModel
    let onCopy: (String) -> Void
    
    @State private var selectedLanguage: String = "Deutsch"
    @State private var includeClubDocs = false
    @State private var includePlayerCV = false
    @State private var includeVideo = false
    @State private var showMailComposer = false

    // Farben für das helle Design
    private let backgroundColor = Color(hex: "#F5F5F5")
    private let cardBackgroundColor = Color(hex: "#E0E0E0")
    private let accentColor = Color(hex: "#00C4B4")
    private let textColor = Color(hex: "#333333")
    private let secondaryTextColor = Color(hex: "#666666")

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 15) {
                    List {
                        Section(header: Text("E-Mail-Vorschau").foregroundColor(textColor)) {
                            VStack(spacing: 10) {
                                Picker("Sprache", selection: $selectedLanguage) {
                                    Text("Deutsch").tag("Deutsch")
                                    Text("Englisch").tag("Englisch")
                                    Text("Französisch").tag("Französisch")
                                    Text("Spanisch").tag("Spanisch")
                                }
                                .pickerStyle(.menu)
                                .foregroundColor(textColor)
                                .tint(accentColor)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .onChange(of: selectedLanguage) { _ in regenerateEmail() }
                                
                                TextEditor(text: $emailContent)
                                    .frame(minHeight: 300)
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

                        Section(header: Text("Anhänge").foregroundColor(textColor)) {
                            VStack(spacing: 10) {
                                Toggle("Vereinsdokumente", isOn: $includeClubDocs)
                                    .foregroundColor(textColor)
                                    .tint(accentColor)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                Toggle("Spieler-CV", isOn: $includePlayerCV)
                                    .foregroundColor(textColor)
                                    .tint(accentColor)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                Toggle("Videomaterial", isOn: $includeVideo)
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
                    .foregroundColor(textColor)

                    HStack(spacing: 15) {
                        Button(action: {
                            onCopy(emailContent)
                            isPresented = false
                        }) {
                            Text("Kopieren")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(accentColor)
                                .foregroundColor(textColor)
                                .cornerRadius(10)
                        }
                        Button(action: { showMailComposer = true }) {
                            Text("Senden")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(accentColor)
                                .foregroundColor(textColor)
                                .cornerRadius(10)
                        }
                    }
                    .padding()
                }
                .background(backgroundColor)
                .navigationTitle("E-Mail-Vorschau")
                .navigationBarTitleDisplayMode(.inline)
                .foregroundColor(textColor)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Abbrechen") { isPresented = false }
                            .foregroundColor(accentColor)
                    }
                }
                .sheet(isPresented: $showMailComposer) {
                    MailComposeView(
                        subject: extractSubject(from: emailContent),
                        body: emailContent,
                        isPresented: $showMailComposer
                    )
                }
            }
        }
    }

    private func regenerateEmail() {
        Task {
            let newEmail = await viewModel.generateEmail(for: process, step: step, language: selectedLanguage)
            await MainActor.run {
                emailContent = newEmail
            }
        }
    }

    private func extractSubject(from email: String) -> String {
        let lines = email.split(separator: "\n")
        if let subjectLine = lines.first(where: { $0.starts(with: "Betreff:") }) {
            return String(subjectLine.dropFirst(8)).trimmingCharacters(in: .whitespaces)
        }
        return ""
    }
}

struct MailComposeView: UIViewControllerRepresentable {
    let subject: String
    let body: String
    @Binding var isPresented: Bool

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let mailComposer = MFMailComposeViewController()
        mailComposer.mailComposeDelegate = context.coordinator
        mailComposer.setSubject(subject)
        mailComposer.setMessageBody(body, isHTML: false)
        return mailComposer
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let parent: MailComposeView

        init(_ parent: MailComposeView) {
            self.parent = parent
        }

        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            parent.isPresented = false
        }
    }
}

#Preview {
    EmailPreviewView(
        isPresented: .constant(true),
        emailContent: .constant("Betreff: Kontaktaufnahme für Max Mustermann - FC Beispiel\n\nSehr geehrte Damen und Herren,\n\nim Rahmen des Transfers von Max Mustermann haben wir am 30. März 2025 die Kontaktaufnahme mit FC Beispiel erfolgreich abgeschlossen.\n\nMit freundlichen Grüßen,\nSports Transfer Team"),
        process: TransferProcess(clientID: "client1", vereinID: "club1", status: "in Bearbeitung", startDatum: Date()),
        step: Step(typ: "Kontaktaufnahme", status: "abgeschlossen", datum: Date()),
        viewModel: TransferProcessViewModel(authManager: AuthManager()),
        onCopy: { _ in }
    )
}
