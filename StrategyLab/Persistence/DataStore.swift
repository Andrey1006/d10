import SwiftUI
import Combine

enum LeaderMetric: String, CaseIterable, Identifiable {
    case rating = "Rating"
    case goals = "Goals"
    case assists = "Assists"
    case contributions = "G+A"
    case passAccuracy = "Pass %"
    case tackles = "Tackles"
    case distance = "Distance"
    case topSpeed = "Top Speed"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .rating:        return "star.fill"
        case .goals:         return "soccerball"
        case .assists:       return "arrow.up.forward"
        case .contributions: return "plus.forwardslash.minus"
        case .passAccuracy:  return "scope"
        case .tackles:       return "shield.lefthalf.filled"
        case .distance:      return "figure.run"
        case .topSpeed:      return "speedometer"
        }
    }

    func value(_ s: PlayerSeasonStat) -> Double {
        switch self {
        case .rating:        return s.rating
        case .goals:         return Double(s.goals)
        case .assists:       return Double(s.assists)
        case .contributions: return Double(s.goalContributions)
        case .passAccuracy:  return s.passAccuracy
        case .tackles:       return Double(s.tackles)
        case .distance:      return s.distanceKm
        case .topSpeed:      return s.topSpeedKmh
        }
    }

    func display(_ s: PlayerSeasonStat) -> String {
        switch self {
        case .rating:        return String(format: "%.2f", s.rating)
        case .passAccuracy:  return String(format: "%.0f%%", s.passAccuracy)
        case .distance:      return String(format: "%.0f km", s.distanceKm)
        case .topSpeed:      return String(format: "%.1f km/h", s.topSpeedKmh)
        default:             return String(format: "%.0f", value(s))
        }
    }
}

final class DataStore: ObservableObject {
    @Published var teams: [Team] = []
    @Published var players: [Player] = []
    @Published var matches: [Match] = []
    @Published var tournaments: [Tournament] = []
    @Published var activeSeason: String = "2025/26"

    private let key = "strategylab.state.v1"
    private var cancellable: AnyCancellable?

    struct Snapshot: Codable {
        var teams: [Team]
        var players: [Player]
        var matches: [Match]
        var tournaments: [Tournament]
        var activeSeason: String
    }

    init() {
        if !load() {
            SeedData.populate(self)
            save()
        }
        cancellable = objectWillChange
            .debounce(for: .seconds(0.4), scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.save() }
    }

    @discardableResult
    func load() -> Bool {
        guard let data = UserDefaults.standard.data(forKey: key),
              let snap = try? JSONDecoder().decode(Snapshot.self, from: data)
        else { return false }
        teams = snap.teams
        players = snap.players
        matches = snap.matches
        tournaments = snap.tournaments
        activeSeason = snap.activeSeason
        return true
    }

    func save() {
        let snap = Snapshot(teams: teams, players: players, matches: matches,
                            tournaments: tournaments, activeSeason: activeSeason)
        if let data = try? JSONEncoder().encode(snap) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func resetToSampleData() {
        teams = []; players = []; matches = []; tournaments = []
        SeedData.populate(self)
        save()
        objectWillChange.send()
    }

    func wipeAll() {
        teams = []; players = []; matches = []; tournaments = []
        save(); objectWillChange.send()
    }

    func addTeam(_ team: Team) { teams.append(team); objectWillChange.send() }
    func updateTeam(_ team: Team) {
        if let i = teams.firstIndex(where: { $0.id == team.id }) { teams[i] = team }
        objectWillChange.send()
    }
    func deleteTeam(_ team: Team) {
        teams.removeAll { $0.id == team.id }
        players.removeAll { $0.teamId == team.id }
        matches.removeAll { $0.involves(team.id) }
        objectWillChange.send()
    }

    func addPlayer(_ p: Player) { players.append(p); objectWillChange.send() }
    func updatePlayer(_ p: Player) {
        if let i = players.firstIndex(where: { $0.id == p.id }) { players[i] = p }
        objectWillChange.send()
    }
    func deletePlayer(_ p: Player) {
        players.removeAll { $0.id == p.id }; objectWillChange.send()
    }
    func players(of teamId: UUID) -> [Player] {
        players.filter { $0.teamId == teamId }.sorted { $0.number < $1.number }
    }

    func addMatch(_ m: Match) { matches.append(m); objectWillChange.send() }
    func updateMatch(_ m: Match) {
        if let i = matches.firstIndex(where: { $0.id == m.id }) { matches[i] = m }
        objectWillChange.send()
    }
    func deleteMatch(_ m: Match) {
        matches.removeAll { $0.id == m.id }; objectWillChange.send()
    }

    func addTournament(_ t: Tournament) { tournaments.append(t); objectWillChange.send() }
    func deleteTournament(_ t: Tournament) {
        tournaments.removeAll { $0.id == t.id }; objectWillChange.send()
    }

    func team(_ id: UUID) -> Team? { teams.first { $0.id == id } }
    func teamName(_ id: UUID) -> String { team(id)?.name ?? "Unknown" }
    func teamShort(_ id: UUID) -> String { team(id)?.shortName ?? "—" }

    var finishedMatches: [Match] { matches.filter { $0.isFinished } }
    var upcomingMatches: [Match] {
        matches.filter { !$0.isFinished }.sorted { $0.date < $1.date }
    }

    func record(for teamId: UUID, season: String? = nil) -> TeamRecord {
        var r = TeamRecord()
        for m in finishedMatches where m.involves(teamId) {
            if let season, m.season != season { continue }
            r.played += 1
            let isHome = m.homeTeamId == teamId
            let gf = isHome ? m.homeScore : m.awayScore
            let ga = isHome ? m.awayScore : m.homeScore
            r.goalsFor += gf; r.goalsAgainst += ga
            switch m.result(for: teamId) {
            case .win:  r.wins += 1
            case .draw: r.draws += 1
            case .loss: r.losses += 1
            case .none: break
            }
        }
        return r
    }

    func form(for teamId: UUID, limit: Int = 5) -> [MatchResult] {
        finishedMatches
            .filter { $0.involves(teamId) }
            .sorted { $0.date > $1.date }
            .prefix(limit)
            .compactMap { $0.result(for: teamId) }
    }

    func standings(season: String? = nil) -> [(team: Team, record: TeamRecord)] {
        teams.map { ($0, record(for: $0.id, season: season)) }
            .sorted {
                if $0.1.points != $1.1.points { return $0.1.points > $1.1.points }
                return $0.1.goalDifference > $1.1.goalDifference
            }
    }

    func leaderboard(_ metric: LeaderMetric, limit: Int = 50) -> [Player] {
        players
            .sorted { metric.value($0.current) > metric.value($1.current) }
            .prefix(limit)
            .map { $0 }
    }

    var goalsTrend: [(index: Int, goals: Int)] {
        let sorted = finishedMatches
            .filter { $0.season == activeSeason }
            .sorted { $0.date < $1.date }
        return sorted.enumerated().map { (idx, m) in (idx + 1, m.homeScore + m.awayScore) }
    }

    var totalGoals: Int { players.reduce(0) { $0 + $1.current.goals } }
    var avgRating: Double {
        let rated = players.filter { $0.current.appearances > 0 }
        guard !rated.isEmpty else { return 0 }
        return rated.reduce(0.0) { $0 + $1.current.rating } / Double(rated.count)
    }

    var topPerformer: Player? {
        players.max { $0.current.rating < $1.current.rating }
    }

    var seasons: [String] {
        let set = Set(tournaments.map { $0.season } + matches.map { $0.season } + [activeSeason])
        return set.sorted(by: >)
    }
}
