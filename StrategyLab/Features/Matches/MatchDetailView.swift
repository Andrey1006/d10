import SwiftUI

struct MatchDetailView: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) private var dismiss
    let match: Match

    @State private var showEventSheet = false
    @State private var showScoreSheet = false
    @State private var noteDraft = ""
    @State private var editingNote = false

    private var live: Match { store.matches.first { $0.id == match.id } ?? match }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                scoreboard
                actionRow
                if live.isFinished { breakdownPanel }
                timelinePanel
                notePanel
            }
            .padding(16)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Match Center")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showScoreSheet = true } label: { Label("Edit Score / Status", systemImage: "pencil") }
                    Button(role: .destructive) { store.deleteMatch(live); dismiss() } label: {
                        Label("Delete Match", systemImage: "trash")
                    }
                } label: { Image(systemName: "ellipsis.circle").foregroundStyle(Theme.blue) }
            }
        }
        .sheet(isPresented: $showEventSheet) { EventEntryView(match: live) }
        .sheet(isPresented: $showScoreSheet) { ScoreEditorView(match: live) }
        .appFont()
    }

    private var scoreboard: some View {
        DataPanel {
            VStack(spacing: 16) {
                Text(live.tournament)
                    .font(.caption.weight(.bold)).foregroundStyle(Theme.blue)
                HStack {
                    teamColumn(live.homeTeamId)
                    VStack(spacing: 4) {
                        if live.isFinished {
                            Text("\(live.homeScore) – \(live.awayScore)")
                                .font(.system(size: 38, weight: .heavy, design: .rounded))
                                .foregroundStyle(Theme.textPrimary)
                            Text("FULL TIME").font(.caption2.weight(.bold)).foregroundStyle(Theme.emerald)
                        } else {
                            Text("VS").font(.system(size: 30, weight: .heavy, design: .rounded))
                                .foregroundStyle(Theme.textSecondary)
                            Text(live.date, format: .dateTime.day().month().hour().minute())
                                .font(.caption2).foregroundStyle(Theme.gold)
                        }
                    }
                    .frame(width: 120)
                    teamColumn(live.awayTeamId)
                }
            }
        }
    }

    private func teamColumn(_ id: UUID) -> some View {
        VStack(spacing: 8) {
            Image(systemName: store.team(id)?.crest ?? "shield.fill")
                .font(.system(size: 32))
                .foregroundStyle(store.team(id)?.color ?? Theme.textSecondary)
            Text(store.teamName(id))
                .font(.caption.weight(.bold))
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.textPrimary)
        }
        .frame(maxWidth: .infinity)
    }

    private var actionRow: some View {
        HStack(spacing: 12) {
            PrimaryButton(title: "Add Event", icon: "plus", tint: Theme.emerald) {
                showEventSheet = true
            }
            PrimaryButton(title: live.isFinished ? "Edit Score" : "Set Result",
                          icon: "flag.checkered", tint: Theme.blue) {
                showScoreSheet = true
            }
        }
    }

    private var breakdownPanel: some View {
        let homeGoals = live.events.filter { $0.type == .goal && $0.teamId == live.homeTeamId }.count
        let awayGoals = live.events.filter { $0.type == .goal && $0.teamId == live.awayTeamId }.count
        let homeCards = live.events.filter { ($0.type == .yellow || $0.type == .red) && $0.teamId == live.homeTeamId }.count
        let awayCards = live.events.filter { ($0.type == .yellow || $0.type == .red) && $0.teamId == live.awayTeamId }.count
        return DataPanel {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: "Breakdown")
                comparisonRow("Goal events", homeGoals, awayGoals)
                comparisonRow("Cards", homeCards, awayCards)
                comparisonRow("Total events",
                              live.events.filter { $0.teamId == live.homeTeamId }.count,
                              live.events.filter { $0.teamId == live.awayTeamId }.count)
            }
        }
    }

    private func comparisonRow(_ label: String, _ home: Int, _ away: Int) -> some View {
        let total = max(1, home + away)
        return VStack(spacing: 6) {
            HStack {
                Text("\(home)").font(.subheadline.weight(.bold)).foregroundStyle(Theme.emerald)
                Spacer()
                Text(label).font(.caption).foregroundStyle(Theme.textSecondary)
                Spacer()
                Text("\(away)").font(.subheadline.weight(.bold)).foregroundStyle(Theme.blue)
            }
            GeometryReader { geo in
                HStack(spacing: 2) {
                    Capsule().fill(Theme.emerald)
                        .frame(width: geo.size.width * CGFloat(home) / CGFloat(total))
                    Capsule().fill(Theme.blue)
                        .frame(width: geo.size.width * CGFloat(away) / CGFloat(total))
                }
            }
            .frame(height: 6)
        }
    }

    private var timelinePanel: some View {
        DataPanel {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: "Event Timeline", subtitle: "\(live.events.count) events",
                              actionTitle: "Add") { showEventSheet = true }
                if live.events.isEmpty {
                    EmptyHint(icon: "clock.badge.questionmark", title: "No events",
                              message: "Record goals, cards and key moments.")
                } else {
                    ForEach(live.events.sorted { $0.minute < $1.minute }) { ev in
                        eventRow(ev)
                    }
                }
            }
        }
    }

    private func eventRow(_ ev: MatchEvent) -> some View {
        let isHome = ev.teamId == live.homeTeamId
        return HStack(spacing: 12) {
            Text("\(ev.minute)'")
                .font(.caption.weight(.bold))
                .foregroundStyle(Theme.textSecondary)
                .frame(width: 34, alignment: .leading)
            Image(systemName: ev.type.icon)
                .font(.caption)
                .foregroundStyle(ev.type.color)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 1) {
                Text(ev.playerName).font(.subheadline.weight(.semibold)).foregroundStyle(Theme.textPrimary)
                Text("\(ev.type.title) · \(store.teamShort(ev.teamId))")
                    .font(.caption2).foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            Image(systemName: isHome ? "arrow.left" : "arrow.right")
                .font(.caption2)
                .foregroundStyle(isHome ? Theme.emerald : Theme.blue)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .contextMenu {
            Button(role: .destructive) { deleteEvent(ev) } label: {
                Label("Delete Event", systemImage: "trash")
            }
        }
    }

    private func deleteEvent(_ ev: MatchEvent) {
        var m = live
        m.events.removeAll { $0.id == ev.id }
        store.updateMatch(m); Haptics.warning()
    }

    private var notePanel: some View {
        DataPanel {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Analyst Note",
                              actionTitle: editingNote ? "Save" : "Edit") {
                    if editingNote {
                        var m = live; m.note = noteDraft; store.updateMatch(m); Haptics.success()
                    } else {
                        noteDraft = live.note
                    }
                    editingNote.toggle()
                }
                if editingNote {
                    TextEditor(text: $noteDraft)
                        .frame(minHeight: 100)
                        .scrollContentBackground(.hidden)
                        .padding(8)
                        .background(Theme.surface2)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(Theme.textPrimary)
                } else if live.note.isEmpty {
                    Text("No tactical note yet. Tap Edit to add observations.")
                        .font(.subheadline).foregroundStyle(Theme.textSecondary)
                } else {
                    Text(live.note)
                        .font(.subheadline).foregroundStyle(Theme.textPrimary)
                }
            }
        }
    }
}
