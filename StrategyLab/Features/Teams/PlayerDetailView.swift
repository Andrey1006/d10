import SwiftUI
import Charts

struct PlayerDetailView: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) private var dismiss
    let player: Player

    @State private var showEdit = false
    @State private var showDeleteAlert = false

    private var live: Player { store.players.first { $0.id == player.id } ?? player }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                header
                physicalPanel
                radarPanel
                seasonChartPanel
                statsGrid
            }
            .padding(16)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle(live.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showEdit = true } label: { Label("Edit", systemImage: "pencil") }
                    Button(role: .destructive) { showDeleteAlert = true } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: { Image(systemName: "ellipsis.circle").foregroundStyle(Theme.blue) }
            }
        }
        .sheet(isPresented: $showEdit) { PlayerEditorView(teamId: live.teamId, editing: live) }
        .alert("Delete \(live.name)?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                Haptics.warning(); store.deletePlayer(live); dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: { Text("This removes the player and their statistics.") }
        .appFont()
    }

    private var header: some View {
        DataPanel {
            HStack(spacing: 16) {
                Avatar(name: live.name, photoData: live.photoData, size: 76, tint: live.position.color)
                VStack(alignment: .leading, spacing: 5) {
                    Text(live.name).font(.title3.weight(.heavy)).foregroundStyle(Theme.textPrimary)
                    HStack(spacing: 6) {
                        tag("#\(live.number)", Theme.surface3)
                        tag(live.position.title, live.position.color.opacity(0.25))
                    }
                    Text("\(store.teamName(live.teamId)) · \(live.nationality)")
                        .font(.caption).foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                VStack(spacing: 2) {
                    Text(String(format: "%.2f", live.current.rating))
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                        .foregroundStyle(Theme.gold)
                    Text("rating").font(.caption2).foregroundStyle(Theme.textSecondary)
                }
            }
        }
    }

    private func tag(_ text: String, _ bg: Color) -> some View {
        Text(text)
            .font(.caption2.weight(.bold))
            .foregroundStyle(Theme.textPrimary)
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(bg).clipShape(Capsule())
    }

    private var physicalPanel: some View {
        DataPanel {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Physical")
                HStack(spacing: 10) {
                    StatPill(label: "Age", value: "\(live.age)")
                    StatPill(label: "Height", value: "\(live.heightCm)cm")
                    StatPill(label: "Weight", value: "\(live.weightKg)kg")
                    StatPill(label: "Top Speed", value: String(format: "%.1f", live.current.topSpeedKmh), tint: Theme.blue)
                }
            }
        }
    }

    private var radarPanel: some View {
        DataPanel {
            VStack(alignment: .leading, spacing: 8) {
                SectionHeader(title: "Attribute Profile", subtitle: "Normalized vs elite benchmark")
                RadarChart(axes: live.radarAxes(), primaryColor: live.position.color)
                    .frame(height: 240)
            }
        }
    }

    private var seasonChartPanel: some View {
        DataPanel {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Development", subtitle: "Goal contributions & rating by season")
                Chart {
                    ForEach(live.seasons) { s in
                        BarMark(x: .value("Season", s.season),
                                y: .value("G+A", s.goalContributions))
                            .foregroundStyle(Theme.emeraldGradient)
                            .cornerRadius(6)
                    }
                    ForEach(live.seasons) { s in
                        LineMark(x: .value("Season", s.season),
                                 y: .value("Rating", s.rating))
                            .foregroundStyle(Theme.gold)
                            .lineStyle(StrokeStyle(lineWidth: 3))
                        PointMark(x: .value("Season", s.season),
                                  y: .value("Rating", s.rating))
                            .foregroundStyle(Theme.gold)
                    }
                }
                .chartYAxis { AxisMarks { _ in
                    AxisGridLine().foregroundStyle(Theme.panelStroke)
                    AxisValueLabel().foregroundStyle(Theme.textSecondary)
                } }
                .chartXAxis { AxisMarks { _ in
                    AxisValueLabel().foregroundStyle(Theme.textSecondary)
                } }
                .frame(height: 180)
                HStack(spacing: 16) {
                    legendDot(Theme.emerald, "Goal contributions")
                    legendDot(Theme.gold, "Rating")
                }
            }
        }
    }

    private func legendDot(_ color: Color, _ text: String) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(text).font(.caption2).foregroundStyle(Theme.textSecondary)
        }
    }

    private var statsGrid: some View {
        let s = live.current
        return DataPanel {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Season Statistics", subtitle: s.season)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()),
                                    GridItem(.flexible())], spacing: 10) {
                    statCell("Apps", "\(s.appearances)", Theme.textPrimary)
                    statCell("Goals", "\(s.goals)", Theme.emerald)
                    statCell("Assists", "\(s.assists)", Theme.blue)
                    statCell("Minutes", "\(s.minutes)", Theme.textPrimary)
                    statCell("Shots", "\(s.shots)", Theme.textPrimary)
                    statCell("Pass %", String(format: "%.0f", s.passAccuracy), Theme.emerald)
                    statCell("Tackles", "\(s.tackles)", Theme.blue)
                    statCell("Intercept", "\(s.interceptions)", Theme.blue)
                    statCell("Sprints", "\(s.sprints)", Theme.textPrimary)
                    statCell("Distance", String(format: "%.0fkm", s.distanceKm), Theme.textPrimary)
                    statCell("Yellow", "\(s.yellowCards)", Theme.gold)
                    statCell("Red", "\(s.redCards)", Theme.danger)
                }
            }
        }
    }

    private func statCell(_ label: String, _ value: String, _ tint: Color) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.headline.weight(.bold)).foregroundStyle(tint)
            Text(label).font(.caption2).foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Theme.surface2)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
