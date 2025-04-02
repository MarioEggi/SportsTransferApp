//
//  SoccerdonnaService.swift

import Foundation
import SwiftSoup

class SoccerdonnaService {
    static let shared = SoccerdonnaService()

    private init() {}

    func fetchPlayerData(forPlayerID playerID: String) async throws -> PlayerData {
        let urlString = "https://www.soccerdonna.de/de/spieler-name/profil/spieler_\(playerID).html"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.114 Safari/537.36", forHTTPHeaderField: "User-Agent")
        request.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8", forHTTPHeaderField: "Accept")
        request.setValue("de-DE,de;q=0.9,en-US;q=0.8,en;q=0.7", forHTTPHeaderField: "Accept-Language")
        request.timeoutInterval = 10

        let (data, response) = try await URLSession.shared.data(for: request, delegate: nil)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let html = String(data: data, encoding: .utf8) ?? ""
        let doc: Document = try SwiftSoup.parse(html)

        var playerData = PlayerData()

        // Name
        if let nameElement = try doc.select("h1[itemprop=name]").first() {
            playerData.name = try nameElement.text()
        }

        // Position
        if let positionElement = try doc.select("td:contains(Spielposition) + td").first() {
            playerData.position = try positionElement.text()
        }

        // Nationalität
        if let nationalityElement = try doc.select("td:contains(Nationalität) + td").first() {
            playerData.nationalitaet = [try nationalityElement.text()]
        }

        // Geburtsdatum
        if let birthdateElement = try doc.select("td:contains(Geburtsdatum) + td").first() {
            let birthdateString = try birthdateElement.text()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd.MM.yyyy" // Format auf Soccerdonna
            if let birthdate = dateFormatter.date(from: birthdateString) {
                playerData.geburtsdatum = birthdate
            }
        }

        // Aktueller Verein
        if let clubElement = try doc.select("td:contains(Verein) + td a").first() {
            playerData.vereinID = try clubElement.text()
        }

        // Vertragsende (falls verfügbar)
        if let contractElement = try doc.select("td:contains(Vertrag bis) + td").first() {
            let contractEndString = try contractElement.text()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd.MM.yyyy"
            if let contractEnd = dateFormatter.date(from: contractEndString) {
                playerData.contractEnd = contractEnd
            }
        }

        return playerData
    }
}
