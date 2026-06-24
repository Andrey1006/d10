import SwiftUI

struct MainTabView: View {
    @State private var selection = 0

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Theme.surface1)
        appearance.shadowColor = UIColor.white.withAlphaComponent(0.06)
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView(selection: $selection) {
            DashboardView()
                .tabItem { Label("Overview", systemImage: "chart.bar.xaxis") }
                .tag(0)

            TeamsView()
                .tabItem { Label("Squad", systemImage: "person.3.fill") }
                .tag(1)

            MatchesView()
                .tabItem { Label("Matches", systemImage: "sportscourt.fill") }
                .tag(2)

            AnalyticsView()
                .tabItem { Label("Analytics", systemImage: "chart.xyaxis.line") }
                .tag(3)

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.crop.circle.fill") }
                .tag(4)
        }
        .tint(Theme.emerald)
    }
}
