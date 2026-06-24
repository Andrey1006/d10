import SwiftUI

struct OnboardingPage: Identifiable {
    let id = UUID()
    let icon: String
    let color: Color
    let title: String
    let subtitle: String
}

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var page = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(icon: "chart.bar.xaxis", color: Theme.emerald,
                       title: "Your Scouting Terminal",
                       subtitle: "Teams, players, matches and seasons — one professional analytics workspace instead of scattered spreadsheets."),
        OnboardingPage(icon: "chart.xyaxis.line", color: Theme.blue,
                       title: "Compare & Spot Trends",
                       subtitle: "Interactive charts, side-by-side player comparisons, leaderboards and season-over-season development curves."),
        OnboardingPage(icon: "trophy.fill", color: Theme.gold,
                       title: "Decide With Data",
                       subtitle: "Live match events, physical metrics and analyst notes that turn every game into part of your knowledge base."),
    ]

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { idx, p in
                        pageView(p).tag(idx)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                indicator
                    .padding(.bottom, 24)

                controls
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
            }
        }
        .appFont()
    }

    private func pageView(_ p: OnboardingPage) -> some View {
        VStack(spacing: 28) {
            Spacer()
            ZStack {
                Circle()
                    .fill(p.color.opacity(0.15))
                    .frame(width: 160, height: 160)
                Circle()
                    .stroke(p.color.opacity(0.4), lineWidth: 1.5)
                    .frame(width: 200, height: 200)
                Image(systemName: p.icon)
                    .font(.system(size: 64, weight: .bold))
                    .foregroundStyle(p.color)
            }
            VStack(spacing: 14) {
                Text(p.title)
                    .font(.largeTitle.weight(.heavy))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.textPrimary)
                Text(p.subtitle)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.horizontal, 32)
            }
            Spacer()
        }
    }

    private var indicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<pages.count, id: \.self) { i in
                Capsule()
                    .fill(i == page ? Theme.emerald : Theme.surface3)
                    .frame(width: i == page ? 24 : 8, height: 8)
                    .animation(.easeOut(duration: 0.2), value: page)
            }
        }
    }

    private var controls: some View {
        VStack(spacing: 12) {
            PrimaryButton(title: page == pages.count - 1 ? "Enter Workspace" : "Continue",
                          icon: "arrow.right") {
                if page == pages.count - 1 {
                    Haptics.success()
                    hasSeenOnboarding = true
                } else {
                    withAnimation { page += 1 }
                }
            }
            if page != pages.count - 1 {
                Button("Skip") {
                    Haptics.tap(); hasSeenOnboarding = true
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Theme.textSecondary)
            }
        }
    }
}
