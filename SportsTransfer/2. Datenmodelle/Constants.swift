import SwiftUI

struct Constants {
    static let nationalities = ["Deutschland", "Schweiz", "Österreich", "Frankreich", "Italien", "Spanien"]
    static let positionOptions = ["Stürmer", "Mittelfeld", "Verteidiger", "Torwart"]
    static let strongFootOptions = ["Rechts", "Links", "Beidfüßig"]
    static let functionaryPositionOptions = ["Trainer", "Manager", "Sportdirektor"]
    static let leaguesMale = ["Bundesliga", "2. Bundesliga", "Premier League"]
    static let leaguesFemale = ["Frauen-Bundesliga", "2. Frauen-Bundesliga"]
    static let sponsorCategories = ["Sportartikelhersteller", "Finanzdienstleister", "Lebensmittel", "Technologie", "Andere"]
    static let activityCategories = ["Besprechung", "Training", "Spiel", "Verhandlung", "Sonstiges"]
    static let contactTypes = ["Telefon", "E-Mail", "Besuch", "Teams-Meeting"] // Hinzugefügt
    static let contactTopics = ["Besuch", "Vertragsverhandlung", "Feedback", "Trainingsplan"] // Hinzugefügt

    enum SortOption: String, CaseIterable {
        case nameAscending = "Name aufsteigend"
        case nameDescending = "Name absteigend"
        case birthDateAscending = "Geburtsdatum aufsteigend"
        case birthDateDescending = "Geburtsdatum absteigend"
    }

    enum ContactFilterType: String, CaseIterable, Identifiable {
        case all = "Alle"
        case clients = "Klienten"
        case funktionäre = "Funktionäre"
        var id: String { self.rawValue }
    }

    enum GroupByOption: String, CaseIterable, Identifiable {
        case none = "Keine"
        case club = "Verein"
        case type = "Typ"
        var id: String { self.rawValue }
    }
}
