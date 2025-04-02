//
//  Constants.swift

import SwiftUI

struct Constants {
    static let nationalities = ["Deutschland", "Schweiz", "Österreich", "Frankreich", "Italien", "Spanien"]
    static let positionOptions = ["Torwart", "Innenverteidiger", "Außenverteidigung Links", "Außenverteidigung Rechts", "6", "8 offensiv", "8 defensiv", "8 BoxtoBox", "10", "Linkes Mittelfeld", "Rechtes Mittelfeld", "Sturm außen", "Sturm zentral",]
    static let strongFootOptions = ["Rechts", "Links", "Beidfüßig"]
    static let functionaryPositionOptions = ["Trainer", "Manager", "Sportdirektor"]
    static let leaguesMale = ["1. Bundesliga", "2. Bundesliga", "3. Liga","Premier League"]
    static let leaguesFemale = ["1. Bundesliga", "2. Bundesliga", "NWSL", "WSL England", "WSL Schweiz"]
    static let sponsorCategories = ["Sportartikelhersteller", "Finanzdienstleister", "Lebensmittel", "Technologie", "Andere"]
    static let activityCategories = ["Besprechung", "Training", "Spiel", "Verhandlung", "Sonstiges"]
    static let contactTypes = ["Telefon", "E-Mail", "Besuch", "Teams-Meeting", "WhatsApp", "Nachricht"] // Hinzugefügt
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
