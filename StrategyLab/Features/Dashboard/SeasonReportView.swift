import SwiftUI

struct SeasonReportView: View {
    @EnvironmentObject var store: DataStore

    private var rows: [(team: Team, record: TeamRecord)] {
        store.standings(season: store.activeSeason)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                headerRow
                ForEach(Array(rows.enumerated()), id: \.offset) { idx, row in
                    standingRow(rank: idx + 1, team: row.team, rec: row.record)
                }
                ShareLink(item: reportText) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Export Report").fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .foregroundStyle(Color(hex: "#0A0D12"))
                    .background(Theme.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .padding(.top, 8)
            }
            .padding(16)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Season Report")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .appFont()
    }

    private var headerRow: some View {
        HStack {
            Text("#").frame(width: 24, alignment: .leading)
            Text("Team")
            Spacer()
            Group {
                Text("P"); Text("W"); Text("D"); Text("L"); Text("GD"); Text("Pts")
            }
            .frame(width: 30)
        }
        .font(.caption.weight(.bold))
        .foregroundStyle(Theme.textSecondary)
        .padding(.horizontal, 8)
    }

    private func standingRow(rank: Int, team: Team, rec: TeamRecord) -> some View {
        DataPanel(padding: 12) {
            VStack(spacing: 10) {
                HStack {
                    Text("\(rank)")
                        .font(.subheadline.weight(.heavy))
                        .foregroundStyle(rank == 1 ? Theme.gold : Theme.textSecondary)
                        .frame(width: 24, alignment: .leading)
                    Image(systemName: team.crest).foregroundStyle(team.color)
                    Text(team.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    Group {
                        Text("\(rec.played)"); Text("\(rec.wins)"); Text("\(rec.draws)")
                        Text("\(rec.losses)")
                        Text(rec.goalDifference >= 0 ? "+\(rec.goalDifference)" : "\(rec.goalDifference)")
                            .foregroundStyle(rec.goalDifference >= 0 ? Theme.emerald : Theme.danger)
                        Text("\(rec.points)").foregroundStyle(Theme.emerald).fontWeight(.heavy)
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .frame(width: 30)
                }
                HStack {
                    Text("Win rate \(Int(rec.winRate * 100))%")
                    Spacer()
                    Text("GF \(rec.goalsFor) · GA \(rec.goalsAgainst)")
                }
                .font(.caption2)
                .foregroundStyle(Theme.textSecondary)
            }
        }
    }

    private var reportText: String {
        var lines = ["Novoline Strategy — \(store.activeSeason) Standings", ""]
        for (idx, row) in rows.enumerated() {
            lines.append("\(idx + 1). \(row.team.name) — \(row.record.points) pts " +
                         "(\(row.record.wins)W \(row.record.draws)D \(row.record.losses)L, GD \(row.record.goalDifference))")
        }
        return lines.joined(separator: "\n")
    }
}
