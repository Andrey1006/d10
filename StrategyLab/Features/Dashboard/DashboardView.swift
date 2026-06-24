import SwiftUI
import Charts

struct DashboardView: View {
    @EnvironmentObject var store: DataStore
    @State private var showSeasonPicker = false

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    seasonBar
                    kpiGrid
                    trendPanel
                    topPerformerPanel
                    standingsPanel
                    nextFixturePanel
                }
                .padding(16)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Command Center")
            .navigationBarTitleDisplayMode(.large)
            .confirmationDialog("Active Season", isPresented: $showSeasonPicker, titleVisibility: .visible) {
                ForEach(store.seasons, id: \.self) { s in
                    Button(s) { Haptics.tap(); store.activeSeason = s }
                }
            }
        }
    }

    private var seasonBar: some View {
        DataPanel {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("ACTIVE SEASON")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Theme.textSecondary)
                    Text(store.activeSeason)
                        .font(.title2.weight(.heavy))
                        .foregroundStyle(Theme.textPrimary)
                }
                Spacer()
                Button {
                    Haptics.tap(); showSeasonPicker = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                        Text("Switch")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.blue)
                    .padding(.horizontal, 14).padding(.vertical, 9)
                    .background(Theme.blue.opacity(0.15))
                    .clipShape(Capsule())
                }
            }
        }
        .appFont()
    }

    private var kpiGrid: some View {
        Grid(horizontalSpacing: 12, verticalSpacing: 12) {
            GridRow {
                KPITile(title: "Teams Tracked", value: "\(store.teams.count)",
                        icon: "shield.fill", tint: Theme.emerald)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                KPITile(title: "Players", value: "\(store.players.count)",
                        icon: "person.3.fill", tint: Theme.blue)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            GridRow {
                KPITile(title: "Matches Logged", value: "\(store.finishedMatches.count)",
                        icon: "sportscourt.fill", tint: Theme.gold,
                        delta: "+\(store.finishedMatches.count)", deltaPositive: true)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                KPITile(title: "Avg Rating", value: String(format: "%.2f", store.avgRating),
                        icon: "star.fill", tint: Theme.emerald,
                        delta: "▲ form", deltaPositive: true)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private var trendPanel: some View {
        DataPanel {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: "Goals per Matchday",
                              subtitle: "Total goals across logged fixtures")
                if store.goalsTrend.isEmpty {
                    EmptyHint(icon: "chart.xyaxis.line", title: "No data yet",
                              message: "Log finished matches to build the trend.")
                } else {
                    Chart(store.goalsTrend, id: \.index) { point in
                        AreaMark(x: .value("MD", point.index),
                                 y: .value("Goals", point.goals))
                            .foregroundStyle(Theme.areaBlueGradient)
                            .interpolationMethod(.catmullRom)
                        LineMark(x: .value("MD", point.index),
                                 y: .value("Goals", point.goals))
                            .foregroundStyle(Theme.blue)
                            .lineStyle(StrokeStyle(lineWidth: 3))
                            .interpolationMethod(.catmullRom)
                        PointMark(x: .value("MD", point.index),
                                  y: .value("Goals", point.goals))
                            .foregroundStyle(Theme.blue)
                    }
                    .chartYAxis { AxisMarks { _ in
                        AxisGridLine().foregroundStyle(Theme.panelStroke)
                        AxisValueLabel().foregroundStyle(Theme.textSecondary)
                    } }
                    .chartXAxis { AxisMarks { _ in
                        AxisValueLabel().foregroundStyle(Theme.textSecondary)
                    } }
                    .frame(height: 170)
                }
            }
        }
    }

    private var topPerformerPanel: some View {
        Group {
            if let p = store.topPerformer {
                NavigationLink {
                    PlayerDetailView(player: p)
                } label: {
                    DataPanel {
                        HStack(spacing: 14) {
                            Avatar(name: p.name, photoData: p.photoData, size: 60, tint: Theme.gold)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("TOP PERFORMER")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(Theme.gold)
                                Text(p.name)
                                    .font(.headline)
                                    .foregroundStyle(Theme.textPrimary)
                                Text("\(p.position.title) · \(store.teamName(p.teamId))")
                                    .font(.caption)
                                    .foregroundStyle(Theme.textSecondary)
                            }
                            Spacer()
                            VStack(spacing: 2) {
                                Text(String(format: "%.2f", p.current.rating))
                                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                                    .foregroundStyle(Theme.gold)
                                Text("rating")
                                    .font(.caption2)
                                    .foregroundStyle(Theme.textSecondary)
                            }
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .appFont()
    }

    private var standingsPanel: some View {
        DataPanel {
            VStack(alignment: .leading, spacing: 12) {
                NavigationLink {
                    SeasonReportView()
                } label: {
                    SectionHeader(title: "Standings", subtitle: store.activeSeason,
                                  actionTitle: "Full report")
                }
                .buttonStyle(.plain)

                ForEach(Array(store.standings(season: store.activeSeason).enumerated()), id: \.offset) { idx, row in
                    HStack(spacing: 12) {
                        Text("\(idx + 1)")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(idx == 0 ? Theme.gold : Theme.textSecondary)
                            .frame(width: 20)
                        Image(systemName: row.team.crest)
                            .foregroundStyle(row.team.color)
                            .frame(width: 22)
                        Text(row.team.name)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Theme.textPrimary)
                        Spacer()
                        FormStrip(results: store.form(for: row.team.id, limit: 4))
                        Text("\(row.record.points)")
                            .font(.subheadline.weight(.heavy))
                            .foregroundStyle(Theme.emerald)
                            .frame(width: 28, alignment: .trailing)
                    }
                    if idx < store.standings(season: store.activeSeason).count - 1 {
                        Divider().overlay(Theme.panelStroke)
                    }
                }
            }
        }
        .appFont()
    }

    private var nextFixturePanel: some View {
        Group {
            if let m = store.upcomingMatches.first {
                DataPanel {
                    VStack(alignment: .leading, spacing: 14) {
                        SectionHeader(title: "Next Fixture", subtitle: m.tournament)
                        HStack {
                            fixtureTeam(m.homeTeamId)
                            VStack(spacing: 2) {
                                Text("VS").font(.caption.weight(.bold)).foregroundStyle(Theme.textSecondary)
                                Text(m.date, format: .dateTime.day().month())
                                    .font(.caption2).foregroundStyle(Theme.textSecondary)
                            }
                            fixtureTeam(m.awayTeamId)
                        }
                    }
                }
            }
        }
        .appFont()
    }

    private func fixtureTeam(_ id: UUID) -> some View {
        VStack(spacing: 8) {
            Image(systemName: store.team(id)?.crest ?? "shield.fill")
                .font(.title)
                .foregroundStyle(store.team(id)?.color ?? Theme.textSecondary)
            Text(store.teamShort(id))
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Theme.textPrimary)
        }
        .frame(maxWidth: .infinity)
    }
}
