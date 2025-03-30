import SwiftUI

struct TransferProcessListView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var transferProcesses: [TransferProcess] = []
    @State private var isLoading = true
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            List {
                ForEach(transferProcesses) { process in
                    NavigationLink(destination: TransferProcessDetailView(transferProcess: process)) {
                        HStack {
                            Text("Klient-ID: \(process.clientID)")
                            Spacer()
                            Text(process.status)
                                .foregroundColor(process.status == "abgeschlossen" ? .green : .orange)
                        }
                    }
                }
            }
            .navigationTitle("Transferprozesse")
            .overlay {
                if isLoading {
                    ProgressView("Lade Transferprozesse...")
                }
            }
            .alert(isPresented: .constant(!errorMessage.isEmpty)) {
                Alert(
                    title: Text("Fehler"),
                    message: Text(errorMessage),
                    dismissButton: .default(Text("OK")) { errorMessage = "" }
                )
            }
            .task {
                await loadTransferProcesses()
            }
        }
    }

    private func loadTransferProcesses() async {
        do {
            let (processes, _) = try await FirestoreManager.shared.getTransferProcesses()
            await MainActor.run {
                self.transferProcesses = processes
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Fehler beim Laden: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
}

#Preview {
    TransferProcessListView()
        .environmentObject(AuthManager())
}
