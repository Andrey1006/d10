import SwiftUI

struct RadarAxis: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
}

struct RadarChart: View {
    let axes: [RadarAxis]
    var compareAxes: [RadarAxis]? = nil
    var primaryColor: Color = Theme.emerald
    var compareColor: Color = Theme.blue
    var rings: Int = 4

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius = size / 2 - 26

            ZStack {
                ForEach(1...rings, id: \.self) { r in
                    polygonPath(center: center, radius: radius * CGFloat(r) / CGFloat(rings),
                                count: axes.count)
                        .stroke(Theme.panelStroke, lineWidth: 1)
                }
                ForEach(0..<axes.count, id: \.self) { i in
                    Path { p in
                        p.move(to: center)
                        p.addLine(to: vertex(center: center, radius: radius, index: i, total: axes.count))
                    }
                    .stroke(Theme.panelStroke, lineWidth: 1)
                }
                if let compareAxes {
                    seriesShape(values: compareAxes.map { $0.value }, center: center, radius: radius)
                        .fill(compareColor.opacity(0.18))
                    seriesShape(values: compareAxes.map { $0.value }, center: center, radius: radius)
                        .stroke(compareColor, lineWidth: 2)
                }
                seriesShape(values: axes.map { $0.value }, center: center, radius: radius)
                    .fill(primaryColor.opacity(0.25))
                seriesShape(values: axes.map { $0.value }, center: center, radius: radius)
                    .stroke(primaryColor, lineWidth: 2)

                ForEach(0..<axes.count, id: \.self) { i in
                    let pt = vertex(center: center, radius: radius + 16, index: i, total: axes.count)
                    Text(axes[i].label)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Theme.textSecondary)
                        .position(pt)
                }
            }
        }
    }

    private func vertex(center: CGPoint, radius: CGFloat, index: Int, total: Int) -> CGPoint {
        let angle = (Double(index) / Double(total)) * 2 * .pi - .pi / 2
        return CGPoint(x: center.x + radius * CGFloat(cos(angle)),
                       y: center.y + radius * CGFloat(sin(angle)))
    }

    private func polygonPath(center: CGPoint, radius: CGFloat, count: Int) -> Path {
        Path { p in
            for i in 0..<count {
                let pt = vertex(center: center, radius: radius, index: i, total: count)
                if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
            }
            p.closeSubpath()
        }
    }

    private func seriesShape(values: [Double], center: CGPoint, radius: CGFloat) -> Path {
        Path { p in
            for i in 0..<values.count {
                let v = min(1, max(0.04, values[i]))
                let pt = vertex(center: center, radius: radius * CGFloat(v), index: i, total: values.count)
                if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
            }
            p.closeSubpath()
        }
    }
}

extension Player {
    func radarAxes() -> [RadarAxis] {
        let s = current
        return [
            RadarAxis(label: "Attack",   value: min(1, Double(s.goals) / 22.0)),
            RadarAxis(label: "Creation", value: min(1, Double(s.assists) / 14.0)),
            RadarAxis(label: "Passing",  value: min(1, s.passAccuracy / 95.0)),
            RadarAxis(label: "Defense",  value: min(1, Double(s.tackles + s.interceptions) / 130.0)),
            RadarAxis(label: "Physical", value: min(1, s.distanceKm / 330.0)),
            RadarAxis(label: "Pace",     value: min(1, (s.topSpeedKmh - 28) / 9.0)),
        ]
    }
}
