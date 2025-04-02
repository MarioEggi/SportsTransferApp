import SwiftUI
import FirebaseFirestore

struct FunktionärListView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var viewModel: FunktionärViewModel
    @State private var showingAddFunktionärSheet = false
    @State private var showingEditFunktionärSheet = false
    @State private var newFunktionär = Funktionär(name: "", vorname: "")
    @State private var selectedFunktionär: Funktionär?

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
                VStack(spacing: 0) {
                    HStack {
                        Text("Funktionäre")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(textColor)
                        Spacer()
                        Button(action: { showingAddFunktionärSheet = true }) {
                            Image(systemName: "plus")
                                .foregroundColor(accentColor)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)

                    List {
                        if viewModel.funktionäre.isEmpty {
                            Text("Keine Funktionäre gefunden.")
                                .foregroundColor(secondaryTextColor)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .listRowBackground(backgroundColor)
                        } else {
                            ForEach(viewModel.funktionäre, id: \.id) { funktionär in
                                NavigationLink(destination: FunktionärView(funktionär: .constant(funktionär))) {
                                    funktionärRow(for: funktionär)
                                }
                                .swipeActions {
                                    Button(role: .destructive) {
                                        Task { await viewModel.deleteFunktionär(funktionär) }
                                    } label: {
                                        Label("Löschen", systemImage: "trash")
                                            .foregroundColor(.white)
                                    }
                                    Button(action: {
                                        selectedFunktionär = funktionär
                                        showingEditFunktionärSheet = true
                                    }) {
                                        Label("Bearbeiten", systemImage: "pencil")
                                            .foregroundColor(.white)
                                    }
                                    .tint(.blue)
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
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 3, leading: 13, bottom: 3, trailing: 13))
                            }
                            if viewModel.isLoading {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                                    .tint(accentColor)
                                    .listRowBackground(backgroundColor)
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                    .scrollContentBackground(.hidden)
                    .background(backgroundColor)
                    .padding(.horizontal)
                }
                .sheet(isPresented: $showingAddFunktionärSheet) {
                    AddFunktionärView(
                        funktionär: $newFunktionär,
                        onSave: { updatedFunktionär in
                            Task {
                                await viewModel.saveFunktionär(updatedFunktionär)
                                await MainActor.run {
                                    resetNewFunktionär()
                                    showingAddFunktionärSheet = false
                                }
                            }
                        },
                        onCancel: {
                            resetNewFunktionär()
                            showingAddFunktionärSheet = false
                        }
                    )
                }
                .sheet(isPresented: $showingEditFunktionärSheet) {
                    if let selectedFunktionär = selectedFunktionär {
                        EditFunktionärView(
                            funktionär: Binding(
                                get: { selectedFunktionär },
                                set: { self.selectedFunktionär = $0 }
                            ),
                            onSave: { updatedFunktionär in
                                Task {
                                    await viewModel.saveFunktionär(updatedFunktionär)
                                    await MainActor.run {
                                        showingEditFunktionärSheet = false
                                        self.selectedFunktionär = nil
                                    }
                                }
                            },
                            onCancel: {
                                showingEditFunktionärSheet = false
                                self.selectedFunktionär = nil
                            }
                        )
                    }
                }
                .alert(isPresented: $viewModel.isShowingError) {
                    Alert(
                        title: Text("Fehler").foregroundColor(textColor),
                        message: Text(viewModel.errorMessage).foregroundColor(secondaryTextColor),
                        dismissButton: .default(Text("OK").foregroundColor(accentColor)) {
                            viewModel.resetError()
                        }
                    )
                }
                .task {
                    await viewModel.loadClubs()
                }
            }
        }
    }

    @ViewBuilder
    private func funktionärRow(for funktionär: Funktionär) -> some View {
        HStack(spacing: 10) {
            if let profilbildURL = funktionär.profilbildURL, let url = URL(string: profilbildURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: 40, height: 40)
                            .tint(accentColor)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(accentColor.opacity(0.3), lineWidth: 1))
                    case .failure:
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 40, height: 40)
                            .foregroundColor(secondaryTextColor)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(accentColor.opacity(0.3), lineWidth: 1))
                    @unknown default:
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 40, height: 40)
                            .foregroundColor(secondaryTextColor)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(accentColor.opacity(0.3), lineWidth: 1))
                    }
                }
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .foregroundColor(secondaryTextColor)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(accentColor.opacity(0.3), lineWidth: 1))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("\(funktionär.vorname) \(funktionär.name)")
                    .font(.headline)
                    .foregroundColor(textColor)
                if let position = funktionär.positionImVerein {
                    Text(position)
                        .font(.caption)
                        .foregroundColor(secondaryTextColor)
                }
                if let vereinID = funktionär.vereinID,
                   let club = viewModel.clubs.first(where: { $0.id == vereinID }) {
                    HStack(spacing: 5) {
                        if let logoURL = club.sharedInfo?.logoURL, let url = URL(string: logoURL) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 20, height: 20)
                                        .clipShape(Circle())
                                case .failure, .empty:
                                    Image(systemName: "building.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 20, height: 20)
                                        .foregroundColor(secondaryTextColor)
                                        .clipShape(Circle())
                                @unknown default:
                                    Image(systemName: "building.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 20, height: 20)
                                        .foregroundColor(secondaryTextColor)
                                        .clipShape(Circle())
                                }
                            }
                        } else {
                            Image(systemName: "building.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                                .foregroundColor(secondaryTextColor)
                                .clipShape(Circle())
                        }
                        Text(club.name)
                            .font(.caption)
                            .foregroundColor(secondaryTextColor)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 8)
    }

    private func resetNewFunktionär() {
        newFunktionär = Funktionär(name: "", vorname: "")
    }
}

#Preview {
    FunktionärListView()
        .environmentObject(AuthManager())
        .environmentObject(FunktionärViewModel())
}
