import SwiftUI

enum Position: String, Codable, CaseIterable, Identifiable {
    case goalkeeper = "GK"
    case defender   = "DF"
    case midfielder = "MF"
    case forward    = "FW"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .goalkeeper: return "Goalkeeper"
        case .defender:   return "Defender"
        case .midfielder: return "Midfielder"
        case .forward:    return "Forward"
        }
    }

    var color: Color {
        switch self {
        case .goalkeeper: return Theme.gold
        case .defender:   return Theme.blue
        case .midfielder: return Theme.emerald
        case .forward:    return Theme.danger
        }
    }
}

enum MatchResult {
    case win, draw, loss

    var short: String {
        switch self {
        case .win:  return "W"
        case .draw: return "D"
        case .loss: return "L"
        }
    }
    var color: Color {
        switch self {
        case .win:  return Theme.emerald
        case .draw: return Theme.textSecondary
        case .loss: return Theme.danger
        }
    }
}

struct Team: Codable, Identifiable, Hashable {
    var id = UUID()
    var name: String
    var shortName: String
    var city: String
    var founded: Int
    var colorHex: String
    var crest: String

    var color: Color { Color(hex: colorHex) }
}

struct PlayerSeasonStat: Codable, Identifiable, Hashable {
    var id = UUID()
    var season: String
    var appearances: Int
    var goals: Int
    var assists: Int
    var minutes: Int
    var shots: Int
    var tackles: Int
    var interceptions: Int
    var sprints: Int
    var yellowCards: Int
    var redCards: Int
    var passAccuracy: Double
    var distanceKm: Double
    var topSpeedKmh: Double
    var rating: Double

    var goalContributions: Int { goals + assists }
    var minutesPerGoal: Double { goals == 0 ? 0 : Double(minutes) / Double(goals) }
}

struct Player: Codable, Identifiable, Hashable {
    var id = UUID()
    var teamId: UUID
    var name: String
    var position: Position
    var number: Int
    var age: Int
    var heightCm: Int
    var weightKg: Int
    var nationality: String
    var photoData: Data?
    var seasons: [PlayerSeasonStat]

    var current: PlayerSeasonStat {
        seasons.last ?? PlayerSeasonStat(
            season: "—", appearances: 0, goals: 0, assists: 0, minutes: 0,
            shots: 0, tackles: 0, interceptions: 0, sprints: 0,
            yellowCards: 0, redCards: 0, passAccuracy: 0, distanceKm: 0,
            topSpeedKmh: 0, rating: 0)
    }
}

enum EventType: String, Codable, CaseIterable, Identifiable {
    case goal, assist, yellow, red, substitution, penalty, save

    var id: String { rawValue }

    var title: String {
        switch self {
        case .goal:         return "Goal"
        case .assist:       return "Assist"
        case .yellow:       return "Yellow Card"
        case .red:          return "Red Card"
        case .substitution: return "Substitution"
        case .penalty:      return "Penalty"
        case .save:         return "Key Save"
        }
    }

    var icon: String {
        switch self {
        case .goal:         return "soccerball"
        case .assist:       return "arrow.up.forward"
        case .yellow:       return "rectangle.fill"
        case .red:          return "rectangle.fill"
        case .substitution: return "arrow.left.arrow.right"
        case .penalty:      return "scope"
        case .save:         return "hand.raised.fill"
        }
    }

    var color: Color {
        switch self {
        case .goal:         return Theme.emerald
        case .assist:       return Theme.blue
        case .yellow:       return Theme.gold
        case .red:          return Theme.danger
        case .substitution: return Theme.textSecondary
        case .penalty:      return Theme.gold
        case .save:         return Theme.blue
        }
    }
}

struct MatchEvent: Codable, Identifiable, Hashable {
    var id = UUID()
    var minute: Int
    var type: EventType
    var teamId: UUID
    var playerName: String
    var detail: String = ""
}

struct Match: Codable, Identifiable, Hashable {
    var id = UUID()
    var homeTeamId: UUID
    var awayTeamId: UUID
    var date: Date
    var tournament: String
    var season: String
    var homeScore: Int
    var awayScore: Int
    var isFinished: Bool
    var events: [MatchEvent]
    var note: String = ""

    func result(for teamId: UUID) -> MatchResult? {
        guard isFinished else { return nil }
        let isHome = teamId == homeTeamId
        let own = isHome ? homeScore : awayScore
        let opp = isHome ? awayScore : homeScore
        if own > opp { return .win }
        if own < opp { return .loss }
        return .draw
    }

    func involves(_ teamId: UUID) -> Bool {
        homeTeamId == teamId || awayTeamId == teamId
    }
}

struct Tournament: Codable, Identifiable, Hashable {
    var id = UUID()
    var name: String
    var season: String
}

struct TeamRecord {
    var played = 0
    var wins = 0
    var draws = 0
    var losses = 0
    var goalsFor = 0
    var goalsAgainst = 0

    var points: Int { wins * 3 + draws }
    var goalDifference: Int { goalsFor - goalsAgainst }
    var winRate: Double { played == 0 ? 0 : Double(wins) / Double(played) }
}
