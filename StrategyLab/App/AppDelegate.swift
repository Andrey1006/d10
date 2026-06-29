import SwiftUI
import UIKit
import AppsFlyerLib
import FirebaseCore

@main
final class AppDelegate: NSObject, UIApplicationDelegate {

    var window: UIWindow?
    private let store = DataStore()

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        FirebaseApp.configure()

        AppsFlyerLib.shared().initialize(devKey: "tbtLBziE5edcZJZB9pvnkn", appId: "6783727535")
        AppsFlyerLib.shared().delegate = self

        let rootView = RootView()
            .environmentObject(store)
            .preferredColorScheme(.dark)
            .tint(Theme.emerald)

        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = UIHostingController(rootView: rootView)
        window.makeKeyAndVisible()
        self.window = window

        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        AppsFlyerLib.shared().start()
    }
}

extension AppDelegate: AppsFlyerLibDelegate {
    func onConversionDataSuccess(_ conversionInfo: [AnyHashable: Any]) {
        let campaign = conversionInfo["c"] as? String ?? conversionInfo["campaign"] as? String ?? ""
        UserDefaults.standard.setValue(campaign, forKey: "labMeta")
        UserDefaults.standard.setValue(true, forKey: "labReady")
    }

    func onConversionDataFail(_ error: Error) {
        UserDefaults.standard.setValue("", forKey: "labMeta")
        UserDefaults.standard.setValue(true, forKey: "labReady")
    }
}
