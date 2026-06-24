import Foundation

enum SeedData {

    static let prevSeason = "2024/25"
    static let curSeason  = "2025/26"

    static func populate(_ store: DataStore) {
        let ngu = Team(name: "Northgate United", shortName: "NGU", city: "Northgate",
                       founded: 1899, colorHex: "#1FA15B", crest: "shield.fill")
        let riv = Team(name: "Riverside FC", shortName: "RIV", city: "Riverside",
                       founded: 1912, colorHex: "#27B5FF", crest: "drop.fill")
        let cre = Team(name: "Crestfall City", shortName: "CRE", city: "Crestfall",
                       founded: 1905, colorHex: "#F0B84A", crest: "crown.fill")
        let val = Team(name: "Valebridge Athletic", shortName: "VAL", city: "Valebridge",
                       founded: 1921, colorHex: "#FF6A4D", crest: "flame.fill")
        store.teams = [ngu, riv, cre, val]

        store.tournaments = [
            Tournament(name: "Premier Division", season: curSeason),
            Tournament(name: "National Cup", season: curSeason),
            Tournament(name: "Premier Division", season: prevSeason),
        ]

        store.players = []
        store.players += squad(for: ngu.id, names: nguSquad)
        store.players += squad(for: riv.id, names: rivSquad)
        store.players += squad(for: cre.id, names: creSquad)
        store.players += squad(for: val.id, names: valSquad)

        store.matches = buildMatches(ngu: ngu, riv: riv, cre: cre, val: val)
        store.activeSeason = curSeason
    }

    private typealias PlayerSpec = (
        name: String, pos: Position, num: Int, age: Int, h: Int, w: Int, nat: String,
        apps: Int, g: Int, a: Int, min: Int, shots: Int, tackles: Int, intc: Int,
        sprints: Int, yc: Int, rc: Int, pass: Double, dist: Double, speed: Double, rating: Double
    )

    private static func squad(for teamId: UUID, names: [PlayerSpec]) -> [Player] {
        names.map { spec in
            let cur = PlayerSeasonStat(
                season: curSeason, appearances: spec.apps, goals: spec.g, assists: spec.a,
                minutes: spec.min, shots: spec.shots, tackles: spec.tackles,
                interceptions: spec.intc, sprints: spec.sprints, yellowCards: spec.yc,
                redCards: spec.rc, passAccuracy: spec.pass, distanceKm: spec.dist,
                topSpeedKmh: spec.speed, rating: spec.rating)
            let prev = PlayerSeasonStat(
                season: prevSeason,
                appearances: Int(Double(spec.apps) * 0.92),
                goals: Int(Double(spec.g) * 0.78),
                assists: Int(Double(spec.a) * 0.8),
                minutes: Int(Double(spec.min) * 0.9),
                shots: Int(Double(spec.shots) * 0.82),
                tackles: Int(Double(spec.tackles) * 0.88),
                interceptions: Int(Double(spec.intc) * 0.9),
                sprints: Int(Double(spec.sprints) * 0.85),
                yellowCards: max(0, spec.yc - 1),
                redCards: spec.rc,
                passAccuracy: max(50, spec.pass - 3.2),
                distanceKm: spec.dist * 0.94,
                topSpeedKmh: spec.speed - 0.6,
                rating: max(5.5, spec.rating - 0.4))
            return Player(teamId: teamId, name: spec.name, position: spec.pos,
                          number: spec.num, age: spec.age, heightCm: spec.h,
                          weightKg: spec.w, nationality: spec.nat,
                          photoData: nil, seasons: [prev, cur])
        }
    }

    private static let nguSquad: [PlayerSpec] = [
        ("Marco Vitale",   .goalkeeper, 1,  29, 191, 84, "Italy",     28, 0,  0, 2520, 0,  6,  9,  40, 2, 0, 84.0, 132.4, 31.1, 7.4),
        ("Diego Alvarez",  .defender,   4,  27, 186, 80, "Spain",     27, 2,  3, 2400, 14, 71, 58, 188, 6, 1, 88.5, 281.2, 33.4, 7.6),
        ("Tom Hartley",    .defender,   5,  31, 189, 83, "England",   26, 1,  1, 2310, 9,  64, 61, 162, 5, 0, 86.1, 270.5, 32.8, 7.3),
        ("Luca Romano",    .defender,   3,  24, 180, 74, "Italy",     25, 1,  6, 2200, 11, 55, 44, 240, 4, 0, 85.8, 298.1, 35.2, 7.5),
        ("Kwame Mensah",   .midfielder, 6,  26, 182, 77, "Ghana",     28, 4, 7, 2480, 33, 78, 49, 268, 7, 0, 89.7, 312.6, 34.0, 8.0),
        ("Owen Bright",    .midfielder, 8,  23, 178, 72, "England",   27, 7,  9, 2360, 51, 44, 31, 296, 3, 0, 90.4, 324.9, 34.6, 8.3),
        ("Felix Brandt",   .midfielder, 10, 28, 176, 70, "Germany",   26, 9, 12, 2280, 64, 30, 22, 274, 4, 0, 88.2, 305.3, 33.9, 8.5),
        ("Andre Sousa",    .forward,    7,  25, 179, 73, "Portugal",  27, 14, 8, 2300, 88, 18, 12, 318, 5, 0, 81.6, 296.7, 35.8, 8.6),
        ("Samuel Okafor",  .forward,    9,  24, 188, 82, "Nigeria",   28, 21, 5, 2410, 102, 9, 6, 305, 4, 1, 79.3, 288.4, 36.4, 8.9),
    ]

    private static let rivSquad: [PlayerSpec] = [
        ("Niklas Berg",    .goalkeeper, 1,  30, 193, 86, "Sweden",    27, 0,  0, 2430, 0,  4,  7,  36, 1, 0, 82.7, 128.9, 30.6, 7.5),
        ("Pavel Novak",    .defender,   2,  28, 184, 79, "Czechia",   26, 1,  2, 2340, 8,  68, 55, 176, 6, 0, 87.0, 276.3, 33.0, 7.2),
        ("Hassan Karimi",  .defender,   6,  26, 187, 81, "Iran",      27, 2,  1, 2400, 12, 73, 63, 158, 7, 1, 85.4, 268.0, 32.5, 7.4),
        ("Leon Carter",    .defender,   3,  22, 181, 75, "England",   24, 0,  4, 2120, 6,  58, 47, 233, 3, 0, 86.9, 291.7, 34.8, 7.3),
        ("Mateo Silva",    .midfielder, 8,  25, 177, 71, "Brazil",    28, 6, 10, 2470, 47, 52, 35, 281, 5, 0, 91.2, 318.4, 34.2, 8.2),
        ("Eric Lindqvist", .midfielder, 4,  29, 183, 78, "Sweden",    26, 3,  5, 2350, 29, 80, 52, 254, 8, 0, 88.9, 309.6, 33.1, 7.8),
        ("Yuki Tanaka",    .midfielder, 11, 24, 173, 68, "Japan",     27, 8, 11, 2280, 58, 36, 26, 312, 2, 0, 89.5, 327.2, 34.9, 8.4),
        ("Rafael Moreno",  .forward,    10, 27, 180, 74, "Spain",     27, 16, 9, 2330, 92, 16, 11, 299, 5, 0, 82.1, 294.8, 35.5, 8.7),
        ("Kofi Adjei",     .forward,    9,  23, 185, 80, "Ghana",     26, 18, 4, 2260, 97, 11, 7, 310, 4, 1, 78.8, 285.1, 36.7, 8.6),
    ]

    private static let creSquad: [PlayerSpec] = [
        ("Goran Petrov",   .goalkeeper, 1,  32, 190, 85, "Serbia",    27, 0,  0, 2430, 0,  5,  8,  34, 2, 0, 83.5, 130.2, 30.9, 7.3),
        ("Ivan Horvat",    .defender,   5,  29, 188, 82, "Croatia",   26, 3,  2, 2380, 13, 70, 60, 167, 6, 0, 86.7, 273.9, 32.7, 7.5),
        ("Bruno Lima",     .defender,   4,  27, 183, 78, "Brazil",    27, 1,  3, 2400, 9,  66, 57, 198, 5, 1, 87.4, 286.5, 34.1, 7.4),
        ("Max Schneider",  .defender,   3,  25, 179, 73, "Germany",   26, 0,  5, 2300, 7,  61, 49, 245, 4, 0, 88.0, 295.3, 35.0, 7.6),
        ("Aaron Webb",     .midfielder, 6,  28, 181, 76, "England",   28, 5,  6, 2490, 38, 75, 47, 263, 7, 0, 90.1, 314.7, 33.6, 8.1),
        ("Carlos Mendez",  .midfielder, 10, 26, 175, 70, "Argentina", 27, 11, 13, 2350, 69, 33, 24, 288, 4, 0, 89.8, 320.1, 34.4, 8.7),
        ("Nico Fischer",   .midfielder, 8,  24, 178, 72, "Austria",   26, 6, 8, 2270, 49, 41, 30, 277, 3, 0, 88.6, 308.9, 34.7, 8.0),
        ("Theo Laurent",   .forward,    7,  25, 182, 75, "France",    27, 13, 10, 2320, 85, 17, 13, 301, 5, 0, 83.0, 297.4, 35.6, 8.5),
        ("Dani Costa",     .forward,    9,  26, 186, 81, "Portugal",  28, 19, 6, 2400, 99, 12, 8, 308, 6, 1, 79.9, 289.7, 36.2, 8.8),
    ]

    private static let valSquad: [PlayerSpec] = [
        ("Erik Solberg",   .goalkeeper, 1,  28, 192, 85, "Norway",    27, 0,  0, 2430, 0,  6,  9,  38, 1, 0, 81.9, 127.6, 30.4, 7.1),
        ("Jan Kowalski",   .defender,   2,  30, 185, 80, "Poland",    26, 1,  1, 2350, 10, 69, 59, 172, 7, 0, 85.9, 271.8, 32.4, 7.2),
        ("Sergio Rossi",   .defender,   4,  27, 187, 82, "Italy",     27, 2,  2, 2400, 11, 72, 62, 161, 6, 1, 86.3, 267.5, 32.9, 7.3),
        ("Liam Doyle",     .defender,   3,  23, 180, 74, "Ireland",   25, 0,  3, 2200, 6,  57, 46, 228, 4, 0, 85.7, 288.9, 34.6, 7.0),
        ("Ahmed Saleh",    .midfielder, 6,  26, 182, 77, "Egypt",     28, 4,  5, 2470, 35, 76, 50, 259, 8, 0, 88.4, 311.2, 33.3, 7.7),
        ("Viktor Ilic",    .midfielder, 8,  25, 176, 71, "Serbia",    27, 7,  8, 2330, 52, 38, 28, 283, 5, 0, 89.0, 316.8, 34.1, 7.9),
        ("Ben Walker",     .midfielder, 10, 24, 177, 72, "England",   26, 9, 10, 2280, 61, 34, 25, 290, 3, 0, 88.7, 313.4, 34.5, 8.1),
        ("Luis Fernandez", .forward,    7,  27, 181, 75, "Mexico",    27, 12, 7, 2310, 81, 19, 14, 296, 5, 0, 82.4, 293.1, 35.3, 8.2),
        ("Stefan Vasic",   .forward,    9,  25, 184, 79, "Serbia",    28, 15, 5, 2390, 94, 13, 9, 304, 6, 1, 79.5, 287.2, 36.0, 8.4),
    ]

    private static func buildMatches(ngu: Team, riv: Team, cre: Team, val: Team) -> [Match] {
        let cal = Calendar.current
        let now = Date()
        func daysAgo(_ d: Int) -> Date { cal.date(byAdding: .day, value: -d, to: now)! }
        func daysAhead(_ d: Int) -> Date { cal.date(byAdding: .day, value: d, to: now)! }

        var matches: [Match] = []

        func finished(_ home: Team, _ away: Team, _ hs: Int, _ as_: Int,
                      _ tourn: String, _ day: Int, events: [MatchEvent] = [], note: String = "") {
            matches.append(Match(homeTeamId: home.id, awayTeamId: away.id, date: daysAgo(day),
                                 tournament: tourn, season: curSeason, homeScore: hs,
                                 awayScore: as_, isFinished: true, events: events, note: note))
        }

        finished(ngu, riv, 2, 1, "Premier Division", 42, events: [
            MatchEvent(minute: 12, type: .goal, teamId: ngu.id, playerName: "Samuel Okafor"),
            MatchEvent(minute: 34, type: .goal, teamId: riv.id, playerName: "Rafael Moreno"),
            MatchEvent(minute: 78, type: .goal, teamId: ngu.id, playerName: "Andre Sousa"),
            MatchEvent(minute: 81, type: .yellow, teamId: riv.id, playerName: "Hassan Karimi"),
        ], note: "Compact mid-block neutralised Riverside's wide rotations; press triggered on the GK's first touch.")

        finished(cre, val, 3, 0, "Premier Division", 39, events: [
            MatchEvent(minute: 23, type: .goal, teamId: cre.id, playerName: "Dani Costa"),
            MatchEvent(minute: 55, type: .goal, teamId: cre.id, playerName: "Carlos Mendez"),
            MatchEvent(minute: 70, type: .penalty, teamId: cre.id, playerName: "Theo Laurent"),
        ], note: "Half-space combinations between Mendez and Costa repeatedly broke the back line.")

        finished(riv, cre, 1, 1, "Premier Division", 32, events: [
            MatchEvent(minute: 41, type: .goal, teamId: riv.id, playerName: "Kofi Adjei"),
            MatchEvent(minute: 67, type: .goal, teamId: cre.id, playerName: "Dani Costa"),
            MatchEvent(minute: 88, type: .red, teamId: riv.id, playerName: "Pavel Novak"),
        ])

        finished(val, ngu, 0, 2, "Premier Division", 28, events: [
            MatchEvent(minute: 19, type: .goal, teamId: ngu.id, playerName: "Felix Brandt"),
            MatchEvent(minute: 73, type: .goal, teamId: ngu.id, playerName: "Samuel Okafor"),
        ], note: "Transition speed of Sousa & Okafor punished Valebridge's high line twice.")

        finished(ngu, cre, 1, 1, "National Cup", 21, events: [
            MatchEvent(minute: 50, type: .goal, teamId: cre.id, playerName: "Dani Costa"),
            MatchEvent(minute: 84, type: .goal, teamId: ngu.id, playerName: "Owen Bright"),
        ])

        finished(riv, val, 2, 2, "Premier Division", 17, events: [
            MatchEvent(minute: 9,  type: .goal, teamId: val.id, playerName: "Stefan Vasic"),
            MatchEvent(minute: 38, type: .goal, teamId: riv.id, playerName: "Yuki Tanaka"),
            MatchEvent(minute: 61, type: .goal, teamId: riv.id, playerName: "Kofi Adjei"),
            MatchEvent(minute: 90, type: .goal, teamId: val.id, playerName: "Luis Fernandez"),
        ])

        finished(cre, ngu, 0, 1, "Premier Division", 11, events: [
            MatchEvent(minute: 64, type: .goal, teamId: ngu.id, playerName: "Andre Sousa"),
            MatchEvent(minute: 71, type: .save, teamId: ngu.id, playerName: "Marco Vitale"),
        ], note: "Vitale's 71' save preserved the away win; xG was nearly even.")

        finished(val, riv, 1, 3, "Premier Division", 5, events: [
            MatchEvent(minute: 14, type: .goal, teamId: riv.id, playerName: "Rafael Moreno"),
            MatchEvent(minute: 29, type: .goal, teamId: riv.id, playerName: "Mateo Silva"),
            MatchEvent(minute: 52, type: .goal, teamId: val.id, playerName: "Ben Walker"),
            MatchEvent(minute: 80, type: .goal, teamId: riv.id, playerName: "Kofi Adjei"),
        ])

        matches.append(Match(homeTeamId: ngu.id, awayTeamId: cre.id, date: daysAhead(3),
                             tournament: "Premier Division", season: curSeason,
                             homeScore: 0, awayScore: 0, isFinished: false, events: []))
        matches.append(Match(homeTeamId: riv.id, awayTeamId: ngu.id, date: daysAhead(7),
                             tournament: "National Cup", season: curSeason,
                             homeScore: 0, awayScore: 0, isFinished: false, events: []))
        matches.append(Match(homeTeamId: cre.id, awayTeamId: val.id, date: daysAhead(10),
                             tournament: "Premier Division", season: curSeason,
                             homeScore: 0, awayScore: 0, isFinished: false, events: []))

        return matches
    }
}
