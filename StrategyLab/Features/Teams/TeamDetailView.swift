import SwiftUI

struct TeamDetailView: View {
    @EnvironmentObject var store: DataStore
    let team: Team

    @State private var showAddPlayer = false
    @State private var showEditTeam = false
    @State private var positionFilter: Int = 0

    private let positions: [Position?] = [nil, .goalkeeper, .defender, .midfielder, .forward]

    private var roster: [Player] {
        let all = store.players(of: team.id)
        guard let pos = positions[positionFilter] else { return all }
        return all.filter { $0.position == pos }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                header
                recordPanel
                recentResults
                rosterSection
            }
            .padding(16)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle(team.shortName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showAddPlayer = true } label: { Label("Add Player", systemImage: "person.badge.plus") }
                    Button { showEditTeam = true } label: { Label("Edit Team", systemImage: "pencil") }
                } label: {
                    Image(systemName: "ellipsis.circle").foregroundStyle(Theme.blue)
                }
            }
        }
        .sheet(isPresented: $showAddPlayer) { PlayerEditorView(teamId: team.id) }
        .sheet(isPresented: $showEditTeam) { TeamEditorView(editing: team) }
        .appFont()
    }

    private var header: some View {
        DataPanel {
            HStack(spacing: 16) {
                Image(systemName: team.crest)
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(team.color)
                    .frame(width: 70, height: 70)
                    .background(team.color.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                VStack(alignment: .leading, spacing: 4) {
                    Text(team.name).font(.title3.weight(.heavy)).foregroundStyle(Theme.textPrimary)
                    Text("\(team.city) · Founded \(String(team.founded))")
                        .font(.caption).foregroundStyle(Theme.textSecondary)
                    FormStrip(results: store.form(for: team.id))
                        .padding(.top, 4)
                }
                Spacer()
            }
        }
    }

    private var recordPanel: some View {
        let rec = store.record(for: team.id)
        return DataPanel {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Season Record", subtitle: store.activeSeason)
                HStack(spacing: 10) {
                    StatPill(label: "Played", value: "\(rec.played)")
                    StatPill(label: "Points", value: "\(rec.points)", tint: Theme.emerald)
                    StatPill(label: "Win %", value: "\(Int(rec.winRate * 100))", tint: Theme.blue)
                }
                HStack(spacing: 10) {
                    StatPill(label: "Wins", value: "\(rec.wins)", tint: Theme.emerald)
                    StatPill(label: "Draws", value: "\(rec.draws)")
                    StatPill(label: "Losses", value: "\(rec.losses)", tint: Theme.danger)
                }
                HStack(spacing: 10) {
                    StatPill(label: "Goals For", value: "\(rec.goalsFor)", tint: Theme.emerald)
                    StatPill(label: "Goals Against", value: "\(rec.goalsAgainst)", tint: Theme.danger)
                    StatPill(label: "Diff", value: rec.goalDifference >= 0 ? "+\(rec.goalDifference)" : "\(rec.goalDifference)",
                             tint: rec.goalDifference >= 0 ? Theme.emerald : Theme.danger)
                }
            }
        }
    }

    private var recentResults: some View {
        let games = store.finishedMatches
            .filter { $0.involves(team.id) }
            .sorted { $0.date > $1.date }
            .prefix(4)
        return Group {
            if !games.isEmpty {
                DataPanel {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "Recent Results")
                        ForEach(Array(games), id: \.id) { m in
                            HStack {
                                if let r = m.result(for: team.id) { ResultBadge(result: r) }
                                Text("\(store.teamShort(m.homeTeamId))  \(m.homeScore) – \(m.awayScore)  \(store.teamShort(m.awayTeamId))")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(Theme.textPrimary)
                                Spacer()
                                Text(m.date, format: .dateTime.day().month())
                                    .font(.caption).foregroundStyle(Theme.textSecondary)
                            }
                        }
                    }
                }
            }
        }
    }

    private var rosterSection: some View {
        VStack(spacing: 12) {
            SectionHeader(title: "Squad", subtitle: "\(store.players(of: team.id).count) players",
                          actionTitle: "Add") { showAddPlayer = true }
            PillSegment(options: ["All", "GK", "DF", "MF", "FW"], selection: $positionFilter)
            if roster.isEmpty {
                EmptyHint(icon: "person.fill.questionmark", title: "No players",
                          message: "Add players to this position group.")
            } else {
                ForEach(roster) { player in
                    NavigationLink {
                        PlayerDetailView(player: player)
                    } label: {
                        playerRow(player)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func playerRow(_ p: Player) -> some View {
        DataPanel(padding: 12) {
            HStack(spacing: 12) {
                Avatar(name: p.name, photoData: p.photoData, size: 44, tint: p.position.color)
                VStack(alignment: .leading, spacing: 2) {
                    Text(p.name).font(.subheadline.weight(.semibold)).foregroundStyle(Theme.textPrimary)
                    Text("#\(p.number) · \(p.position.rawValue) · \(p.nationality)")
                        .font(.caption).foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "%.2f", p.current.rating))
                        .font(.subheadline.weight(.heavy)).foregroundStyle(ratingColor(p.current.rating))
                    Text("\(p.current.goals)G \(p.current.assists)A")
                        .font(.caption2).foregroundStyle(Theme.textSecondary)
                }
            }
        }
    }

    private func ratingColor(_ r: Double) -> Color {
        r >= 8.5 ? Theme.gold : (r >= 7.5 ? Theme.emerald : Theme.textPrimary)
    }
}
