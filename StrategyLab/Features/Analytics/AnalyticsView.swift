import SwiftUI
import Charts

struct AnalyticsView: View {
    @EnvironmentObject var store: DataStore
    @State private var metric: LeaderMetric = .rating

    private var ranked: [Player] { store.leaderboard(metric, limit: 10) }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    compareCTA
                    metricPicker
                    chartPanel
                    rankingPanel
                    insightPanel
                }
                .padding(16)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Analytics")
        }
    }

    private var compareCTA: some View {
        NavigationLink {
            ComparePlayersView()
        } label: {
            DataPanel {
                HStack(spacing: 14) {
                    Image(systemName: "rectangle.split.2x1.fill")
                        .font(.title2).foregroundStyle(Theme.blue)
                        .frame(width: 48, height: 48)
                        .background(Theme.blue.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Compare Players").font(.headline).foregroundStyle(Theme.textPrimary)
                        Text("Head-to-head radar & metric breakdown")
                            .font(.caption).foregroundStyle(Theme.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").font(.caption.weight(.bold))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
        }
        .buttonStyle(.plain)
        .appFont()
    }

    private var metricPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(LeaderMetric.allCases) { m in
                    Button {
                        Haptics.tap()
                        withAnimation(.easeOut(duration: 0.2)) { metric = m }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: m.icon)
                            Text(m.rawValue)
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(metric == m ? Color(hex: "#0A0D12") : Theme.textSecondary)
                        .padding(.horizontal, 14).padding(.vertical, 9)
                        .background(metric == m ? Theme.emerald : Theme.surface2)
                        .clipShape(Capsule())
                    }
                }
            }
        }
    }

    private var chartPanel: some View {
        DataPanel {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "\(metric.rawValue) Leaders", subtitle: "Top 10 · \(store.activeSeason)")
                if ranked.isEmpty {
                    EmptyHint(icon: "chart.bar", title: "No players", message: "Add players to rank them.")
                } else {
                    Chart(ranked) { p in
                        BarMark(
                            x: .value("Value", metric.value(p.current)),
                            y: .value("Player", p.name)
                        )
                        .foregroundStyle(barColor(for: p))
                        .cornerRadius(6)
                        .annotation(position: .trailing) {
                            Text(metric.display(p.current))
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }
                    .chartXAxis { AxisMarks { _ in
                        AxisGridLine().foregroundStyle(Theme.panelStroke)
                    } }
                    .chartYAxis { AxisMarks { value in
                        AxisValueLabel().foregroundStyle(Theme.textSecondary)
                    } }
                    .frame(height: CGFloat(ranked.count) * 34 + 20)
                }
            }
        }
    }

    private func barColor(for p: Player) -> Color {
        guard let top = ranked.first else { return Theme.emerald }
        return p.id == top.id ? Theme.gold : Theme.emerald
    }

    private var rankingPanel: some View {
        DataPanel {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "Ranking Table")
                ForEach(Array(ranked.enumerated()), id: \.element.id) { idx, p in
                    NavigationLink {
                        PlayerDetailView(player: p)
                    } label: {
                        HStack(spacing: 12) {
                            Text("\(idx + 1)")
                                .font(.subheadline.weight(.heavy))
                                .foregroundStyle(idx == 0 ? Theme.gold : Theme.textSecondary)
                                .frame(width: 22)
                            Avatar(name: p.name, photoData: p.photoData, size: 36, tint: p.position.color)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(p.name).font(.subheadline.weight(.semibold)).foregroundStyle(Theme.textPrimary)
                                Text(store.teamName(p.teamId)).font(.caption2).foregroundStyle(Theme.textSecondary)
                            }
                            Spacer()
                            Text(metric.display(p.current))
                                .font(.subheadline.weight(.heavy)).foregroundStyle(Theme.emerald)
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                    if idx < ranked.count - 1 { Divider().overlay(Theme.panelStroke) }
                }
            }
        }
        .appFont()
    }

    private var insightPanel: some View {
        DataPanel {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "Quick Insights")
                if let topScorer = store.leaderboard(.goals).first {
                    insightRow("soccerball", Theme.emerald,
                               "\(topScorer.name) leads scoring with \(topScorer.current.goals) goals.")
                }
                if let creator = store.leaderboard(.assists).first {
                    insightRow("arrow.up.forward", Theme.blue,
                               "\(creator.name) tops assists (\(creator.current.assists)).")
                }
                if let fastest = store.leaderboard(.topSpeed).first {
                    insightRow("speedometer", Theme.gold,
                               "Fastest sprint: \(fastest.name) at \(String(format: "%.1f", fastest.current.topSpeedKmh)) km/h.")
                }
            }
        }
        .appFont()
    }

    private func insightRow(_ icon: String, _ tint: Color, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon).foregroundStyle(tint).frame(width: 22)
            Text(text).font(.subheadline).foregroundStyle(Theme.textPrimary)
            Spacer()
        }
    }
}
