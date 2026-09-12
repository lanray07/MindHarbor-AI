import Foundation
import SwiftData

enum ScreenshotFixtures {
    static let isEnabled = CommandLine.arguments.contains("--screenshot-mode")

    static var requestedTab: Int {
        guard let argument = CommandLine.arguments.first(where: { $0.hasPrefix("--screenshot-tab=") }),
              let value = Int(argument.split(separator: "=").last ?? "0") else {
            return 0
        }
        return min(max(value, 0), 4)
    }

    static func seedIfNeeded(in context: ModelContext) {
        guard isEnabled else { return }
        let descriptor = FetchDescriptor<JournalEntry>()
        guard (try? context.fetchCount(descriptor)) == 0 else { return }

        let calendar = Calendar.current
        let samples: [(String, String, Int, MoodLevel, [String])] = [
            ("A calmer start", "I took ten quiet minutes before opening my inbox. The slower start helped me feel grounded and clear.", -1, .good, ["calm", "morning"]),
            ("What helped today", "A walk by the water and an honest conversation made the afternoon feel lighter.", -3, .veryGood, ["outdoors", "connection"]),
            ("Making space", "Work felt busy, but writing down the next small step stopped everything from feeling urgent at once.", -5, .okay, ["work", "reflection"]),
            ("Evening reflection", "I am learning that rest is part of progress, not something I have to earn.", -8, .good, ["rest", "growth"])
        ]

        for sample in samples {
            context.insert(JournalEntry(
                title: sample.0,
                bodyText: sample.1,
                createdAt: calendar.date(byAdding: .day, value: sample.2, to: .now) ?? .now,
                kind: .written,
                mood: sample.3,
                includeInAI: true,
                isFavorite: sample.2 == -3,
                tags: sample.4
            ))
        }

        for day in 0..<10 {
            context.insert(MoodCheckIn(
                recordedAt: calendar.date(byAdding: .day, value: -day, to: .now) ?? .now,
                mood: day % 4 == 0 ? .okay : .good,
                energy: day % 3 == 0 ? 3 : 4,
                stress: day % 4 == 0 ? 3 : 2,
                sleepQuality: day % 3 == 0 ? 3 : 4,
                focus: 4,
                social: day % 2 == 0 ? 4 : 3,
                tags: day % 2 == 0 ? ["calm", "rest"] : ["work", "connection"]
            ))
        }

        try? context.save()
    }
}
