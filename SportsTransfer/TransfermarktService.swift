import Foundation
import SwiftSoup

class TransfermarktService {
    static let shared = TransfermarktService()

    private init() {}

    func fetchTransfermarktData(forPlayerID playerID: String) async throws -> [String: String] {
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

        var stats: [String: String] = [:]

        if let performanceTable = try doc.select("#player-performance-table .grid-table").first() {
            let rows = try performanceTable.select(".grid-row")
            for row in rows {
                let columns = try row.select(".grid__cell")
                if columns.count >= 6 {
                    let competition = try columns[0].text().trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                    if competition.contains("insgesamt") || competition.contains("total") {
                        let games = try columns[1].text().trimmingCharacters(in: .whitespacesAndNewlines)
                        let goals = try columns[2].text().trimmingCharacters(in: .whitespacesAndNewlines)
                        let assists = try columns[3].text().trimmingCharacters(in: .whitespacesAndNewlines)
                        let minutesPlayed = try columns[5].text().trimmingCharacters(in: .whitespacesAndNewlines)

                        stats["Wettbewerb"] = "Insgesamt"
                        stats["Spiele"] = games.isEmpty ? "0" : games
                        stats["Tore"] = goals.isEmpty ? "0" : goals
                        stats["Vorlagen"] = assists.isEmpty ? "0" : assists
                        stats["Spielminuten"] = minutesPlayed.isEmpty ? "0'" : minutesPlayed
                        break
                    }
                }
            }
        } else {
            print("Leistungsübersicht nicht gefunden. HTML-Beispiel: \(String(html.prefix(500)))")
        }

        if stats.isEmpty {
            stats["Status"] = "Keine Daten gefunden. Überprüfe die transfermarktID oder die HTML-Struktur."
        }

        return stats
    }
}
