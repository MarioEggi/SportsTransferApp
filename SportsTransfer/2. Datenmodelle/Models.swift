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
    var createdBy: String?
    var konditionen: String? // Gehalt und Vertragsdetails
    var art: String? // z. B. "Vereinswechsel", "Vertragsverlängerung"
    var spielerCV: String? // URL zu Spieler-CV
    var video: String? // URL zu Video
    var spielstil: String? // "offensiv" oder "defensiv"
    var tempo: Int? // 0-100 (Geschwindigkeit)
    var zweikampfstärke: Int? // 0-100
    var einsGegenEins: Int?
    var globalID: String?

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
        createdBy: String? = nil,
        konditionen: String? = nil,
        art: String? = nil,
        spielerCV: String? = nil,
        video: String? = nil,
        spielstil: String? = nil,
        tempo: Int? = nil,
        zweikampfstärke: Int? = nil,
        einsGegenEins: Int? = nil,
        globalID: String? = nil
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
        self.konditionen = konditionen
        self.art = art
        self.spielerCV = spielerCV
        self.video = video
        self.spielstil = spielstil
        self.tempo = tempo
        self.zweikampfstärke = zweikampfstärke
        self.einsGegenEins = einsGegenEins
        self.globalID = globalID
    }

    enum CodingKeys: String, CodingKey {
        case id
        case typ
        case name
        case vorname
        case geschlecht
        case abteilung
        case vereinID
        case nationalitaet
        case geburtsdatum
        case alter
        case kontaktTelefon
        case kontaktEmail
        case adresse
        case liga
        case vertragBis
        case vertragsOptionen
        case gehalt
        case schuhgroesse
        case schuhmarke
        case starkerFuss
        case groesse
        case gewicht
        case positionFeld
        case sprachen
        case lizenz
        case nationalmannschaft
        case profilbildURL
        case transfermarktID
        case userID
        case createdBy
        case konditionen
        case art
        case spielerCV
        case video
        case spielstil
        case tempo
        case zweikampfstärke
        case einsGegenEins
        case globalID
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(String.self, forKey: .id)
        self.typ = try container.decode(String.self, forKey: .typ)
        self.name = try container.decode(String.self, forKey: .name)
        self.vorname = try container.decode(String.self, forKey: .vorname)
        self.geschlecht = try container.decode(String.self, forKey: .geschlecht)
        self.abteilung = try container.decodeIfPresent(String.self, forKey: .abteilung)
        self.vereinID = try container.decodeIfPresent(String.self, forKey: .vereinID)
        self.nationalitaet = try container.decodeIfPresent([String].self, forKey: .nationalitaet)
        self.geburtsdatum = try container.decodeIfPresent(Date.self, forKey: .geburtsdatum)
        self.alter = try container.decodeIfPresent(Int.self, forKey: .alter)
        self.kontaktTelefon = try container.decodeIfPresent(String.self, forKey: .kontaktTelefon)
        self.kontaktEmail = try container.decodeIfPresent(String.self, forKey: .kontaktEmail)
        self.adresse = try container.decodeIfPresent(String.self, forKey: .adresse)
        self.liga = try container.decodeIfPresent(String.self, forKey: .liga)
        self.vertragBis = try container.decodeIfPresent(Date.self, forKey: .vertragBis)
        self.vertragsOptionen = try container.decodeIfPresent(String.self, forKey: .vertragsOptionen)
        self.gehalt = try container.decodeIfPresent(Double.self, forKey: .gehalt)
        self.schuhgroesse = try container.decodeIfPresent(Int.self, forKey: .schuhgroesse)
        self.schuhmarke = try container.decodeIfPresent(String.self, forKey: .schuhmarke)
        self.starkerFuss = try container.decodeIfPresent(String.self, forKey: .starkerFuss)
        self.groesse = try container.decodeIfPresent(Int.self, forKey: .groesse)
        self.gewicht = try container.decodeIfPresent(Int.self, forKey: .gewicht)
        self.positionFeld = try container.decodeIfPresent([String].self, forKey: .positionFeld)
        self.sprachen = try container.decodeIfPresent([String].self, forKey: .sprachen)
        self.lizenz = try container.decodeIfPresent(String.self, forKey: .lizenz)
        self.nationalmannschaft = try container.decodeIfPresent(String.self, forKey: .nationalmannschaft)
        self.profilbildURL = try container.decodeIfPresent(String.self, forKey: .profilbildURL)
        self.transfermarktID = try container.decodeIfPresent(String.self, forKey: .transfermarktID)
        self.userID = try container.decodeIfPresent(String.self, forKey: .userID)
        self.createdBy = try container.decodeIfPresent(String.self, forKey: .createdBy)
        self.konditionen = try container.decodeIfPresent(String.self, forKey: .konditionen)
        self.art = try container.decodeIfPresent(String.self, forKey: .art)
        self.spielerCV = try container.decodeIfPresent(String.self, forKey: .spielerCV)
        self.video = try container.decodeIfPresent(String.self, forKey: .video)
        self.spielstil = try container.decodeIfPresent(String.self, forKey: .spielstil)
        self.globalID = try container.decodeIfPresent(String.self, forKey: .globalID)

        do {
            if container.contains(.tempo) {
                if let tempoString = try? container.decode(String.self, forKey: .tempo), tempoString.isEmpty {
                    self.tempo = nil
                } else {
                    self.tempo = try container.decodeIfPresent(Int.self, forKey: .tempo)
                }
            } else {
                self.tempo = nil
            }
        } catch {
            print("Fehler beim Dekodieren von tempo: \(error)")
            self.tempo = nil
        }

        do {
            if container.contains(.zweikampfstärke) {
                if let zweikampfstärkeString = try? container.decode(String.self, forKey: .zweikampfstärke), zweikampfstärkeString.isEmpty {
                    self.zweikampfstärke = nil
                } else {
                    self.zweikampfstärke = try container.decodeIfPresent(Int.self, forKey: .zweikampfstärke)
                }
            } else {
                self.zweikampfstärke = nil
            }
        } catch {
            print("Fehler beim Dekodieren von zweikampfstärke: \(error)")
            self.zweikampfstärke = nil
        }

        do {
            if container.contains(.einsGegenEins) {
                if let einsGegenEinsString = try? container.decode(String.self, forKey: .einsGegenEins), einsGegenEinsString.isEmpty {
                    self.einsGegenEins = nil
                } else {
                    self.einsGegenEins = try container.decodeIfPresent(Int.self, forKey: .einsGegenEins)
                }
            } else {
                self.einsGegenEins = nil
            }
        } catch {
            print("Fehler beim Dekodieren von einsGegenEins: \(error)")
            self.einsGegenEins = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(typ, forKey: .typ)
        try container.encode(name, forKey: .name)
        try container.encode(vorname, forKey: .vorname)
        try container.encode(geschlecht, forKey: .geschlecht)
        try container.encodeIfPresent(abteilung, forKey: .abteilung)
        try container.encodeIfPresent(vereinID, forKey: .vereinID)
        try container.encodeIfPresent(nationalitaet, forKey: .nationalitaet)
        try container.encodeIfPresent(geburtsdatum, forKey: .geburtsdatum)
        try container.encodeIfPresent(alter, forKey: .alter)
        try container.encodeIfPresent(kontaktTelefon, forKey: .kontaktTelefon)
        try container.encodeIfPresent(kontaktEmail, forKey: .kontaktEmail)
        try container.encodeIfPresent(adresse, forKey: .adresse)
        try container.encodeIfPresent(liga, forKey: .liga)
        try container.encodeIfPresent(vertragBis, forKey: .vertragBis)
        try container.encodeIfPresent(vertragsOptionen, forKey: .vertragsOptionen)
        try container.encodeIfPresent(gehalt, forKey: .gehalt)
        try container.encodeIfPresent(schuhgroesse, forKey: .schuhgroesse)
        try container.encodeIfPresent(schuhmarke, forKey: .schuhmarke)
        try container.encodeIfPresent(starkerFuss, forKey: .starkerFuss)
        try container.encodeIfPresent(groesse, forKey: .groesse)
        try container.encodeIfPresent(gewicht, forKey: .gewicht)
        try container.encodeIfPresent(positionFeld, forKey: .positionFeld)
        try container.encodeIfPresent(sprachen, forKey: .sprachen)
        try container.encodeIfPresent(lizenz, forKey: .lizenz)
        try container.encodeIfPresent(nationalmannschaft, forKey: .nationalmannschaft)
        try container.encodeIfPresent(profilbildURL, forKey: .profilbildURL)
        try container.encodeIfPresent(transfermarktID, forKey: .transfermarktID)
        try container.encodeIfPresent(userID, forKey: .userID)
        try container.encodeIfPresent(createdBy, forKey: .createdBy)
        try container.encodeIfPresent(konditionen, forKey: .konditionen)
        try container.encodeIfPresent(art, forKey: .art)
        try container.encodeIfPresent(spielerCV, forKey: .spielerCV)
        try container.encodeIfPresent(video, forKey: .video)
        try container.encodeIfPresent(spielstil, forKey: .spielstil)
        try container.encodeIfPresent(tempo, forKey: .tempo)
        try container.encodeIfPresent(zweikampfstärke, forKey: .zweikampfstärke)
        try container.encodeIfPresent(einsGegenEins, forKey: .einsGegenEins)
        try container.encodeIfPresent(globalID, forKey: .globalID)
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
               lhs.createdBy == rhs.createdBy &&
               lhs.konditionen == rhs.konditionen &&
               lhs.art == rhs.art &&
               lhs.spielerCV == rhs.spielerCV &&
               lhs.video == rhs.video &&
               lhs.globalID == rhs.globalID
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
        hasher.combine(konditionen)
        hasher.combine(art)
        hasher.combine(spielerCV)
        hasher.combine(video)
        hasher.combine(globalID)
    }
}

struct Funktionär: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var name: String
    var vorname: String
    var abteilung: String?
    var vereinID: String?
    var kontaktTelefon: String?
    var kontaktEmail: String?
    var adresse: String?
    var clients: [String]?
    var profilbildURL: String?
    var geburtsdatum: Date?
    var positionImVerein: String?
    var mannschaft: String?
    var nationalitaet: [String]?
    var functionaryDocumentURL: String?

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
        nationalitaet: [String]? = nil,
        functionaryDocumentURL: String? = nil
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
        self.functionaryDocumentURL = functionaryDocumentURL
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
        case functionaryDocumentURL
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(String.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.vorname = try container.decode(String.self, forKey: .vorname)
        
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
        self.functionaryDocumentURL = try container.decodeIfPresent(String.self, forKey: .functionaryDocumentURL)
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
        try container.encodeIfPresent(functionaryDocumentURL, forKey: .functionaryDocumentURL)
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

struct TransferProcess: Identifiable, Codable, Hashable, Equatable {
    @DocumentID var id: String?
    var clientID: String
    var vereinID: String
    var status: String // z. B. "in Bearbeitung", "abgeschlossen", "abgebrochen"
    var startDatum: Date
    var schritte: [Step]
    var erinnerungen: [Reminder]?
    var hinweise: [Note]?
    var transferDetails: TransferDetails?
    var mitarbeiterID: String?
    var priority: Int? // 1-5
    var konditionen: String?
    var art: String? // "Vereinswechsel", "Vertragsverlängerung"
    var title: String?
    var sponsorID: String?
    var funktionärID: String? // Verknüpfung mit Funktionär
    var kontaktInitiator: String? // "Verein", "Wir", "Sponsor"
    var abteilung: String? // "Frauen", "Männer"
    var gesuchtePositionen: [String]? // z. B. ["Innenverteidigerin", "Mittelfeldspielerin"]
    var liga: String?

    init(
        id: String? = nil,
        clientID: String,
        vereinID: String,
        status: String = "in Bearbeitung",
        startDatum: Date = Date(),
        schritte: [Step] = [],
        erinnerungen: [Reminder]? = nil,
        hinweise: [Note]? = nil,
        transferDetails: TransferDetails? = nil,
        mitarbeiterID: String? = nil,
        priority: Int? = nil,
        konditionen: String? = nil,
        art: String? = nil,
        title: String? = nil,
        sponsorID: String? = nil,
        funktionärID: String? = nil,
        kontaktInitiator: String? = nil,
        abteilung: String? = nil,
        gesuchtePositionen: [String]? = nil
    ) {
        self.id = id
        self.clientID = clientID
        self.vereinID = vereinID
        self.status = status
        self.startDatum = startDatum
        self.schritte = schritte
        self.erinnerungen = erinnerungen
        self.hinweise = hinweise
        self.transferDetails = transferDetails
        self.mitarbeiterID = mitarbeiterID
        self.priority = priority
        self.konditionen = konditionen
        self.art = art
        self.title = title
        self.sponsorID = sponsorID
        self.funktionärID = funktionärID
        self.kontaktInitiator = kontaktInitiator
        self.abteilung = abteilung
        self.gesuchtePositionen = gesuchtePositionen
    }

    enum CodingKeys: String, CodingKey {
        case id, clientID, vereinID, status, startDatum, schritte, erinnerungen, hinweise, transferDetails
        case mitarbeiterID, priority, konditionen, art, title, sponsorID
        case funktionärID, kontaktInitiator, abteilung, gesuchtePositionen
    }

    static func == (lhs: TransferProcess, rhs: TransferProcess) -> Bool {
        return lhs.id == rhs.id &&
               lhs.clientID == rhs.clientID &&
               lhs.vereinID == rhs.vereinID &&
               lhs.status == rhs.status &&
               lhs.startDatum == rhs.startDatum &&
               lhs.schritte == rhs.schritte &&
               lhs.erinnerungen == rhs.erinnerungen &&
               lhs.hinweise == rhs.hinweise &&
               lhs.transferDetails == rhs.transferDetails &&
               lhs.mitarbeiterID == rhs.mitarbeiterID &&
               lhs.priority == rhs.priority &&
               lhs.konditionen == rhs.konditionen &&
               lhs.art == rhs.art &&
               lhs.title == rhs.title &&
               lhs.sponsorID == rhs.sponsorID &&
               lhs.funktionärID == rhs.funktionärID &&
               lhs.kontaktInitiator == rhs.kontaktInitiator &&
               lhs.abteilung == rhs.abteilung &&
               lhs.gesuchtePositionen == rhs.gesuchtePositionen
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(clientID)
        hasher.combine(vereinID)
        hasher.combine(status)
        hasher.combine(startDatum)
        hasher.combine(schritte)
        hasher.combine(erinnerungen)
        hasher.combine(hinweise)
        hasher.combine(transferDetails)
        hasher.combine(mitarbeiterID)
        hasher.combine(priority)
        hasher.combine(konditionen)
        hasher.combine(art)
        hasher.combine(title)
        hasher.combine(sponsorID)
        hasher.combine(funktionärID)
        hasher.combine(kontaktInitiator)
        hasher.combine(abteilung)
        hasher.combine(gesuchtePositionen)
    }
}

struct Step: Identifiable, Codable, Equatable, Hashable {
    var id: String = UUID().uuidString
    var typ: String // z. B. "initialeKontaktaufnahme", "vertragVerhandeln"
    var status: String // z. B. "geplant", "abgeschlossen"
    var datum: Date
    var notizen: String?
    var erfolgschance: Int? // Erfolgschancen (0-100)
    var checkliste: [String]? // z. B. ["CV bereit", "Video hochgeladen"]
    var funktionär: String?
    var title: String?
    var entscheidung: String? // Neu: "Ja", "Nein", "Vielleicht"
    
    enum CodingKeys: String, CodingKey {
        case id, typ, status, datum, notizen, erfolgschance, checkliste, funktionär, title, entscheidung
    }
    
    static func == (lhs: Step, rhs: Step) -> Bool {
        return lhs.id == rhs.id &&
               lhs.typ == rhs.typ &&
               lhs.status == rhs.status &&
               lhs.datum == rhs.datum &&
               lhs.notizen == rhs.notizen &&
               lhs.erfolgschance == rhs.erfolgschance &&
               lhs.checkliste == rhs.checkliste &&
               lhs.funktionär == rhs.funktionär &&
               lhs.title == rhs.title &&
               lhs.entscheidung == rhs.entscheidung
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(typ)
        hasher.combine(status)
        hasher.combine(datum)
        hasher.combine(notizen)
        hasher.combine(erfolgschance)
        hasher.combine(checkliste)
        hasher.combine(funktionär)
        hasher.combine(title)
        hasher.combine(entscheidung)
    }
}

struct SponsoringProcess: Identifiable, Codable, Hashable, Equatable {
    @DocumentID var id: String?
    var clientID: String
    var sponsorID: String
    var status: String
    var startDatum: Date
    var schritte: [Step]
    var erinnerungen: [Reminder]?
    var hinweise: [Note]?
    var mitarbeiterID: String?
    var priority: Int?
    var konditionen: String?
    var art: String?
    var title: String?
    var funktionärID: String?
    var kontaktInitiator: String?

    init(
        id: String? = nil,
        clientID: String,
        sponsorID: String,
        status: String = "in Bearbeitung",
        startDatum: Date = Date(),
        schritte: [Step] = [],
        erinnerungen: [Reminder]? = nil,
        hinweise: [Note]? = nil,
        mitarbeiterID: String? = nil,
        priority: Int? = nil,
        konditionen: String? = nil,
        art: String? = nil,
        title: String? = nil,
        funktionärID: String? = nil,
        kontaktInitiator: String? = nil
    ) {
        self.id = id
        self.clientID = clientID
        self.sponsorID = sponsorID
        self.status = status
        self.startDatum = startDatum
        self.schritte = schritte
        self.erinnerungen = erinnerungen
        self.hinweise = hinweise
        self.mitarbeiterID = mitarbeiterID
        self.priority = priority
        self.konditionen = konditionen
        self.art = art
        self.title = title
        self.funktionärID = funktionärID
        self.kontaktInitiator = kontaktInitiator
    }

    enum CodingKeys: String, CodingKey {
        case id, clientID, sponsorID, status, startDatum, schritte, erinnerungen, hinweise
        case mitarbeiterID, priority, konditionen, art, title, funktionärID, kontaktInitiator
    }

    static func == (lhs: SponsoringProcess, rhs: SponsoringProcess) -> Bool {
        return lhs.id == rhs.id &&
               lhs.clientID == rhs.clientID &&
               lhs.sponsorID == rhs.sponsorID &&
               lhs.status == rhs.status &&
               lhs.startDatum == rhs.startDatum &&
               lhs.schritte == rhs.schritte &&
               lhs.erinnerungen == rhs.erinnerungen &&
               lhs.hinweise == rhs.hinweise &&
               lhs.mitarbeiterID == rhs.mitarbeiterID &&
               lhs.priority == rhs.priority &&
               lhs.konditionen == rhs.konditionen &&
               lhs.art == rhs.art &&
               lhs.title == rhs.title &&
               lhs.funktionärID == rhs.funktionärID &&
               lhs.kontaktInitiator == rhs.kontaktInitiator
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(clientID)
        hasher.combine(sponsorID)
        hasher.combine(status)
        hasher.combine(startDatum)
        hasher.combine(schritte)
        hasher.combine(erinnerungen)
        hasher.combine(hinweise)
        hasher.combine(mitarbeiterID)
        hasher.combine(priority)
        hasher.combine(konditionen)
        hasher.combine(art)
        hasher.combine(title)
        hasher.combine(funktionärID)
        hasher.combine(kontaktInitiator)
    }
}

struct ProfileRequest: Identifiable, Codable, Hashable, Equatable {
    @DocumentID var id: String?
    var vereinID: String
    var funktionärID: String?
    var abteilung: String // "Frauen", "Männer"
    var gesuchtePositionen: [PositionCriteria] // Liste mit Kriterien
    var status: String // z. B. "offen", "in Bearbeitung", "abgeschlossen"
    var datum: Date
    var kontaktInitiator: String? // "Verein", "Wir"

    struct PositionCriteria: Codable, Hashable {
        var position: String // z. B. "Innenverteidigerin"
        var alterMin: Int? // Mindestalter
        var alterMax: Int? // Höchstalter
        var groesseMin: Int? // Mindestgröße in cm
        var tempoMin: Int? // Mindesttempo (0-100)
        var weitereKriterien: String? // z. B. "technisch stark"
    }

    init(
        id: String? = nil,
        vereinID: String,
        funktionärID: String? = nil,
        abteilung: String,
        gesuchtePositionen: [PositionCriteria],
        status: String = "offen",
        datum: Date = Date(),
        kontaktInitiator: String? = nil
    ) {
        self.id = id
        self.vereinID = vereinID
        self.funktionärID = funktionärID
        self.abteilung = abteilung
        self.gesuchtePositionen = gesuchtePositionen
        self.status = status
        self.datum = datum
        self.kontaktInitiator = kontaktInitiator
    }

    enum CodingKeys: String, CodingKey {
        case id, vereinID, funktionärID, abteilung, gesuchtePositionen, status, datum, kontaktInitiator
    }

    static func == (lhs: ProfileRequest, rhs: ProfileRequest) -> Bool {
        return lhs.id == rhs.id &&
               lhs.vereinID == rhs.vereinID &&
               lhs.funktionärID == rhs.funktionärID &&
               lhs.abteilung == rhs.abteilung &&
               lhs.gesuchtePositionen == rhs.gesuchtePositionen &&
               lhs.status == rhs.status &&
               lhs.datum == rhs.datum &&
               lhs.kontaktInitiator == rhs.kontaktInitiator
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(vereinID)
        hasher.combine(funktionärID)
        hasher.combine(abteilung)
        hasher.combine(gesuchtePositionen)
        hasher.combine(status)
        hasher.combine(datum)
        hasher.combine(kontaktInitiator)
    }
}

struct Reminder: Identifiable, Codable, Equatable, Hashable {
    var id: String = UUID().uuidString
    var datum: Date
    var beschreibung: String
    var kategorie: String? // z. B. "nachfrageErinnerung"

    static func == (lhs: Reminder, rhs: Reminder) -> Bool {
        return lhs.id == rhs.id &&
               lhs.datum == rhs.datum &&
               lhs.beschreibung == rhs.beschreibung &&
               lhs.kategorie == rhs.kategorie
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(datum)
        hasher.combine(beschreibung)
        hasher.combine(kategorie)
    }
}

struct Note: Identifiable, Codable, Equatable, Hashable {
    var id: String = UUID().uuidString
    var beschreibung: String
    var vereinsDokumente: [String]? // URLs zu Vereinsdokumenten

    static func == (lhs: Note, rhs: Note) -> Bool {
        return lhs.id == rhs.id &&
               lhs.beschreibung == rhs.beschreibung &&
               lhs.vereinsDokumente == rhs.vereinsDokumente
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(beschreibung)
        hasher.combine(vereinsDokumente)
    }
}

struct TransferDetails: Identifiable, Codable, Equatable, Hashable {
    var id: String? = UUID().uuidString
    var vonVereinID: String?
    var zuVereinID: String?
    var funktionärID: String?
    var datum: Date
    var ablösesumme: Double?
    var isAblösefrei: Bool
    var transferdetails: String?

    static func == (lhs: TransferDetails, rhs: TransferDetails) -> Bool {
        return lhs.id == rhs.id &&
               lhs.vonVereinID == rhs.vonVereinID &&
               lhs.zuVereinID == rhs.zuVereinID &&
               lhs.funktionärID == rhs.funktionärID &&
               lhs.datum == rhs.datum &&
               lhs.ablösesumme == rhs.ablösesumme &&
               lhs.isAblösefrei == rhs.isAblösefrei &&
               lhs.transferdetails == rhs.transferdetails
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(vonVereinID)
        hasher.combine(zuVereinID)
        hasher.combine(funktionärID)
        hasher.combine(datum)
        hasher.combine(ablösesumme)
        hasher.combine(isAblösefrei)
        hasher.combine(transferdetails)
    }
}

struct Club: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var name: String
    var mensDepartment: Department?
    var womensDepartment: Department?
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
        var clubDocumentURL: String?
    }

    struct FunktionärReference: Codable, Hashable {
        var id: String
        var name: String
        var vorname: String
        var positionImVerein: String?
    }

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

struct Chat: Codable, Identifiable {
    @DocumentID var id: String?
    var participantIDs: [String]
    var lastMessage: String?
    var lastMessageTimestamp: Date?
    var isArchived: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case participantIDs
        case lastMessage
        case lastMessageTimestamp
        case isArchived
    }
}

struct ChatMessage: Codable, Identifiable {
    var id: String?
    var senderID: String
    var senderEmail: String
    var content: String?
    var fileURL: String?
    var fileType: String?
    var timestamp: Date
    var readBy: [String]

    enum CodingKeys: String, CodingKey {
        case id
        case senderID
        case senderEmail
        case content
        case fileURL
        case fileType
        case timestamp
        case readBy
    }
}

struct PlayerData: Codable {
    var name: String?
    var position: String?
    var nationalitaet: [String]?
    var geburtsdatum: Date?
    var vereinID: String?
    var contractEnd: Date?
}

struct Matching: Identifiable, Codable {
    var id: String = UUID().uuidString
    var clientID: String
    var vereinID: String
    var matchScore: Double // Übereinstimmungsrate (0-100)
    var status: String // "pending", "accepted", "rejected"
    var createdAt: Date
}

struct MatchFeedback: Identifiable, Codable {
    var id: String = UUID().uuidString
    var matchID: String
    var userID: String // Mitarbeiter, der das Feedback gibt
    var status: String // "accepted" oder "rejected"
    var reason: String? // Grund für Ablehnung
    var timestamp: Date
}

struct User: Identifiable, Codable {
    @DocumentID var id: String?
    var email: String
    var rolle: String
    var points: Int? // Neue Eigenschaft
    var badges: [String]? // Neue Eigenschaft (z. B. ["first_email", "transfer_master"])
    var challenges: [Challenge]? // Neue Eigenschaft
}

struct Challenge: Identifiable, Codable {
    var id: String = UUID().uuidString
    var title: String // z. B. "Versende 3 E-Mails an Vereine"
    var description: String
    var points: Int // Belohnung
    var progress: Int // Fortschritt (z. B. 2/3 E-Mails versendet)
    var goal: Int // Ziel (z. B. 3 E-Mails)
    var type: String // z. B. "send_emails", "acquire_client"
    var completed: Bool
}

struct Notification: Identifiable, Codable {
    var id: String
    var userID: String
    var title: String
    var message: String
    var timestamp: Date
    var isRead: Bool
}
