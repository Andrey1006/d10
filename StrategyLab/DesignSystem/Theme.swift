import SwiftUI

extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var rgb: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&rgb)
        let r, g, b: Double
        if cleaned.count == 6 {
            r = Double((rgb & 0xFF0000) >> 16) / 255
            g = Double((rgb & 0x00FF00) >> 8) / 255
            b = Double(rgb & 0x0000FF) / 255
        } else {
            r = 1; g = 1; b = 1
        }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }
}

enum Theme {
    static let background = Color(hex: "#12161D")
    static let surface1   = Color(hex: "#1A202A")
    static let surface2   = Color(hex: "#232C38")
    static let surface3   = Color(hex: "#2D3847")

    static let emerald    = Color(hex: "#1FA15B")
    static let blue       = Color(hex: "#27B5FF")
    static let gold       = Color(hex: "#F0B84A")
    static let danger     = Color(hex: "#FF6A4D")

    static let textPrimary   = Color(hex: "#F5F7FA")
    static let textSecondary = Color(hex: "#96A2B1")

    static let emeraldGradient = LinearGradient(
        colors: [emerald, emerald.opacity(0.65)],
        startPoint: .topLeading, endPoint: .bottomTrailing)

    static let blueGradient = LinearGradient(
        colors: [blue, blue.opacity(0.6)],
        startPoint: .topLeading, endPoint: .bottomTrailing)

    static let areaBlueGradient = LinearGradient(
        colors: [blue.opacity(0.35), blue.opacity(0.02)],
        startPoint: .top, endPoint: .bottom)

    static let panelStroke = Color.white.opacity(0.06)
}

extension View {
    func appFont() -> some View { self.fontDesign(.rounded) }
}

enum Haptics {
    static func tap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}
