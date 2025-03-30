import Foundation

enum Constants {
    // Positionen auf dem Spielfeld
    static let positionOptions = [
        "Tor", "Innenverteidigung rechts", "Innenverteidigung links",
        "Aussenverteidiger rechts", "Aussenverteidiger links",
        "Defensives Mittelfeld 6", "Zentrales Mittelfeld 8",
        "Offensives Mittelfeld 10", "Mittelfeld rechts", "Mittelfeld links",
        "Aussenstürmer rechts", "Aussenstürmer links", "Mittelstürmer"
    ]

    // Kontaktarten und Themen
    static let contactTypes = ["Telefon", "Email", "Videocall", "Treffen"]
    static let contactTopics = ["Besuch", "Coaching", "Vertrag", "Problem", "Analyse", "Sonstiges"]

    // Funktionärspositionen
    static let functionaryPositionOptions = [
        "Trainer", "Sportlicher Leiter", "Geschäftsführer", "Geschäftsführer Sport",
        "Technischer Leiter", "NLZ Leiter", "Co-Trainer", "Co-Trainer 2",
        "Physiotherapeut", "Arzt", "Rehatrainer", "Präsident", "Teammanager",
        "Aufsichtsrat", "Beirat", "U17 Trainer", "U19 Trainer", "U20 Trainer",
        "U21 Trainer", "U23 Trainer", "Psychologe", "Direktor Profifussball", "Andere"
    ]

    // Geschlechtsoptionen
    static let genderOptions = ["männlich", "weiblich"]

    // Kliententypen
    static let clientTypes = ["Spieler", "Spielerin", "Trainer", "Co-Trainer", "sportlicher Leiter"]

    // Starker Fuß Optionen
    static let strongFootOptions = ["rechts", "links", "beide"]

    // Ligen
    static let leaguesMale = [
        "1. Bundesliga", "2. Bundesliga", "3. Liga", "Regionalliga", "Oberliga", "Serie A", "Serie B",
        "Premier League", "EFL Championship", "Super League CH", "Challenge League CH",
        "1. Bundesliga AUT", "La Liga", "MLS"
    ]
    static let leaguesFemale = [
        "1. Bundesliga", "2. Bundesliga", "Regionalliga", "WSL CH", "FA WSL 1",
        "FA WSL 2", "NWSL", "ÖFB Frauen Bundesliga", "Serie A", "Serie B",
        "Primera Division SPA"
    ]

    // Aktivitätskategorien
    static let activityCategories = ["Besuch", "Coaching", "Vertrag", "Problem", "Analyse", "Sonstiges"]
    
    // Sponsor-Kategorien
    static let sponsorCategories = [
        "Sportartikelhersteller",
        "Beauty",
        "Automobil",
        "Firma"
    ]

    // Regionen für Ansprechpartner
    static let sponsorContactRegions = [
        "Deutschland",
        "Schweiz",
        "Österreich",
        "Italien",
        "Frankreich",
        "England",
        "Niederlande",
        "Spanien",
        "USA",
        "Europa",
        "Weltweit",
        "Andere"
    ]
    
    // Liste der Nationalitäten (basierend auf Ländern, auf Deutsch)
    static let nationalities: [String] = {
        let locale = Locale(identifier: "de_DE") // Explizit auf Deutsch setzen
        let countryCodes = Locale.isoRegionCodes
        var countries: [String] = []
        
        for code in countryCodes {
            if let countryName = locale.localizedString(forRegionCode: code) {
                countries.append(countryName)
            }
        }
        
        return countries.sorted()
    }()

    // Sortieroptionen
    enum SortOption: String, CaseIterable {
        case name = "Name"
        case age = "Alter"
        case nameAscending = "Name (A-Z)"
        case nameDescending = "Name (Z-A)"
        case birthDateAscending = "Geburtsdatum (aufsteigend)"
        case birthDateDescending = "Geburtsdatum (absteigend)"
        case contractEnd = "VertragBis"
    }

    // Kontaktfilter und Gruppierungsoptionen
    enum ContactFilterType: String, CaseIterable {
        case all = "Alle"
        case clients = "Klienten"
        case funktionäre = "Funktionäre"
    }

    enum GroupByOption: String, CaseIterable {
        case none = "Keine"
        case club = "Verein"
        case type = "Typ"
    }

    // Benutzerrollen (optional, falls aus AuthManager verschoben)
    enum UserRole: String, Codable {
        case mitarbeiter = "Mitarbeiter"
        case klient = "Klient"
        case gast = "Gast"
    }
}
