import SwiftUI
import PhotosUI

struct PlayerEditorView: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) private var dismiss

    let teamId: UUID
    var editing: Player?

    @State private var name = ""
    @State private var position: Position = .midfielder
    @State private var number = 10
    @State private var age = 24
    @State private var heightCm = 180
    @State private var weightKg = 75
    @State private var nationality = ""
    @State private var photoItem: PhotosPickerItem?
    @State private var photoData: Data?

    @State private var appearances = 0
    @State private var goals = 0
    @State private var assists = 0
    @State private var minutes = 0
    @State private var passAccuracy = 80.0
    @State private var distanceKm = 0.0
    @State private var topSpeed = 33.0
    @State private var rating = 7.0

    private var isValid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    photoSection
                    identitySection
                    physicalSection
                    statsSection
                }
                .padding(16)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle(editing == nil ? "New Player" : "Edit Player")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(!isValid).fontWeight(.bold)
                }
            }
            .onAppear(perform: loadIfEditing)
            .onChange(of: photoItem) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        photoData = data
                    }
                }
            }
            .appFont()
        }
    }

    private var photoSection: some View {
        DataPanel {
            VStack(spacing: 12) {
                Avatar(name: name.isEmpty ? "New Player" : name,
                       photoData: photoData, size: 92, tint: position.color)
                PhotosPicker(selection: $photoItem, matching: .images) {
                    Label(photoData == nil ? "Add Photo" : "Change Photo", systemImage: "photo.badge.plus")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.blue)
                }
                if photoData != nil {
                    Button("Remove Photo") { photoData = nil; photoItem = nil }
                        .font(.caption).foregroundStyle(Theme.danger)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var identitySection: some View {
        FormSection(title: "Identity") {
            AppTextField(title: "Full name", text: $name, placeholder: "Player name", icon: "person.fill")
            AppTextField(title: "Nationality", text: $nationality, placeholder: "Country", icon: "flag.fill")
            positionPicker
            LabeledStepper(label: "Shirt number", value: $number, range: 1...99)
        }
    }

    private var positionPicker: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("POSITION")
                .font(.caption2.weight(.bold))
                .foregroundStyle(Theme.textSecondary)
            HStack(spacing: 8) {
                ForEach(Position.allCases) { pos in
                    Button {
                        Haptics.tap()
                        withAnimation(.easeOut(duration: 0.15)) { position = pos }
                    } label: {
                        Text(pos.rawValue)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(position == pos ? Color(hex: "#0A0D12") : Theme.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(position == pos ? pos.color : Theme.surface2)
                            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                    }
                }
            }
        }
        .appFont()
    }

    private var physicalSection: some View {
        FormSection(title: "Physical") {
            LabeledStepper(label: "Age", value: $age, range: 15...45)
            LabeledStepper(label: "Height (cm)", value: $heightCm, range: 150...210)
            LabeledStepper(label: "Weight (kg)", value: $weightKg, range: 50...110)
            LabeledSlider(label: "Top speed", valueText: String(format: "%.1f km/h", topSpeed),
                          value: $topSpeed, range: 28...38, step: 0.1, tint: Theme.blue)
        }
    }

    private var statsSection: some View {
        FormSection(title: "Current Season · \(SeedData.curSeason)") {
            LabeledStepper(label: "Appearances", value: $appearances, range: 0...60)
            LabeledStepper(label: "Goals", value: $goals, range: 0...80)
            LabeledStepper(label: "Assists", value: $assists, range: 0...60)
            LabeledStepper(label: "Minutes", value: $minutes, range: 0...5400, step: 90)
            LabeledSlider(label: "Pass accuracy", valueText: String(format: "%.0f%%", passAccuracy),
                          value: $passAccuracy, range: 50...99, step: 1)
            LabeledSlider(label: "Distance", valueText: String(format: "%.0f km", distanceKm),
                          value: $distanceKm, range: 0...340, step: 1)
            LabeledSlider(label: "Rating", valueText: String(format: "%.2f", rating),
                          value: $rating, range: 5...10, step: 0.05, tint: Theme.gold)
        }
    }

    private func loadIfEditing() {
        guard let p = editing else { return }
        name = p.name; position = p.position; number = p.number
        age = p.age; heightCm = p.heightCm; weightKg = p.weightKg
        nationality = p.nationality; photoData = p.photoData
        let s = p.current
        appearances = s.appearances; goals = s.goals; assists = s.assists
        minutes = s.minutes; passAccuracy = s.passAccuracy
        distanceKm = s.distanceKm; topSpeed = s.topSpeedKmh; rating = s.rating
    }

    private func save() {
        let stat = PlayerSeasonStat(
            season: SeedData.curSeason, appearances: appearances, goals: goals,
            assists: assists, minutes: minutes, shots: max(goals, goals * 4),
            tackles: editing?.current.tackles ?? 20,
            interceptions: editing?.current.interceptions ?? 15,
            sprints: editing?.current.sprints ?? 200,
            yellowCards: editing?.current.yellowCards ?? 0,
            redCards: editing?.current.redCards ?? 0,
            passAccuracy: passAccuracy, distanceKm: distanceKm,
            topSpeedKmh: topSpeed, rating: rating)

        if var p = editing {
            p.name = name; p.position = position; p.number = number
            p.age = age; p.heightCm = heightCm; p.weightKg = weightKg
            p.nationality = nationality; p.photoData = photoData
            var seasons = p.seasons.filter { $0.season != SeedData.curSeason }
            seasons.append(stat)
            p.seasons = seasons
            store.updatePlayer(p)
        } else {
            let p = Player(teamId: teamId, name: name, position: position, number: number,
                           age: age, heightCm: heightCm, weightKg: weightKg,
                           nationality: nationality.isEmpty ? "—" : nationality,
                           photoData: photoData, seasons: [stat])
            store.addPlayer(p)
        }
        Haptics.success(); dismiss()
    }
}
