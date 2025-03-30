import Foundation
import FirebaseFirestore

struct Client: Identifiable, Codable, Equatable, Hashable {
    @DocumentID var id: String?
    var typ: String
    var name: String
    var vorname: String
    var geschlecht: String
    var abteilung: String? // "Männer" oder "Frauen"
    var vereinID: String?
    var nationalitaet: [String]?
    var geburtsdatum: Date?
    var alter: Int?
    var kontaktTelefon: String?
    var kontaktEmail: String?
    var adresse: String?
    var liga: String?
    var vertragBis: Date?
    var vertragsOptionen: String?
    var gehalt: Double?
    var schuhgroesse: Int?
    var schuhmarke: String?
    var starkerFuss: String?
    var groesse: Int?
    var gewicht: Int?
    var positionFeld: [String]?
    var sprachen: [String]?
    var lizenz: String?
    var nationalmannschaft: String?
    var profilbildURL: String?
    var transfermarktID: String?
    var userID: String?
    var createdBy: String? // Neues Feld für die Mitarbeiter-Zuordnung

    // Expliziter Initialisierer
    init(
        id: String? = nil,
        typ: String,
        name: String,
        vorname: String,
        geschlecht: String,
        abteilung: String? = nil,
        vereinID: String? = nil,
        nationalitaet: [String]? = nil,
        geburtsdatum: Date? = nil,
        alter: Int? = nil,
        kontaktTelefon: String? = nil,
        kontaktEmail: String? = nil,
        adresse: String? = nil,
        liga: String? = nil,
        vertragBis: Date? = nil,
        vertragsOptionen: String? = nil,
        gehalt: Double? = nil,
        schuhgroesse: Int? = nil,
        schuhmarke: String? = nil,
        starkerFuss: String? = nil,
        groesse: Int? = nil,
        gewicht: Int? = nil,
        positionFeld: [String]? = nil,
        sprachen: [String]? = nil,
        lizenz: String? = nil,
        nationalmannschaft: String? = nil,
        profilbildURL: String? = nil,
        transfermarktID: String? = nil,
        userID: String? = nil,
        createdBy: String? = nil
    ) {
        self.id = id
        self.typ = typ
        self.name = name
        self.vorname = vorname
        self.geschlecht = geschlecht
        self.abteilung = abteilung
        self.vereinID = vereinID
        self.nationalitaet = nationalitaet
        self.geburtsdatum = geburtsdatum
        self.alter = alter
        self.kontaktTelefon = kontaktTelefon
        self.kontaktEmail = kontaktEmail
        self.adresse = adresse
        self.liga = liga
        self.vertragBis = vertragBis
        self.vertragsOptionen = vertragsOptionen
        self.gehalt = gehalt
        self.schuhgroesse = schuhgroesse
        self.schuhmarke = schuhmarke
        self.starkerFuss = starkerFuss
        self.groesse = groesse
        self.gewicht = gewicht
        self.positionFeld = positionFeld
        self.sprachen = sprachen
        self.lizenz = lizenz
        self.nationalmannschaft = nationalmannschaft
        self.profilbildURL = profilbildURL
        self.transfermarktID = transfermarktID
        self.userID = userID
        self.createdBy = createdBy
    }

    static func == (lhs: Client, rhs: Client) -> Bool {
        return lhs.id == rhs.id &&
               lhs.typ == rhs.typ &&
               lhs.name == rhs.name &&
               lhs.vorname == rhs.vorname &&
               lhs.geschlecht == rhs.geschlecht &&
               lhs.abteilung == rhs.abteilung &&
               lhs.vereinID == rhs.vereinID &&
               lhs.nationalitaet == rhs.nationalitaet &&
               lhs.geburtsdatum == rhs.geburtsdatum &&
               lhs.alter == rhs.alter &&
               lhs.kontaktTelefon == rhs.kontaktTelefon &&
               lhs.kontaktEmail == rhs.kontaktEmail &&
               lhs.adresse == rhs.adresse &&
               lhs.liga == rhs.liga &&
               lhs.vertragBis == rhs.vertragBis &&
               lhs.vertragsOptionen == rhs.vertragsOptionen &&
               lhs.gehalt == rhs.gehalt &&
               lhs.schuhgroesse == rhs.schuhgroesse &&
               lhs.schuhmarke == rhs.schuhmarke &&
               lhs.starkerFuss == rhs.starkerFuss &&
               lhs.groesse == rhs.groesse &&
               lhs.gewicht == rhs.gewicht &&
               lhs.positionFeld == rhs.positionFeld &&
               lhs.sprachen == rhs.sprachen &&
               lhs.lizenz == rhs.lizenz &&
               lhs.nationalmannschaft == rhs.nationalmannschaft &&
               lhs.profilbildURL == rhs.profilbildURL &&
               lhs.transfermarktID == rhs.transfermarktID &&
               lhs.userID == rhs.userID &&
               lhs.createdBy == rhs.createdBy
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(typ)
        hasher.combine(name)
        hasher.combine(vorname)
        hasher.combine(geschlecht)
        hasher.combine(abteilung)
        hasher.combine(vereinID)
        hasher.combine(nationalitaet)
        hasher.combine(geburtsdatum)
        hasher.combine(alter)
        hasher.combine(kontaktTelefon)
        hasher.combine(kontaktEmail)
        hasher.combine(adresse)
        hasher.combine(liga)
        hasher.combine(vertragBis)
        hasher.combine(vertragsOptionen)
        hasher.combine(gehalt)
        hasher.combine(schuhgroesse)
        hasher.combine(schuhmarke)
        hasher.combine(starkerFuss)
        hasher.combine(groesse)
        hasher.combine(gewicht)
        hasher.combine(positionFeld)
        hasher.combine(sprachen)
        hasher.combine(lizenz)
        hasher.combine(nationalmannschaft)
        hasher.combine(profilbildURL)
        hasher.combine(transfermarktID)
        hasher.combine(userID)
        hasher.combine(createdBy)
    }
}

struct Funktionär: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var name: String
    var vorname: String
    var abteilung: String? // "Männer" oder "Frauen"
    var vereinID: String?
    var kontaktTelefon: String?
    var kontaktEmail: String?
    var adresse: String?
    var clients: [String]?
    var profilbildURL: String?
    var geburtsdatum: Date?
    var positionImVerein: String?
    var mannschaft: String?
    var nationalitaet: [String]? // Hinzugefügt

    // Expliziter Initialisierer
    init(
        id: String? = nil,
        name: String,
        vorname: String,
        abteilung: String? = nil,
        vereinID: String? = nil,
        kontaktTelefon: String? = nil,
        kontaktEmail: String? = nil,
        adresse: String? = nil,
        clients: [String]? = nil,
        profilbildURL: String? = nil,
        geburtsdatum: Date? = nil,
        positionImVerein: String? = nil,
        mannschaft: String? = nil,
        nationalitaet: [String]? = nil
    ) {
        self.id = id
        self.name = name
        self.vorname = vorname
        self.abteilung = abteilung
        self.vereinID = vereinID
        self.kontaktTelefon = kontaktTelefon
        self.kontaktEmail = kontaktEmail
        self.adresse = adresse
        self.clients = clients
        self.profilbildURL = profilbildURL
        self.geburtsdatum = geburtsdatum
        self.positionImVerein = positionImVerein
        self.mannschaft = mannschaft
        self.nationalitaet = nationalitaet
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case vorname
        case abteilung
        case vereinID
        case kontaktTelefon
        case kontaktEmail
        case adresse
        case clients
        case profilbildURL
        case geburtsdatum
        case positionImVerein
        case mannschaft
        case nationalitaet
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(String.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.vorname = try container.decode(String.self, forKey: .vorname)
        
        // Benutzerdefinierte Dekodierung für abteilung
        if let abteilungString = try? container.decodeIfPresent(String.self, forKey: .abteilung) {
            self.abteilung = abteilungString
        } else if let abteilungArray = try? container.decodeIfPresent([String].self, forKey: .abteilung) {
            self.abteilung = abteilungArray.first
        } else {
            self.abteilung = nil
        }

        self.vereinID = try container.decodeIfPresent(String.self, forKey: .vereinID)
        self.kontaktTelefon = try container.decodeIfPresent(String.self, forKey: .kontaktTelefon)
        self.kontaktEmail = try container.decodeIfPresent(String.self, forKey: .kontaktEmail)
        self.adresse = try container.decodeIfPresent(String.self, forKey: .adresse)
        self.clients = try container.decodeIfPresent([String].self, forKey: .clients)
        self.profilbildURL = try container.decodeIfPresent(String.self, forKey: .profilbildURL)
        self.geburtsdatum = try container.decodeIfPresent(Date.self, forKey: .geburtsdatum)
        self.positionImVerein = try container.decodeIfPresent(String.self, forKey: .positionImVerein)
        self.mannschaft = try container.decodeIfPresent(String.self, forKey: .mannschaft)
        self.nationalitaet = try container.decodeIfPresent([String].self, forKey: .nationalitaet)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(vorname, forKey: .vorname)
        try container.encodeIfPresent(abteilung, forKey: .abteilung)
        try container.encodeIfPresent(vereinID, forKey: .vereinID)
        try container.encodeIfPresent(kontaktTelefon, forKey: .kontaktTelefon)
        try container.encodeIfPresent(kontaktEmail, forKey: .kontaktEmail)
        try container.encodeIfPresent(adresse, forKey: .adresse)
        try container.encodeIfPresent(clients, forKey: .clients)
        try container.encodeIfPresent(profilbildURL, forKey: .profilbildURL)
        try container.encodeIfPresent(geburtsdatum, forKey: .geburtsdatum)
        try container.encodeIfPresent(positionImVerein, forKey: .positionImVerein)
        try container.encodeIfPresent(mannschaft, forKey: .mannschaft)
        try container.encodeIfPresent(nationalitaet, forKey: .nationalitaet)
    }

    static func == (lhs: Funktionär, rhs: Funktionär) -> Bool {
        return lhs.id == rhs.id &&
               lhs.name == rhs.name &&
               lhs.vorname == rhs.vorname &&
               lhs.abteilung == rhs.abteilung &&
               lhs.vereinID == rhs.vereinID &&
               lhs.kontaktTelefon == rhs.kontaktTelefon &&
               lhs.kontaktEmail == rhs.kontaktEmail &&
               lhs.adresse == rhs.adresse &&
               lhs.clients == rhs.clients &&
               lhs.profilbildURL == rhs.profilbildURL &&
               lhs.geburtsdatum == rhs.geburtsdatum &&
               lhs.positionImVerein == rhs.positionImVerein &&
               lhs.mannschaft == rhs.mannschaft &&
               lhs.nationalitaet == rhs.nationalitaet
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
        hasher.combine(vorname)
        hasher.combine(abteilung)
        hasher.combine(vereinID)
        hasher.combine(kontaktTelefon)
        hasher.combine(kontaktEmail)
        hasher.combine(adresse)
        hasher.combine(clients)
        hasher.combine(profilbildURL)
        hasher.combine(geburtsdatum)
        hasher.combine(positionImVerein)
        hasher.combine(mannschaft)
        hasher.combine(nationalitaet)
    }
}

struct Contract: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var clientID: String?
    var vereinID: String?
    var startDatum: Date
    var endDatum: Date?
    var gehalt: Double?
    var vertragsdetails: String?

    static func == (lhs: Contract, rhs: Contract) -> Bool {
        return lhs.id == rhs.id &&
               lhs.clientID == rhs.clientID &&
               lhs.vereinID == rhs.vereinID &&
               lhs.startDatum == rhs.startDatum &&
               lhs.endDatum == rhs.endDatum &&
               lhs.gehalt == rhs.gehalt &&
               lhs.vertragsdetails == rhs.vertragsdetails
    }
}

struct Transfer: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var clientID: String?
    var vonVereinID: String?
    var zuVereinID: String?
    var datum: Date
    var ablösesumme: Double?
    var isAblösefrei: Bool
    var transferdetails: String?

    init(
        id: String? = nil,
        clientID: String? = nil,
        vonVereinID: String? = nil,
        zuVereinID: String? = nil,
        datum: Date = Date(),
        ablösesumme: Double? = nil,
        isAblösefrei: Bool = false,
        transferdetails: String? = nil
    ) {
        self.id = id
        self.clientID = clientID
        self.vonVereinID = vonVereinID
        self.zuVereinID = zuVereinID
        self.datum = datum
        self.ablösesumme = ablösesumme
        self.isAblösefrei = isAblösefrei
        self.transferdetails = transferdetails
    }

    static func == (lhs: Transfer, rhs: Transfer) -> Bool {
        return lhs.id == rhs.id &&
               lhs.clientID == rhs.clientID &&
               lhs.vonVereinID == rhs.vonVereinID &&
               lhs.zuVereinID == rhs.zuVereinID &&
               lhs.datum == rhs.datum &&
               lhs.ablösesumme == rhs.ablösesumme &&
               lhs.isAblösefrei == rhs.isAblösefrei &&
               lhs.transferdetails == rhs.transferdetails
    }
}

struct Club: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var name: String
    var mensDepartment: Department? // Männerabteilung
    var womensDepartment: Department? // Frauenabteilung
    var sharedInfo: SharedInfo?

    struct Department: Codable, Hashable {
        var league: String?
        var adresse: String?
        var kontaktTelefon: String?
        var kontaktEmail: String?
        var funktionäre: [FunktionärReference]?
        var clients: [String]?
    }

    struct SharedInfo: Codable, Hashable {
        var land: String?
        var memberCount: Int?
        var founded: String?
        var logoURL: String?
    }

    struct FunktionärReference: Codable, Hashable {
        var id: String
        var name: String
        var vorname: String
        var positionImVerein: String?
    }

    // Neue Methode abteilungForGender
    func abteilungForGender(_ geschlecht: String) -> String? {
        if geschlecht == "männlich" {
            return mensDepartment != nil ? "Männer" : nil
        } else if geschlecht == "weiblich" {
            return womensDepartment != nil ? "Frauen" : nil
        }
        return nil
    }

    static func == (lhs: Club, rhs: Club) -> Bool {
        return lhs.id == rhs.id &&
               lhs.name == rhs.name &&
               lhs.mensDepartment == rhs.mensDepartment &&
               lhs.womensDepartment == rhs.womensDepartment &&
               lhs.sharedInfo == rhs.sharedInfo
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
        hasher.combine(mensDepartment)
        hasher.combine(womensDepartment)
        hasher.combine(sharedInfo)
    }
}

struct Match: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var heimVereinID: String?
    var gastVereinID: String?
    var datum: Date
    var ergebnis: String?
    var stadion: String?

    static func == (lhs: Match, rhs: Match) -> Bool {
        return lhs.id == rhs.id &&
               lhs.heimVereinID == rhs.heimVereinID &&
               lhs.gastVereinID == rhs.gastVereinID &&
               lhs.datum == rhs.datum &&
               lhs.ergebnis == rhs.ergebnis &&
               lhs.stadion == rhs.stadion
    }
}

struct Sponsor: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var name: String
    var category: String?
    var contacts: [Contact]?
    var kontaktTelefon: String?
    var kontaktEmail: String?
    var adresse: String?
    var gesponsorteVereine: [String]?

    struct Contact: Codable, Identifiable, Equatable {
        var id: String = UUID().uuidString
        var name: String
        var region: String
        var telefon: String?
        var email: String?
    }

    static func == (lhs: Sponsor, rhs: Sponsor) -> Bool {
        return lhs.id == rhs.id &&
               lhs.name == rhs.name &&
               lhs.category == rhs.category &&
               lhs.contacts == rhs.contacts &&
               lhs.kontaktTelefon == rhs.kontaktTelefon &&
               lhs.kontaktEmail == rhs.kontaktEmail &&
               lhs.adresse == rhs.adresse &&
               lhs.gesponsorteVereine == rhs.gesponsorteVereine
    }
}

struct Activity: Identifiable, Codable {
    @DocumentID var id: String?
    var clientID: String
    var description: String
    var timestamp: Date
    var category: String?
    var comments: [String]?

    enum CodingKeys: String, CodingKey {
        case id
        case clientID
        case description
        case timestamp
        case category
        case comments
    }

    init(id: String? = nil, clientID: String, description: String, timestamp: Date, category: String? = nil, comments: [String]? = nil) {
        self.id = id
        self.clientID = clientID
        self.description = description
        self.timestamp = timestamp
        self.category = category
        self.comments = comments
    }
}

struct Message: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var senderID: String
    var senderEmail: String
    var content: String?
    var fileURL: String?
    var fileType: String?
    var timestamp: Date
    var readBy: [String]

    static func == (lhs: Message, rhs: Message) -> Bool {
        return lhs.id == rhs.id
    }
}

struct Chat: Identifiable, Codable, Equatable, Hashable {
    @DocumentID var id: String?
    var participantIDs: [String]
    var lastMessage: String?
    var lastMessageTimestamp: Date?
    var isArchived: Bool?

    static func == (lhs: Chat, rhs: Chat) -> Bool {
        return lhs.id == rhs.id &&
               lhs.participantIDs == rhs.participantIDs &&
               lhs.lastMessage == rhs.lastMessage &&
               lhs.lastMessageTimestamp == rhs.lastMessageTimestamp &&
               lhs.isArchived == rhs.isArchived
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// Neue PlayerData-Struktur hinzugefügt
struct PlayerData {
    var name: String?
    var position: String?
    var nationalitaet: [String]?
    var geburtsdatum: Date?
    var vereinID: String?
    var contractEnd: Date?
}
struct TransferProcess: Identifiable, Codable {
    @DocumentID var id: String?
    var clientID: String
    var vereinID: String
    var status: String // z. B. "in Bearbeitung", "abgeschlossen", "abgebrochen"
    var startDatum: Date
    var schritte: [Step] // Liste der Schritte
    var erinnerungen: [Reminder]? // Optional: Liste der Erinnerungen
    var hinweise: [Note]? // Optional: Liste der Hinweise

    init(id: String? = nil, clientID: String, vereinID: String, status: String = "in Bearbeitung", startDatum: Date = Date(), schritte: [Step] = [], erinnerungen: [Reminder]? = nil, hinweise: [Note]? = nil) {
        self.id = id
        self.clientID = clientID
        self.vereinID = vereinID
        self.status = status
        self.startDatum = startDatum
        self.schritte = schritte
        self.erinnerungen = erinnerungen
        self.hinweise = hinweise
    }
}

// Modell für einzelne Schritte im Transferprozess
struct Step: Identifiable, Codable {
    var id: String = UUID().uuidString // Eindeutige ID für jeden Schritt
    var typ: String // z. B. "Initiale Kontaktaufnahme", "Kennenlerngespräch"
    var status: String // z. B. "geplant", "abgeschlossen"
    var datum: Date
    var notizen: String?

    init(id: String = UUID().uuidString, typ: String, status: String = "geplant", datum: Date = Date(), notizen: String? = nil) {
        self.id = id
        self.typ = typ
        self.status = status
        self.datum = datum
        self.notizen = notizen
    }
}

// Modell für Erinnerungen
struct Reminder: Identifiable, Codable {
    var id: String = UUID().uuidString
    var datum: Date
    var beschreibung: String
}

// Modell für Hinweise
struct Note: Identifiable, Codable {
    var id: String = UUID().uuidString
    var beschreibung: String
}
