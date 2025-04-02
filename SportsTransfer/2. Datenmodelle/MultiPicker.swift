//
//  MultiPicker.swift

import SwiftUI

struct MultiPicker: View {
    let title: String
    @Binding var selection: [String]
    let options: [String]
    var isNationalityPicker: Bool = false // Optionaler Parameter für Nationalitäten-Modus
    @State private var searchText: String = ""

    private let priorityNationalities = ["Deutschland", "Schweiz", "Österreich"]

    private var filteredOptions: [String] {
        if isNationalityPicker {
            let nonPriorityOptions = options.filter { !priorityNationalities.contains($0) }
            if searchText.isEmpty {
                return nonPriorityOptions
            } else {
                return nonPriorityOptions.filter { $0.lowercased().contains(searchText.lowercased()) }
            }
        } else {
            if searchText.isEmpty {
                return options
            } else {
                return options.filter { $0.lowercased().contains(searchText.lowercased()) }
            }
        }
    }

    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                if isNationalityPicker || options.count > 10 {
                    TextField("Suche", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                }

                List {
                    if isNationalityPicker {
                        Section(header: Text("Häufig verwendet")) {
                            ForEach(priorityNationalities, id: \.self) { option in
                                MultipleSelectionRow(
                                    title: option,
                                    isSelected: selection.contains(option)
                                ) {
                                    toggleSelection(option)
                                }
                            }
                        }
                    }

                    Section(header: Text(isNationalityPicker ? "Alle Länder" : title)) {
                        ForEach(filteredOptions, id: \.self) { option in
                            MultipleSelectionRow(
                                title: option,
                                isSelected: selection.contains(option)
                            ) {
                                toggleSelection(option)
                            }
                        }
                    }
                }
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fertig") {
                        // Die Auswahl wird automatisch über die Binding aktualisiert
                    }
                }
            }
        }
    }

    private func toggleSelection(_ option: String) {
        if selection.contains(option) {
            selection.removeAll { $0 == option }
        } else {
            selection.append(option)
        }
    }
}

// Eingebautes MultipleSelectionRow direkt in MultiPicker
struct MultipleSelectionRow: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                }
            }
        }
    }
}

#Preview {
    MultiPicker(
        title: "Nationalitäten auswählen",
        selection: .constant(["Deutschland"]),
        options: ["Deutschland", "Schweiz", "Österreich", "Frankreich", "Italien", "Spanien"],
        isNationalityPicker: true
    )
}
