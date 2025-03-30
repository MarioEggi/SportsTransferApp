import SwiftUI
import MessageUI // Für MFMailComposeViewController

struct EmailPreviewView: View {
    @Binding var isPresented: Bool
    @State var emailContent: String
    @State private var selectedLanguage: String = "Deutsch" // Standard: Deutsch
    @State private var includeClubDocs = false
    @State private var includePlayerCV = false
    @State private var includeVideo = false
    @State private var showMailComposer = false
    let process: TransferProcess
    let step: Step
    let viewModel: TransferProcessViewModel
    let onCopy: (String) -> Void
    
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
                        Text("E-Mail-Vorschau")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(textColor)
                            .padding(.top, 16)
                        
                        // Sprachauswahl
                        Picker("Sprache", selection: $selectedLanguage) {
                            Text("Deutsch").tag("Deutsch")
                            Text("Englisch").tag("Englisch")
                            Text("Französisch").tag("Französisch")
                            Text("Spanisch").tag("Spanisch")
                        }
                        .pickerStyle(.menu)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(cardBackgroundColor)
                        .foregroundColor(textColor)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .onChange(of: selectedLanguage) { _ in
                            regenerateEmail()
                        }

                        // E-Mail-Editor
                        TextEditor(text: $emailContent)
                            .frame(minHeight: 300)
                            .padding()
                            .background(cardBackgroundColor)
                            .foregroundColor(textColor)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(accentColor.opacity(0.2), lineWidth: 1)
                            )

                        // Anhangsoptionen
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Anhänge")
                                .font(.headline)
                                .foregroundColor(textColor)
                            Toggle("Vereinsdokumente", isOn: $includeClubDocs)
                                .foregroundColor(textColor)
                            Toggle("Spieler-CV", isOn: $includePlayerCV)
                                .foregroundColor(textColor)
                            Toggle("Videomaterial", isOn: $includeVideo)
                                .foregroundColor(textColor)
                        }
                        .padding()
                        .background(cardBackgroundColor)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                }
            }
            .navigationTitle("E-Mail-Vorschau")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        isPresented = false
                    }
                    .foregroundColor(accentColor)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Menu {
                        Button(action: {
                            onCopy(emailContent)
                            isPresented = false
                        }) {
                            Label("Kopieren", systemImage: "doc.on.clipboard")
                        }
                        Button(action: {
                            showMailComposer = true
                        }) {
                            Label("Senden", systemImage: "paperplane")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundColor(accentColor)
                    }
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

    // E-Mail basierend auf der Sprache neu generieren
    private func regenerateEmail() {
        Task {
            let newEmail = await viewModel.generateEmail(for: process, step: step, language: selectedLanguage)
            await MainActor.run {
                emailContent = newEmail
            }
        }
    }

    // Betreff aus der E-Mail extrahieren
    private func extractSubject(from email: String) -> String {
        let lines = email.split(separator: "\n")
        if let subjectLine = lines.first(where: { $0.starts(with: "Betreff:") }) {
            return String(subjectLine.dropFirst(8)).trimmingCharacters(in: .whitespaces)
        }
        return ""
    }
}

// Wrapper für MFMailComposeViewController
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
        emailContent: "Betreff: Kontaktaufnahme für Max Mustermann - FC Beispiel\n\nSehr geehrte Damen und Herren,\n\nim Rahmen des Transfers von Max Mustermann haben wir am 30. März 2025 die Kontaktaufnahme mit FC Beispiel erfolgreich abgeschlossen.\n\nMit freundlichen Grüßen,\nSports Transfer Team",
        process: TransferProcess(clientID: "client1", vereinID: "club1", status: "in Bearbeitung", startDatum: Date()),
        step: Step(typ: "Kontaktaufnahme", status: "abgeschlossen", datum: Date()),
        viewModel: TransferProcessViewModel(authManager: AuthManager()),
        onCopy: { _ in }
    )
}
