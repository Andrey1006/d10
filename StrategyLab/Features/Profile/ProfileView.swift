import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var store: DataStore
    @AppStorage("analystName") private var analystName = "Lead Analyst"
    @AppStorage("analystRole") private var analystRole = "Performance Analyst"
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = true

    @State private var showProfileEditor = false
    @State private var showResetAlert = false
    @State private var showWipeAlert = false
    @State private var webDoc: WebDocument?

    private let roles = ["Performance Analyst", "Head Coach", "Scout", "Team Manager"]

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    profileHeader
                    statsOverview
                    tournamentsLink
                    dataSection
                    legalSection
                }
                .padding(16)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Profile")
            .sheet(isPresented: $showProfileEditor) { profileEditor }
            .sheet(item: $webDoc) { WebSheetView(document: $0) }
            .alert("Reset to sample data?", isPresented: $showResetAlert) {
                Button("Reset", role: .destructive) { store.resetToSampleData(); Haptics.success() }
                Button("Cancel", role: .cancel) { }
            } message: { Text("Replaces current data with the demo dataset.") }
            .alert("Delete all data?", isPresented: $showWipeAlert) {
                Button("Delete Everything", role: .destructive) { store.wipeAll(); Haptics.warning() }
                Button("Cancel", role: .cancel) { }
            } message: { Text("Removes all teams, players and matches. This cannot be undone.") }
        }
    }

    private var profileHeader: some View {
        DataPanel {
            HStack(spacing: 16) {
                ZStack {
                    Circle().fill(Theme.emeraldGradient).frame(width: 70, height: 70)
                    Text(initials).font(.title2.weight(.heavy)).foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(analystName).font(.title3.weight(.heavy)).foregroundStyle(Theme.textPrimary)
                    Text(analystRole).font(.subheadline).foregroundStyle(Theme.emerald)
                    Text("Novoline Strategy Workspace").font(.caption).foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                Button { Haptics.tap(); showProfileEditor = true } label: {
                    Image(systemName: "pencil.circle.fill").font(.title2).foregroundStyle(Theme.blue)
                }
            }
        }
        .appFont()
    }

    private var initials: String {
        let parts = analystName.split(separator: " ")
        return ((parts.first?.prefix(1) ?? "A") + (parts.dropFirst().first?.prefix(1) ?? "")).uppercased()
    }

    private var statsOverview: some View {
        HStack(spacing: 12) {
            StatPill(label: "Teams", value: "\(store.teams.count)", tint: Theme.emerald)
            StatPill(label: "Players", value: "\(store.players.count)", tint: Theme.blue)
            StatPill(label: "Matches", value: "\(store.matches.count)", tint: Theme.gold)
            StatPill(label: "Events", value: "\(store.matches.reduce(0) { $0 + $1.events.count })", tint: Theme.danger)
        }
    }

    private var tournamentsLink: some View {
        NavigationLink {
            TournamentsView()
        } label: {
            settingsRow("trophy.fill", Theme.gold, "Tournaments & Seasons",
                        "\(store.tournaments.count) configured", chevron: true)
        }
        .buttonStyle(.plain)
    }

    private var dataSection: some View {
        DataPanel {
            VStack(spacing: 0) {
                Button { Haptics.tap(); showResetAlert = true } label: {
                    settingsRow("arrow.clockwise", Theme.blue, "Load Sample Data", "Restore demo dataset")
                }
                Divider().overlay(Theme.panelStroke)
                Button { Haptics.tap(); showWipeAlert = true } label: {
                    settingsRow("trash.fill", Theme.danger, "Delete All Data", "Start from empty")
                }
                Divider().overlay(Theme.panelStroke)
                Button { Haptics.tap(); hasSeenOnboarding = false } label: {
                    settingsRow("sparkles", Theme.emerald, "Replay Onboarding", "Show the intro again")
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var legalSection: some View {
        DataPanel {
            VStack(spacing: 0) {
                Button {
                    Haptics.tap()
                    webDoc = WebDocument(title: "Privacy Policy",
                                         url: URL(string: "https://sites.google.com/view/novalinesportsplus/privacy-policy")!)
                } label: {
                    settingsRow("lock.shield.fill", Theme.emerald, "Privacy Policy", nil, chevron: true)
                }
                Divider().overlay(Theme.panelStroke)
                Button {
                    Haptics.tap()
                    webDoc = WebDocument(title: "Terms of Service",
                                         url: URL(string: "https://sites.google.com/view/novalinesportsplus/terms-of-service")!)
                } label: {
                    settingsRow("doc.text.fill", Theme.textSecondary, "Terms of Service", nil, chevron: true)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var aboutSection: some View {
        DataPanel {
            HStack {
                Text("Version").font(.subheadline).foregroundStyle(Theme.textPrimary)
                Spacer()
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                    .font(.subheadline).foregroundStyle(Theme.textSecondary)
            }
        }
        .appFont()
    }

    private func settingsRow(_ icon: String, _ tint: Color, _ title: String,
                             _ subtitle: String?, chevron: Bool = false) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 34, height: 34)
                .background(tint.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 9))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(Theme.textPrimary)
                if let subtitle {
                    Text(subtitle).font(.caption2).foregroundStyle(Theme.textSecondary)
                }
            }
            Spacer()
            if chevron {
                Image(systemName: "chevron.right").font(.caption.weight(.bold)).foregroundStyle(Theme.textSecondary)
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .appFont()
    }

    private var profileEditor: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    FormSection(title: "Analyst") {
                        AppTextField(title: "Name", text: $analystName,
                                     placeholder: "Your name", icon: "person.fill")
                        VStack(alignment: .leading, spacing: 7) {
                            Text("ROLE").font(.caption2.weight(.bold)).foregroundStyle(Theme.textSecondary)
                            VStack(spacing: 8) {
                                ForEach(roles, id: \.self) { role in
                                    Button { Haptics.tap(); analystRole = role } label: {
                                        HStack {
                                            Text(role).foregroundStyle(Theme.textPrimary)
                                            Spacer()
                                            if analystRole == role {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundStyle(Theme.emerald)
                                            }
                                        }
                                        .fieldStyle()
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(16)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { Haptics.success(); showProfileEditor = false }.fontWeight(.bold)
                }
            }
            .appFont()
        }
    }
}
