import SwiftUI

struct ComparePlayersView: View {
    @EnvironmentObject var store: DataStore
    @State private var leftId: UUID?
    @State private var rightId: UUID?
    @State private var picking: Side?

    enum Side { case left, right }

    private var left: Player? { store.players.first { $0.id == leftId } }
    private var right: Player? { store.players.first { $0.id == rightId } }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                pickerRow
                if let l = left, let r = right {
                    radarPanel(l, r)
                    metricsPanel(l, r)
                    verdictPanel(l, r)
                } else {
                    EmptyHint(icon: "rectangle.split.2x1", title: "Pick two players",
                              message: "Select a player on each side to compare profiles and metrics.")
                }
            }
            .padding(16)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Compare")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .onAppear(perform: preselect)
        .sheet(item: $picking) { side in
            PlayerPickerSheet { player in
                if side == .left { leftId = player.id } else { rightId = player.id }
                picking = nil
            }
        }
        .appFont()
    }

    private func preselect() {
        let top = store.leaderboard(.rating, limit: 2)
        if leftId == nil { leftId = top.first?.id }
        if rightId == nil { rightId = top.dropFirst().first?.id }
    }

    private var pickerRow: some View {
        HStack(spacing: 12) {
            pickerCard(left, side: .left, tint: Theme.emerald)
            Text("VS").font(.caption.weight(.heavy)).foregroundStyle(Theme.textSecondary)
            pickerCard(right, side: .right, tint: Theme.blue)
        }
    }

    private func pickerCard(_ p: Player?, side: Side, tint: Color) -> some View {
        Button {
            Haptics.tap(); picking = side
        } label: {
            DataPanel(padding: 12) {
                VStack(spacing: 8) {
                    Avatar(name: p?.name ?? "Select", photoData: p?.photoData, size: 54, tint: tint)
                    Text(p?.name ?? "Select player")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(p == nil ? Theme.textSecondary : Theme.textPrimary)
                        .lineLimit(1).minimumScaleFactor(0.7)
                    if let p {
                        Text(store.teamShort(p.teamId))
                            .font(.caption2).foregroundStyle(Theme.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(.plain)
    }

    private func radarPanel(_ l: Player, _ r: Player) -> some View {
        DataPanel {
            VStack(spacing: 12) {
                SectionHeader(title: "Profile Overlay")
                RadarChart(axes: l.radarAxes(), compareAxes: r.radarAxes(),
                           primaryColor: Theme.emerald, compareColor: Theme.blue)
                    .frame(height: 250)
                HStack(spacing: 20) {
                    legend(Theme.emerald, l.name)
                    legend(Theme.blue, r.name)
                }
            }
        }
    }

    private func legend(_ color: Color, _ name: String) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 9, height: 9)
            Text(name).font(.caption.weight(.medium)).foregroundStyle(Theme.textSecondary)
                .lineLimit(1)
        }
    }

    private func metricsPanel(_ l: Player, _ r: Player) -> some View {
        DataPanel {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: "Metric Breakdown")
                ForEach(LeaderMetric.allCases) { m in
                    comparisonBar(m, l, r)
                }
            }
        }
    }

    private func comparisonBar(_ m: LeaderMetric, _ l: Player, _ r: Player) -> some View {
        let lv = m.value(l.current)
        let rv = m.value(r.current)
        let maxV = max(lv, rv, 0.0001)
        return VStack(spacing: 6) {
            HStack {
                Text(m.display(l.current))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(lv >= rv ? Theme.emerald : Theme.textSecondary)
                Spacer()
                Text(m.rawValue).font(.caption2).foregroundStyle(Theme.textSecondary)
                Spacer()
                Text(m.display(r.current))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(rv >= lv ? Theme.blue : Theme.textSecondary)
            }
            GeometryReader { geo in
                let half = (geo.size.width - 6) / 2
                HStack(spacing: 6) {
                    HStack { Spacer(minLength: 0)
                        Capsule().fill(Theme.emerald)
                            .frame(width: max(4, half * CGFloat(lv / maxV)))
                    }
                    .frame(width: half)
                    HStack {
                        Capsule().fill(Theme.blue)
                            .frame(width: max(4, half * CGFloat(rv / maxV)))
                        Spacer(minLength: 0)
                    }
                    .frame(width: half)
                }
            }
            .frame(height: 8)
        }
    }

    private func verdictPanel(_ l: Player, _ r: Player) -> some View {
        var lWins = 0, rWins = 0
        for m in LeaderMetric.allCases {
            let lv = m.value(l.current), rv = m.value(r.current)
            if lv > rv { lWins += 1 } else if rv > lv { rWins += 1 }
        }
        let leader = lWins >= rWins ? l : r
        let tint = lWins >= rWins ? Theme.emerald : Theme.blue
        return DataPanel {
            HStack(spacing: 14) {
                Image(systemName: "checkmark.seal.fill").font(.title).foregroundStyle(tint)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Edge: \(leader.name)").font(.headline).foregroundStyle(Theme.textPrimary)
                    Text("Leads \(max(lWins, rWins)) of \(LeaderMetric.allCases.count) metrics")
                        .font(.caption).foregroundStyle(Theme.textSecondary)
                }
                Spacer()
            }
        }
    }
}

extension ComparePlayersView.Side: Identifiable {
    var id: Int { self == .left ? 0 : 1 }
}

struct PlayerPickerSheet: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) private var dismiss
    @State private var search = ""
    let onSelect: (Player) -> Void

    private var filtered: [Player] {
        let all = store.players.sorted { $0.current.rating > $1.current.rating }
        guard !search.isEmpty else { return all }
        return all.filter { $0.name.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 8) {
                    ForEach(filtered) { p in
                        Button {
                            Haptics.tap(); onSelect(p); dismiss()
                        } label: {
                            DataPanel(padding: 10) {
                                HStack(spacing: 12) {
                                    Avatar(name: p.name, photoData: p.photoData, size: 38, tint: p.position.color)
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(p.name).font(.subheadline.weight(.semibold)).foregroundStyle(Theme.textPrimary)
                                        Text("\(p.position.rawValue) · \(store.teamShort(p.teamId))")
                                            .font(.caption2).foregroundStyle(Theme.textSecondary)
                                    }
                                    Spacer()
                                    Text(String(format: "%.2f", p.current.rating))
                                        .font(.subheadline.weight(.bold)).foregroundStyle(Theme.gold)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
            }
            .background(Theme.background.ignoresSafeArea())
            .searchable(text: $search, prompt: "Search players")
            .navigationTitle("Select Player")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
            .appFont()
        }
    }
}
