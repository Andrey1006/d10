import SwiftUI

struct MatchEditorView: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) private var dismiss

    @State private var homeId: UUID?
    @State private var awayId: UUID?
    @State private var date = Date()
    @State private var tournament = ""
    @State private var isFinished = false
    @State private var homeScore = 0
    @State private var awayScore = 0

    private var tournamentOptions: [String] {
        Array(Set(store.tournaments.map { $0.name } + store.matches.map { $0.tournament })).sorted()
    }

    private var isValid: Bool {
        guard let h = homeId, let a = awayId else { return false }
        return h != a && !tournament.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    teamsSection
                    fixtureSection
                    resultSection
                }
                .padding(16)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("New Match")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(!isValid).fontWeight(.bold)
                }
            }
            .appFont()
        }
    }

    private var teamsSection: some View {
        FormSection(title: "Teams") {
            teamSelector(title: "Home", selection: $homeId, exclude: awayId, tint: Theme.emerald)
            teamSelector(title: "Away", selection: $awayId, exclude: homeId, tint: Theme.blue)
            if let h = homeId, let a = awayId, h == a {
                Text("Home and away must differ")
                    .font(.caption).foregroundStyle(Theme.danger)
            }
        }
    }

    private func teamSelector(title: String, selection: Binding<UUID?>, exclude: UUID?, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title.uppercased())
                .font(.caption2.weight(.bold)).foregroundStyle(Theme.textSecondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(store.teams) { team in
                        let selected = selection.wrappedValue == team.id
                        Button {
                            Haptics.tap(); selection.wrappedValue = team.id
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: team.crest)
                                Text(team.shortName)
                            }
                            .font(.caption.weight(.bold))
                            .foregroundStyle(selected ? Color(hex: "#0A0D12") : Theme.textPrimary)
                            .padding(.horizontal, 14).padding(.vertical, 10)
                            .background(selected ? tint : Theme.surface2)
                            .opacity(team.id == exclude ? 0.35 : 1)
                            .clipShape(Capsule())
                        }
                        .disabled(team.id == exclude)
                    }
                }
            }
        }
        .appFont()
    }

    private var fixtureSection: some View {
        FormSection(title: "Fixture") {
            DatePicker("Kickoff", selection: $date)
                .tint(Theme.emerald)
                .foregroundStyle(Theme.textPrimary)
                .fieldStyle()
            AppTextField(title: "Tournament", text: $tournament,
                         placeholder: "e.g. Premier Division", icon: "trophy.fill")
            if !tournamentOptions.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(tournamentOptions, id: \.self) { t in
                            Button { Haptics.tap(); tournament = t } label: {
                                Text(t)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(tournament == t ? Color(hex: "#0A0D12") : Theme.blue)
                                    .padding(.horizontal, 12).padding(.vertical, 7)
                                    .background(tournament == t ? Theme.blue : Theme.surface2)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
        }
    }

    private var resultSection: some View {
        FormSection(title: "Result") {
            Toggle("Match finished", isOn: $isFinished)
                .tint(Theme.emerald)
                .foregroundStyle(Theme.textPrimary)
                .fieldStyle()
            if isFinished {
                LabeledStepper(label: "Home score", value: $homeScore, range: 0...30)
                LabeledStepper(label: "Away score", value: $awayScore, range: 0...30)
            }
        }
    }

    private func save() {
        guard let h = homeId, let a = awayId else { return }
        let m = Match(homeTeamId: h, awayTeamId: a, date: date, tournament: tournament,
                      season: store.activeSeason, homeScore: homeScore, awayScore: awayScore,
                      isFinished: isFinished, events: [])
        store.addMatch(m); Haptics.success(); dismiss()
    }
}

struct EventEntryView: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) private var dismiss
    let match: Match

    @State private var minute = 1
    @State private var type: EventType = .goal
    @State private var teamId: UUID
    @State private var playerName = ""
    @State private var detail = ""

    init(match: Match) {
        self.match = match
        _teamId = State(initialValue: match.homeTeamId)
    }

    private var squad: [Player] { store.players(of: teamId) }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    eventSection
                    playerSection
                }
                .padding(16)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Add Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { save() }
                        .disabled(playerName.trimmingCharacters(in: .whitespaces).isEmpty)
                        .fontWeight(.bold)
                }
            }
            .appFont()
        }
    }

    private var eventSection: some View {
        FormSection(title: "Event") {
            VStack(alignment: .leading, spacing: 7) {
                Text("TYPE").font(.caption2.weight(.bold)).foregroundStyle(Theme.textSecondary)
                LazyVGrid(columns: Array(repeating: GridItem(spacing: 8), count: 4), spacing: 8) {
                    ForEach(EventType.allCases) { t in
                        Button { Haptics.tap(); type = t } label: {
                            VStack(spacing: 5) {
                                Image(systemName: t.icon)
                                Text(t.title).font(.system(size: 9, weight: .semibold))
                                    .lineLimit(1).minimumScaleFactor(0.7)
                            }
                            .foregroundStyle(type == t ? Color(hex: "#0A0D12") : Theme.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(type == t ? t.color : Theme.surface2)
                            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                        }
                    }
                }
            }
            LabeledStepper(label: "Minute", value: $minute, range: 1...120)
            teamToggle
        }
    }

    private var teamToggle: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("TEAM").font(.caption2.weight(.bold)).foregroundStyle(Theme.textSecondary)
            HStack(spacing: 8) {
                ForEach([match.homeTeamId, match.awayTeamId], id: \.self) { id in
                    Button { Haptics.tap(); teamId = id } label: {
                        Text(store.teamName(id))
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(teamId == id ? Color(hex: "#0A0D12") : Theme.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(teamId == id ? Theme.emerald : Theme.surface2)
                            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                    }
                }
            }
        }
        .appFont()
    }

    private var playerSection: some View {
        FormSection(title: "Player") {
            AppTextField(title: "Player name", text: $playerName,
                         placeholder: "Who was involved", icon: "person.fill")
            if !squad.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(squad) { p in
                            Button { playerName = p.name; Haptics.tap() } label: {
                                Text(p.name)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(playerName == p.name ? Color(hex: "#0A0D12") : Theme.textPrimary)
                                    .padding(.horizontal, 12).padding(.vertical, 7)
                                    .background(playerName == p.name ? Theme.emerald : Theme.surface2)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
            AppTextField(title: "Detail (optional)", text: $detail,
                         placeholder: "Notes", icon: "text.alignleft")
        }
    }

    private func save() {
        var m = match
        m.events.append(MatchEvent(minute: minute, type: type, teamId: teamId,
                                   playerName: playerName, detail: detail))
        store.updateMatch(m); Haptics.success(); dismiss()
    }
}

struct ScoreEditorView: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) private var dismiss
    let match: Match

    @State private var homeScore: Int
    @State private var awayScore: Int
    @State private var isFinished: Bool

    init(match: Match) {
        self.match = match
        _homeScore = State(initialValue: match.homeScore)
        _awayScore = State(initialValue: match.awayScore)
        _isFinished = State(initialValue: match.isFinished)
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    FormSection(title: "Status") {
                        Toggle("Match finished", isOn: $isFinished)
                            .tint(Theme.emerald)
                            .foregroundStyle(Theme.textPrimary)
                            .fieldStyle()
                    }
                    FormSection(title: "Score") {
                        LabeledStepper(label: store.teamName(match.homeTeamId), value: $homeScore, range: 0...30)
                        LabeledStepper(label: store.teamName(match.awayTeamId), value: $awayScore, range: 0...30)
                    }
                }
                .padding(16)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Edit Result")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.fontWeight(.bold)
                }
            }
            .appFont()
        }
    }

    private func save() {
        var m = match
        m.homeScore = homeScore; m.awayScore = awayScore; m.isFinished = isFinished
        store.updateMatch(m); Haptics.success(); dismiss()
    }
}
