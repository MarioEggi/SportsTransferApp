import Foundation
import SwiftSoup

class TransfermarktService {
    static let shared = TransfermarktService()

    private init() {}

    func fetchPlayerData(forPlayerID playerID: String) async throws -> PlayerData {
        let urlString = "https://www.transfermarkt.de/spieler-name/profil/spieler/\(playerID)"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.114 Safari/537.36", forHTTPHeaderField: "User-Agent")
        request.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8", forHTTPHeaderField: "Accept")
        request.setValue("en-US,en;q=0.5", forHTTPHeaderField: "Accept-Language")
        request.timeoutInterval = 10

        let (data, response) = try await URLSession.shared.data(for: request, delegate: nil)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let html = String(data: data, encoding: .utf8) ?? ""
        let doc: Document = try SwiftSoup.parse(html)

        var playerData = PlayerData()

        // Extract name
        if let nameElement = try doc.select(".data-header__name").first() {
            playerData.name = try nameElement.text()
        }

        // Extract position
        if let positionElement = try doc.select(".data-header__position").first() {
            playerData.position = try positionElement.text()
        }

        // Extract nationality
        if let nationalityElement = try doc.select(".data-header__nationality").first() {
            playerData.nationalitaet = [try nationalityElement.text()]
        }

        // Extract date of birth
        if let birthdateElement = try doc.select(".data-header__birthdate").first() {
            let birthdateString = try birthdateElement.text()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd.MM.yyyy"
            if let birthdate = dateFormatter.date(from: birthdateString) {
                playerData.geburtsdatum = birthdate
            }
        }

        // Extract current club
        if let clubElement = try doc.select(".data-header__club").first() {
            playerData.vereinID = try clubElement.text()
        }

        // Extract contract end date
        if let contractElement = try doc.select(".data-contract__end").first() {
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
