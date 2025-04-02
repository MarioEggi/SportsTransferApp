// AnyProcess.swift
import SwiftUI

struct AnyProcess: Identifiable, Equatable {
    let id: String
    let title: String
    let displayTitle: String
    let status: String
    let priority: Int?
    let type: ProcessType
    let color: Color
    let icon: String
    let note: String?
    
    enum ProcessType {
        case transfer, sponsoring, profile
    }
    
    init(transfer: TransferProcess, clients: [Client], clubs: [Club]) {
        self.id = transfer.id ?? UUID().uuidString
        let clientName = clients.first(where: { $0.id == transfer.clientID })?.vorname ?? transfer.clientID
        let clubName = clubs.first(where: { $0.id == transfer.vereinID })?.name ?? transfer.vereinID
        self.title = transfer.title ?? "Unbekannt"
        self.displayTitle = "\(clientName) -> \(clubName)"
        self.status = transfer.status
        self.priority = transfer.priority
        self.type = .transfer
        self.color = .blue
        self.icon = "person.3.fill"
        self.note = transfer.hinweise?.first?.beschreibung
    }
    
    init(sponsoring: SponsoringProcess, clients: [Client], sponsors: [Sponsor]) {
        self.id = sponsoring.id ?? UUID().uuidString
        let clientName = clients.first(where: { $0.id == sponsoring.clientID })?.vorname ?? sponsoring.clientID
        let sponsorName = sponsors.first(where: { $0.id == sponsoring.sponsorID })?.name ?? sponsoring.sponsorID
        self.title = sponsoring.title ?? "Unbekannt"
        self.displayTitle = "\(clientName) -> \(sponsorName)"
        self.status = sponsoring.status
        self.priority = sponsoring.priority
        self.type = .sponsoring
        self.color = .green
        self.icon = "dollarsign.circle.fill"
        self.note = sponsoring.hinweise?.first?.beschreibung
    }
    
    init(profile: ProfileRequest, clubs: [Club]) {
        self.id = profile.id ?? UUID().uuidString
        let clubName = clubs.first(where: { $0.id == profile.vereinID })?.name ?? profile.vereinID
        self.title = "Profil-Anfrage für \(profile.vereinID)"
        self.displayTitle = "Profil-Anfrage \(clubName)"
        self.status = profile.status
        self.priority = nil
        self.type = .profile
        self.color = .orange
        self.icon = "magnifyingglass"
        self.note = nil
    }
    
    static func == (lhs: AnyProcess, rhs: AnyProcess) -> Bool {
        return lhs.id == rhs.id
    }
}
