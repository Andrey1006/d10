import SwiftUI
@preconcurrency import WebKit

struct NovaView: View {
    let targetUrl: String

    var body: some View {
        NavigationView {
            NovaContainer(targetUrl: targetUrl)
                .navigationBarHidden(true)
                .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .background(Color.black.ignoresSafeArea(.all))
    }
}

struct NovaContainer: View {
    let targetUrl: String
    @State private var webView = WKWebView()
    @State private var canGoBack = false
    @State private var canGoForward = false
    @AppStorage("labEntry") var point: String = ""
    @AppStorage("labStored") var placesaved: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            NovaWrapper(
                webView: $webView,
                targetUrl: targetUrl,
                canGoBack: $canGoBack,
                canGoForward: $canGoForward,
                point: $point,
                placesaved: $placesaved
            )

            HStack {
                Spacer()
                Button {
                    if webView.canGoBack { webView.goBack() }
                } label: {
                    Image(systemName: "chevron.backward")
                        .font(.title2)
                        .foregroundStyle(.white)
                }
                .padding(8)

                Spacer()

                Button {
                    if webView.canGoForward { webView.goForward() }
                } label: {
                    Image(systemName: "chevron.forward")
                        .font(.title2)
                        .foregroundStyle(.white)
                }
                .padding(8)

                Spacer()
            }
            .background(Color.black)
        }
        .background(Color.black.ignoresSafeArea(.all))
    }
}

struct NovaWrapper: UIViewRepresentable {
    @Binding var webView: WKWebView
    let targetUrl: String
    @Binding var canGoBack: Bool
    @Binding var canGoForward: Bool
    @Binding var point: String
    @Binding var placesaved: Bool

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.defaultWebpagePreferences.allowsContentJavaScript = true
        config.mediaTypesRequiringUserActionForPlayback = []

        let wk = WKWebView(frame: .zero, configuration: config)
        wk.navigationDelegate = context.coordinator
        wk.uiDelegate = context.coordinator

        guard let url = URL(string: targetUrl), UIApplication.shared.canOpenURL(url) else {
            return wk
        }
        wk.load(URLRequest(url: url))
        wk.allowsBackForwardNavigationGestures = true

        DispatchQueue.main.async {
            self.webView = wk
        }

        return wk
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        var parent: NovaWrapper

        init(_ parent: NovaWrapper) { self.parent = parent }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.canGoBack = webView.canGoBack
                self.parent.canGoForward = webView.canGoForward

                if let url = webView.url?.absoluteString, !self.parent.placesaved {
                    self.parent.placesaved = true
                    self.parent.point = url
                }
            }
        }

        @available(iOS 15, *)
        func webView(_ webView: WKWebView,
                     requestMediaCapturePermissionFor origin: WKSecurityOrigin,
                     initiatedByFrame frame: WKFrameInfo,
                     type: WKMediaCaptureType,
                     decisionHandler: @escaping (WKPermissionDecision) -> Void) {
            decisionHandler(.grant)
        }

        func webView(_ webView: WKWebView,
                     createWebViewWith configuration: WKWebViewConfiguration,
                     for navigationAction: WKNavigationAction,
                     windowFeatures: WKWindowFeatures) -> WKWebView? {
            if navigationAction.targetFrame == nil {
                webView.load(navigationAction.request)
            }
            return nil
        }
    }
}
