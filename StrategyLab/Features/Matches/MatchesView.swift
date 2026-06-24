import SwiftUI

struct MatchesView: View {
    @EnvironmentObject var store: DataStore
    @State private var segment = 0
    @State private var showEditor = false
    @State private var tournamentFilter = "All"

    private var tournamentNames: [String] {
        ["All"] + Array(Set(store.matches.map { $0.tournament })).sorted()
    }

    private var list: [Match] {
        let base = segment == 0
            ? store.finishedMatches.sorted { $0.date > $1.date }
            : store.upcomingMatches
        guard tournamentFilter != "All" else { return base }
        return base.filter { $0.tournament == tournamentFilter }
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    PillSegment(options: ["Results", "Upcoming"], selection: $segment)
                    tournamentChips
                    if list.isEmpty {
                        EmptyHint(icon: "sportscourt", title: "No matches",
                                  message: segment == 0 ? "Logged results will appear here." : "Schedule a fixture with +.")
                    } else {
                        ForEach(list) { match in
                            NavigationLink {
                                MatchDetailView(match: match)
                            } label: {
                                matchPanel(match)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(16)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Matches")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { Haptics.tap(); showEditor = true } label: {
                        Image(systemName: "plus.circle.fill").foregroundStyle(Theme.emerald)
                    }
                }
            }
            .sheet(isPresented: $showEditor) { MatchEditorView() }
        }
    }

    private var tournamentChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(tournamentNames, id: \.self) { name in
                    Button {
                        Haptics.tap(); tournamentFilter = name
                    } label: {
                        Text(name)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(tournamentFilter == name ? Color(hex: "#0A0D12") : Theme.textSecondary)
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .background(tournamentFilter == name ? Theme.emerald : Theme.surface2)
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }

    private func matchPanel(_ m: Match) -> some View {
        DataPanel {
            VStack(spacing: 12) {
                HStack {
                    Text(m.tournament)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Theme.blue)
                    Spacer()
                    Text(m.date, format: .dateTime.day().month().hour().minute())
                        .font(.caption2).foregroundStyle(Theme.textSecondary)
                }
                HStack {
                    teamSide(m.homeTeamId, alignment: .leading)
                    scoreBlock(m)
                    teamSide(m.awayTeamId, alignment: .trailing)
                }
            }
        }
        .appFont()
    }

    private func teamSide(_ id: UUID, alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 6) {
            Image(systemName: store.team(id)?.crest ?? "shield.fill")
                .font(.title2)
                .foregroundStyle(store.team(id)?.color ?? Theme.textSecondary)
            Text(store.teamShort(id))
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Theme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: alignment == .leading ? .leading : .trailing)
    }

    private func scoreBlock(_ m: Match) -> some View {
        VStack(spacing: 4) {
            if m.isFinished {
                Text("\(m.homeScore) – \(m.awayScore)")
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                Text("FT").font(.caption2.weight(.bold)).foregroundStyle(Theme.emerald)
            } else {
                Text("VS")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
                Text("SCHEDULED").font(.caption2.weight(.bold)).foregroundStyle(Theme.gold)
            }
        }
        .frame(width: 90)
    }
}
