import SwiftUI
import WebKit

struct WebDocument: Identifiable {
    let id = UUID()
    let title: String
    let url: URL
}

struct WebView: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.isOpaque = false
        webView.backgroundColor = UIColor(Theme.background)
        webView.scrollView.backgroundColor = UIColor(Theme.background)
        webView.scrollView.showsVerticalScrollIndicator = false
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) { }

    final class Coordinator: NSObject, WKNavigationDelegate {
        let parent: WebView
        init(_ parent: WebView) { self.parent = parent }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.isLoading = true
        }
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
        }
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
        }
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
        }
    }
}

struct WebSheetView: View {
    @Environment(\.dismiss) private var dismiss
    let document: WebDocument
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                WebView(url: document.url, isLoading: $isLoading)
                    .ignoresSafeArea(edges: .bottom)
                if isLoading {
                    VStack(spacing: 14) {
                        ProgressView().tint(Theme.emerald)
                        Text("Loading…")
                            .font(.subheadline)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            }
            .navigationTitle(document.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { Haptics.tap(); dismiss() }.fontWeight(.bold)
                }
            }
            .appFont()
        }
    }
}
