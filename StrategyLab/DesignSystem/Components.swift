import SwiftUI

struct DataPanel<Content: View>: View {
    var padding: CGFloat = 16
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surface1)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Theme.panelStroke, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

struct SectionHeader: View {
    let title: String
    var subtitle: String? = nil
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Theme.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            Spacer()
            if let actionTitle, let action {
                Button(action: { Haptics.tap(); action() }) {
                    Text(actionTitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.blue)
                }
            }
        }
        .appFont()
    }
}

struct KPITile: View {
    let title: String
    let value: String
    let icon: String
    var tint: Color = Theme.emerald
    var delta: String? = nil
    var deltaPositive: Bool = true

    var body: some View {
        DataPanel(padding: 14) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: icon.isEmpty ? "square.dashed" : icon)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(tint)
                        .frame(width: 34, height: 34)
                        .background(tint.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    Spacer()
                    if let delta {
                        Text(delta)
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(deltaPositive ? Theme.emerald : Theme.danger)
                            .padding(.horizontal, 7).padding(.vertical, 3)
                            .background((deltaPositive ? Theme.emerald : Theme.danger).opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
                Spacer(minLength: 8)
                Text(value)
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .appFont()
    }
}

struct StatPill: View {
    let label: String
    let value: String
    var tint: Color = Theme.textPrimary

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline.weight(.bold))
                .foregroundStyle(tint)
            Text(label)
                .font(.caption2)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Theme.surface2)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .appFont()
    }
}

struct PrimaryButton: View {
    let title: String
    var icon: String? = nil
    var tint: Color = Theme.emerald
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.tap(); action()
        } label: {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon.isEmpty ? "square.dashed" : icon)
                }
                Text(title).fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .foregroundStyle(Color(hex: "#0A0D12"))
            .background(tint)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .appFont()
    }
}

struct PillSegment: View {
    let options: [String]
    @Binding var selection: Int

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(options.enumerated()), id: \.offset) { idx, title in
                Button {
                    Haptics.tap()
                    withAnimation(.easeOut(duration: 0.2)) { selection = idx }
                } label: {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(selection == idx ? Color(hex: "#0A0D12") : Theme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(selection == idx ? Theme.blue : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                }
            }
        }
        .padding(4)
        .background(Theme.surface2)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .appFont()
    }
}

struct ResultBadge: View {
    let result: MatchResult

    var body: some View {
        Text(result.short)
            .font(.caption2.weight(.heavy))
            .foregroundStyle(Color(hex: "#0A0D12"))
            .frame(width: 22, height: 22)
            .background(result.color)
            .clipShape(Circle())
    }
}

struct FormStrip: View {
    let results: [MatchResult]
    var body: some View {
        HStack(spacing: 5) {
            ForEach(Array(results.enumerated()), id: \.offset) { _, r in
                ResultBadge(result: r)
            }
        }
    }
}

struct EmptyHint: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon.isEmpty ? "square.dashed" : icon)
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(Theme.textSecondary)
            Text(title)
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)
            Text(message)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .appFont()
    }
}

struct MetricBar: View {
    let label: String
    let value: Double
    let normalized: Double
    var tint: Color = Theme.emerald
    var valueText: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                Text(valueText ?? String(format: "%.0f", value))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Theme.textPrimary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.surface3)
                    Capsule()
                        .fill(tint)
                        .frame(width: max(6, geo.size.width * min(1, max(0, normalized))))
                }
            }
            .frame(height: 8)
        }
        .appFont()
    }
}

extension View {
    func fieldStyle() -> some View {
        self
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background(Theme.surface2)
            .overlay(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .stroke(Theme.panelStroke, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
    }
}

struct AppTextField: View {
    let title: String
    @Binding var text: String
    var placeholder: String = ""
    var icon: String? = nil
    var autocapitalization: TextInputAutocapitalization = .sentences

    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title.uppercased())
                .font(.caption2.weight(.bold))
                .foregroundStyle(Theme.textSecondary)
            HStack(spacing: 10) {
                if let icon {
                    Image(systemName: icon.isEmpty ? "square.dashed" : icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(focused ? Theme.emerald : Theme.textSecondary)
                        .frame(width: 18)
                }
                TextField("", text: $text,
                          prompt: Text(placeholder).foregroundColor(Theme.textSecondary.opacity(0.55)))
                    .focused($focused)
                    .foregroundStyle(Theme.textPrimary)
                    .textInputAutocapitalization(autocapitalization)
                    .autocorrectionDisabled()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background(Theme.surface2)
            .overlay(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .stroke(focused ? Theme.emerald.opacity(0.7) : Theme.panelStroke,
                            lineWidth: focused ? 1.5 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
            .animation(.easeOut(duration: 0.15), value: focused)
        }
        .appFont()
    }
}

struct AppTextEditor: View {
    let title: String
    @Binding var text: String
    var minHeight: CGFloat = 110

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title.uppercased())
                .font(.caption2.weight(.bold))
                .foregroundStyle(Theme.textSecondary)
            TextEditor(text: $text)
                .frame(minHeight: minHeight)
                .scrollContentBackground(.hidden)
                .foregroundStyle(Theme.textPrimary)
                .padding(10)
                .background(Theme.surface2)
                .overlay(
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .stroke(Theme.panelStroke, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
        }
        .appFont()
    }
}

struct FormSection<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.caption.weight(.bold))
                .foregroundStyle(Theme.textSecondary)
                .padding(.leading, 4)
            content
        }
        .appFont()
    }
}

struct LabeledStepper: View {
    let label: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    var step: Int = 1

    var body: some View {
        Stepper(value: $value, in: range, step: step) {
            HStack {
                Text(label).foregroundStyle(Theme.textPrimary)
                Spacer()
                Text("\(value)").fontWeight(.bold).foregroundStyle(Theme.emerald)
            }
        }
        .tint(Theme.surface3)
        .fieldStyle()
        .appFont()
    }
}

struct LabeledSlider: View {
    let label: String
    let valueText: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    var step: Double = 1
    var tint: Color = Theme.emerald

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label).foregroundStyle(Theme.textPrimary)
                Spacer()
                Text(valueText).fontWeight(.bold).foregroundStyle(tint)
            }
            Slider(value: $value, in: range, step: step).tint(tint)
        }
        .fieldStyle()
        .appFont()
    }
}

struct Avatar: View {
    let name: String
    var photoData: Data? = nil
    var size: CGFloat = 48
    var tint: Color = Theme.blue

    private var initials: String {
        let parts = name.split(separator: " ")
        let first = parts.first?.prefix(1) ?? ""
        let last = parts.dropFirst().first?.prefix(1) ?? ""
        return (first + last).uppercased()
    }

    var body: some View {
        Group {
            if let data = photoData, let ui = UIImage(data: data) {
                Image(uiImage: ui).resizable().scaledToFill()
            } else {
                Text(initials)
                    .font(.system(size: size * 0.36, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(
                        LinearGradient(colors: [tint, tint.opacity(0.55)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 1))
    }
}
