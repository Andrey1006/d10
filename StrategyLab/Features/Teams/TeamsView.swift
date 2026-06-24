import SwiftUI

struct TeamsView: View {
    @EnvironmentObject var store: DataStore
    @State private var search = ""
    @State private var showEditor = false

    private var filtered: [Team] {
        guard !search.isEmpty else { return store.teams }
        return store.teams.filter {
            $0.name.localizedCaseInsensitiveContains(search) ||
            $0.city.localizedCaseInsensitiveContains(search)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    summaryStrip
                    if filtered.isEmpty {
                        EmptyHint(icon: "shield.slash", title: "No teams",
                                  message: "Tap + to add your first team and start building the squad base.")
                    } else {
                        ForEach(filtered) { team in
                            NavigationLink {
                                TeamDetailView(team: team)
                            } label: {
                                teamPanel(team)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(16)
            }
            .background(Theme.background.ignoresSafeArea())
            .searchable(text: $search, prompt: "Search teams or cities")
            .navigationTitle("Teams")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { Haptics.tap(); showEditor = true } label: {
                        Image(systemName: "plus.circle.fill").foregroundStyle(Theme.emerald)
                    }
                }
            }
            .sheet(isPresented: $showEditor) {
                TeamEditorView()
            }
        }
    }

    private var summaryStrip: some View {
        HStack(spacing: 12) {
            StatPill(label: "Teams", value: "\(store.teams.count)", tint: Theme.emerald)
            StatPill(label: "Players", value: "\(store.players.count)", tint: Theme.blue)
            StatPill(label: "Goals", value: "\(store.totalGoals)", tint: Theme.gold)
        }
    }

    private func teamPanel(_ team: Team) -> some View {
        let rec = store.record(for: team.id)
        return DataPanel {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 14) {
                    Image(systemName: team.crest)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(team.color)
                        .frame(width: 54, height: 54)
                        .background(team.color.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    VStack(alignment: .leading, spacing: 3) {
                        Text(team.name)
                            .font(.headline)
                            .foregroundStyle(Theme.textPrimary)
                        Text("\(team.city) · est. \(String(team.founded))")
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Theme.textSecondary)
                }
                HStack(spacing: 10) {
                    miniStat("\(rec.points)", "PTS", Theme.emerald)
                    miniStat("\(rec.wins)-\(rec.draws)-\(rec.losses)", "W-D-L", Theme.textPrimary)
                    miniStat("\(store.players(of: team.id).count)", "SQUAD", Theme.blue)
                    Spacer()
                    FormStrip(results: store.form(for: team.id))
                }
            }
        }
        .appFont()
    }

    private func miniStat(_ value: String, _ label: String, _ tint: Color) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.subheadline.weight(.bold)).foregroundStyle(tint)
            Text(label).font(.caption2).foregroundStyle(Theme.textSecondary)
        }
    }
}
