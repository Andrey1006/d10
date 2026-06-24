import SwiftUI

struct TeamEditorView: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) private var dismiss

    var editing: Team?

    @State private var name = ""
    @State private var shortName = ""
    @State private var city = ""
    @State private var founded = 1950
    @State private var colorHex = "#1FA15B"
    @State private var crest = "shield.fill"

    private let palette = ["#1FA15B", "#27B5FF", "#F0B84A", "#FF6A4D", "#9B6BFF", "#FF8FB1"]
    private let crests = ["shield.fill", "drop.fill", "crown.fill", "flame.fill",
                          "bolt.fill", "star.fill", "hexagon.fill", "pawprint.fill"]

    private var isValid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    preview
                    identitySection
                    crestSection
                    colorSection
                }
                .padding(16)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle(editing == nil ? "New Team" : "Edit Team")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(!isValid).fontWeight(.bold)
                }
            }
            .onAppear(perform: loadIfEditing)
            .appFont()
        }
    }

    private var preview: some View {
        DataPanel {
            HStack(spacing: 14) {
                Image(systemName: crest)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Color(hex: colorHex))
                    .frame(width: 58, height: 58)
                    .background(Color(hex: colorHex).opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                VStack(alignment: .leading, spacing: 3) {
                    Text(name.isEmpty ? "Team Name" : name)
                        .font(.headline)
                        .foregroundStyle(name.isEmpty ? Theme.textSecondary : Theme.textPrimary)
                    Text(city.isEmpty ? "City" : city)
                        .font(.caption).foregroundStyle(Theme.textSecondary)
                }
                Spacer()
            }
        }
    }

    private var identitySection: some View {
        FormSection(title: "Identity") {
            AppTextField(title: "Team name", text: $name, placeholder: "e.g. Northgate United", icon: "shield.fill")
            AppTextField(title: "Short name", text: $shortName, placeholder: "e.g. NGU",
                         icon: "textformat.abc", autocapitalization: .characters)
            AppTextField(title: "City", text: $city, placeholder: "Home city", icon: "mappin.and.ellipse")
            LabeledStepper(label: "Founded", value: $founded, range: 1850...2026)
        }
    }

    private var crestSection: some View {
        FormSection(title: "Crest") {
            LazyVGrid(columns: Array(repeating: GridItem(spacing: 12), count: 4), spacing: 12) {
                ForEach(crests, id: \.self) { sym in
                    Image(systemName: sym)
                        .font(.title2)
                        .foregroundStyle(crest == sym ? Color(hex: colorHex) : Theme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(crest == sym ? Color(hex: colorHex).opacity(0.18) : Theme.surface2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(crest == sym ? Color(hex: colorHex) : Theme.panelStroke,
                                        lineWidth: crest == sym ? 1.5 : 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .onTapGesture { Haptics.tap(); crest = sym }
                }
            }
        }
    }

    private var colorSection: some View {
        FormSection(title: "Color") {
            HStack(spacing: 14) {
                ForEach(palette, id: \.self) { hex in
                    Circle()
                        .fill(Color(hex: hex))
                        .frame(width: 38, height: 38)
                        .overlay(Circle().stroke(.white, lineWidth: colorHex == hex ? 3 : 0))
                        .onTapGesture { Haptics.tap(); colorHex = hex }
                }
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .fieldStyle()
        }
    }

    private func loadIfEditing() {
        guard let t = editing else { return }
        name = t.name; shortName = t.shortName; city = t.city
        founded = t.founded; colorHex = t.colorHex; crest = t.crest
    }

    private func save() {
        let trimmedShort = shortName.isEmpty ? String(name.prefix(3)).uppercased() : shortName
        if var t = editing {
            t.name = name; t.shortName = trimmedShort; t.city = city
            t.founded = founded; t.colorHex = colorHex; t.crest = crest
            store.updateTeam(t)
        } else {
            store.addTeam(Team(name: name, shortName: trimmedShort, city: city,
                               founded: founded, colorHex: colorHex, crest: crest))
        }
        Haptics.success(); dismiss()
    }
}
