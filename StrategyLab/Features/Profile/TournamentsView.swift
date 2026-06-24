import SwiftUI

struct TournamentsView: View {
    @EnvironmentObject var store: DataStore
    @State private var showAdd = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {
                if store.tournaments.isEmpty {
                    EmptyHint(icon: "trophy", title: "No tournaments",
                              message: "Add a tournament to group your fixtures.")
                } else {
                    ForEach(store.tournaments) { t in
                        DataPanel(padding: 14) {
                            HStack(spacing: 14) {
                                Image(systemName: "trophy.fill")
                                    .foregroundStyle(Theme.gold)
                                    .frame(width: 40, height: 40)
                                    .background(Theme.gold.opacity(0.15))
                                    .clipShape(RoundedRectangle(cornerRadius: 11))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(t.name).font(.subheadline.weight(.bold)).foregroundStyle(Theme.textPrimary)
                                    Text("Season \(t.season)").font(.caption).foregroundStyle(Theme.textSecondary)
                                }
                                Spacer()
                                Text("\(matchCount(t)) games")
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(Theme.blue)
                                Button {
                                    store.deleteTournament(t); Haptics.warning()
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(Theme.danger)
                                        .frame(width: 34, height: 34)
                                        .background(Theme.danger.opacity(0.15))
                                        .clipShape(RoundedRectangle(cornerRadius: 9))
                                }
                            }
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Tournaments")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { Haptics.tap(); showAdd = true } label: {
                    Image(systemName: "plus.circle.fill").foregroundStyle(Theme.emerald)
                }
            }
        }
        .sheet(isPresented: $showAdd) { TournamentEditorView() }
        .appFont()
    }

    private func matchCount(_ t: Tournament) -> Int {
        store.matches.filter { $0.tournament == t.name && $0.season == t.season }.count
    }
}

struct TournamentEditorView: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var season = SeedData.curSeason

    private let seasons = ["2025/26", "2024/25", "2023/24", "2026/27"]

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    FormSection(title: "Tournament") {
                        AppTextField(title: "Name", text: $name,
                                     placeholder: "e.g. Premier Division", icon: "trophy.fill")
                        VStack(alignment: .leading, spacing: 7) {
                            Text("SEASON").font(.caption2.weight(.bold)).foregroundStyle(Theme.textSecondary)
                            LazyVGrid(columns: Array(repeating: GridItem(spacing: 8), count: 2), spacing: 8) {
                                ForEach(seasons, id: \.self) { s in
                                    Button { Haptics.tap(); season = s } label: {
                                        Text(s)
                                            .font(.subheadline.weight(.bold))
                                            .foregroundStyle(season == s ? Color(hex: "#0A0D12") : Theme.textSecondary)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(season == s ? Theme.emerald : Theme.surface2)
                                            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(16)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("New Tournament")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.addTournament(Tournament(name: name, season: season))
                        Haptics.success(); dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .fontWeight(.bold)
                }
            }
            .appFont()
        }
    }
}
