import Foundation

enum ReflectionStrength {
    case soft
    case moderate
    case strong
}

enum ReflectionTone {
    case welcomeBack
    case insight
    case caution
}

struct ReflectionSnippet {
    static let welcomeBack = "Welcome back."
    static let safeNudge = "Your journal is here whenever you want it."

    static func dailyMoment(entries: [JournalEntry], checkIns: [MoodCheckIn]) -> String {
        if let topTag = PatternEngine.themeBuckets(from: entries).first {
            return "\(topTag.0) has been appearing in your entries this week."
        }
        if checkIns.isEmpty {
            return "You can check in, or write whatever feels most useful."
        }
        let average = checkIns.suffix(7).reduce(0) { $0 + $1.moodRaw } / max(1, min(7, checkIns.count))
        return "Your recent average mood is \(average) out of 5."
    }

    static func insight(entries: [JournalEntry], checkIns: [MoodCheckIn], minimum: Int = 4) -> String {
        if entries.count < minimum && checkIns.count < minimum { return safeNudge }
        if let commonTheme = PatternEngine.themeBuckets(from: entries).first {
            return "\(commonTheme.0) appeared in \(commonTheme.1) entries. Would you like to reflect on it?"
        }
        return "Your patterns are emerging. Keep checking in when useful."
    }

    static func weeklyHarbor(entries: [JournalEntry], checkIns: [MoodCheckIn]) -> String {
        PatternEngine.weeklyHarborSummary(entries: entries, checkIns: checkIns)
    }

    static func monthlyHarbor(entries: [JournalEntry], checkIns: [MoodCheckIn]) -> String {
        PatternEngine.monthlyHarborSummary(entries: entries, checkIns: checkIns)
    }
}
