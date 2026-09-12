import Foundation

struct PatternEngine {
    struct PatternResult: Identifiable {
        let id = UUID()
        let title: String
        let detail: String
        let sampleCount: Int
        let confidence: Confidence
    }

    enum Confidence: String {
        case none = "Not enough data yet"
        case emerging = "Emerging"
        case consistent = "Consistent"
    }

    static func analyze(entries: [JournalEntry], checkIns: [MoodCheckIn]) -> [PatternResult] {
        let hasEnoughData = checkIns.count >= 4 || entries.count >= 4
        guard hasEnoughData else { return [] }

        var results: [PatternResult] = []

        let recurringTags = Dictionary(grouping: entries.flatMap(\.tags), by: { $0 })
            .filter { $0.value.count >= 3 }

        for (tag, values) in recurringTags {
            let confidence: Confidence = values.count >= 8 ? .consistent : .emerging
            results.append(
                PatternResult(
                    title: "Recurring theme",
                    detail: "\(tag) appeared in \(values.count) entries.",
                    sampleCount: values.count,
                    confidence: confidence
                )
            )
        }

        let moodTagSignals = moodByTagCorrelation(from: entries)
        for signal in moodTagSignals where signal.sampleCount >= 3 {
            results.append(
                PatternResult(
                    title: "Mood and topics",
                    detail: "When entries include \"\(signal.tag)\", mood tended to be around \(String(format: "%.1f", signal.averageMood)) (\(signal.sampleCount) samples).",
                    sampleCount: signal.sampleCount,
                    confidence: signal.sampleCount >= 8 ? .consistent : .emerging
                )
            )
        }

        let recentCheckIns = checkIns.sorted(by: { $0.recordedAt > $1.recordedAt }).prefix(14)
        if !recentCheckIns.isEmpty {
            let avg = recentCheckIns.reduce(0) { $0 + $1.moodRaw } / max(1, recentCheckIns.count)
            let trend = trendDirection(for: recentCheckIns.map(\.moodRaw))
            results.append(
                PatternResult(
                    title: "Mood trend",
                    detail: "Recent average mood is \(avg) on a 1–5 scale. Overall trend: \(trend).",
                    sampleCount: recentCheckIns.count,
                    confidence: recentCheckIns.count >= 8 ? .consistent : .emerging
                )
            )
        }

        let weekdayMood = weekdayAverages(from: checkIns)
        if let top = weekdayMood.max(by: { $0.value < $1.value }) {
            results.append(
                PatternResult(
                    title: "Mood by weekday",
                    detail: "You tended to report higher moods on \(top.key).",
                        sampleCount: top.value.valueSample,
                    confidence: .emerging
                )
            )
        }

        if entries.count >= 5 {
            let keywordCounts = recurringKeywords(from: entries)
            for (word, count) in keywordCounts where count >= 4 {
                results.append(
                    PatternResult(
                        title: "Recurring language",
                        detail: "You used \"\(word)\" frequently (\(count) times).",
                        sampleCount: count,
                        confidence: count >= 10 ? .consistent : .emerging
                    )
                )
            }
        }

        return results
            .sorted {
                if $0.confidence == $1.confidence { return $0.sampleCount > $1.sampleCount }
                let leftRank: Int
                let rightRank: Int
                switch $0.confidence {
                case .consistent: leftRank = 2
                case .emerging: leftRank = 1
                case .none: leftRank = 0
                }
                switch $1.confidence {
                case .consistent: rightRank = 2
                case .emerging: rightRank = 1
                case .none: rightRank = 0
                }
                if leftRank == rightRank { return $0.sampleCount > $1.sampleCount }
                return leftRank > rightRank
            }
    }

    static func themeBuckets(from entries: [JournalEntry], maxCount: Int = 10) -> [(String, Int)] {
        Dictionary(grouping: entries.flatMap(\.tags), by: { $0 })
            .mapValues(\.count)
            .sorted { $0.value > $1.value }
            .prefix(maxCount)
            .map { ($0.key, $0.value) }
    }

    static func weeklyHarborSummary(entries: [JournalEntry], checkIns: [MoodCheckIn]) -> String {
        let checkInText = checkIns.isEmpty ? "No check-ins yet." : "\(checkIns.count) check-ins logged."
        let entryText = "\(entries.count) journal entries logged."
        let topTheme = themeBuckets(from: entries, maxCount: 1).first
        let betterDayHint = topTheme.map { "\($0.0) often appears on entries with stronger moods." } ?? "No clear mood-linked activity pattern yet."
        return "\(entryText) \(checkInText) \(topTheme != nil ? "A common theme is \(topTheme!.0)." : "") \(betterDayHint)"
    }

    static func monthlyHarborSummary(entries: [JournalEntry], checkIns: [MoodCheckIn]) -> String {
        guard !entries.isEmpty || !checkIns.isEmpty else {
            return "Not enough information yet. Keep checking in when it feels useful."
        }
        let now = Date()
        let calendar = Calendar.current
        let previousMonthDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now

        let safeEntries = entries.filter { calendar.isDate($0.createdAt, equalTo: now, toGranularity: .month) }
        let previousMonthEntries = entries.filter { calendar.isDate($0.createdAt, equalTo: previousMonthDate, toGranularity: .month) }

        let safeCheckIns = checkIns.filter { calendar.isDate($0.recordedAt, equalTo: now, toGranularity: .month) }
        let previousCheckIns = checkIns.filter { calendar.isDate($0.recordedAt, equalTo: previousMonthDate, toGranularity: .month) }

        let topThemes = themeBuckets(from: safeEntries, maxCount: 4)
            .map { "\($0.0) (\($0.1))" }
            .joined(separator: ", ")
        let moodStatement = compareMonthMoments(current: safeCheckIns, label: "Mood")
        let moodTrend = compareMonthWithPrevious(
            currentMonth: safeCheckIns,
            previousMonth: previousCheckIns,
            label: "mood"
        )
        let entriesStatement = "This month has \(safeEntries.count) entries. The previous month had \(previousEntriesCount(previousEntries: previousMonthEntries)) entries."
        let stressors = stressSignal(from: safeCheckIns)
        let supporters = supportiveActivities(from: safeEntries)
        let changes = significantChanges(
            currentCount: safeEntries.count,
            currentMood: averageMood(safeCheckIns),
            previousMood: averageMood(previousCheckIns)
        )
        let highlights = topThemes.isEmpty ? "Patterns are still forming." : "Recurring themes: \(topThemes)."

        return "\(entriesStatement) \(moodStatement) \(moodTrend) \(changes) \(highlights) \(stressors) \(supporters)"
    }

    private static func compareMonthMoments(current: [MoodCheckIn], label: String) -> String {
        guard current.count >= 4 else { return "\(label) has limited new data this month." }
        let splitPoint = max(1, current.count / 2)
        let first = Array(current.prefix(splitPoint))
        let last = Array(current.suffix(current.count - splitPoint))
        guard !last.isEmpty else { return "\(label) remains mostly stable." }
        let firstAvg = first.reduce(0) { $0 + $1.moodRaw } / max(1, first.count)
        let lastAvg = last.reduce(0) { $0 + $1.moodRaw } / max(1, last.count)

        if lastAvg > firstAvg {
            return "\(label) appeared higher in the more recent check-ins."
        }
        if lastAvg < firstAvg {
            return "\(label) has been slightly lower than earlier in the window."
        }
        return "\(label) has stayed mostly steady."
    }

    private static func recurringKeywords(from entries: [JournalEntry]) -> [String: Int] {
        let words = entries.flatMap { entry in
            entry.bodyText
                .lowercased()
                .components(separatedBy: CharacterSet.alphanumerics.inverted)
                .filter { $0.count >= 5 }
        }
        return Dictionary(grouping: words, by: { $0 }).mapValues(\.count)
    }

    private static func weekdayAverages(from checkIns: [MoodCheckIn]) -> [String: (value: Double, valueSample: Int)] {
        let format = DateFormatter()
        format.dateFormat = "EEEE"
        let grouped = Dictionary(grouping: checkIns) { format.string(from: $0.recordedAt) }
        return grouped.compactMapValues { bucket in
            guard !bucket.isEmpty else { return nil }
            let sum = bucket.reduce(0) { $0 + $1.moodRaw }
            return (Double(sum) / Double(bucket.count), bucket.count)
        }
    }

    private static func trendDirection(for values: [Int]) -> String {
        guard values.count >= 4 else { return "insufficient movement yet" }
        let half = max(1, values.count / 2)
        let firstHalf = Array(values.prefix(half))
        let lastHalf = Array(values.suffix(half))
        let firstAvg = firstHalf.reduce(0, +) / max(1, firstHalf.count)
        let lastAvg = lastHalf.reduce(0, +) / max(1, lastHalf.count)
        if lastAvg > firstAvg + 1 { return "improving" }
        if lastAvg < firstAvg - 1 { return "declining" }
        return "stable"
    }

    private static func averageMood(_ checkIns: [MoodCheckIn]) -> Double? {
        guard !checkIns.isEmpty else { return nil }
        return Double(checkIns.reduce(0) { $0 + $1.moodRaw }) / Double(checkIns.count)
    }

    private static func previousEntriesCount(previousEntries: [JournalEntry]) -> Int {
        return previousEntries.count
    }

    private static func compareMonthWithPrevious(
        currentMonth: [MoodCheckIn],
        previousMonth: [MoodCheckIn],
        label: String
    ) -> String {
        guard let current = averageMood(currentMonth), currentMonth.count >= 4 else {
            return "No reliable current-month trend comparison yet."
        }
        guard let previous = averageMood(previousMonth), !previousMonth.isEmpty else {
            return "No reliable previous-month comparison yet."
        }
        if current > previous + 0.25 {
            return "\(label.capitalized) appears slightly higher than last month."
        }
        if current < previous - 0.25 {
            return "\(label.capitalized) appears slightly lower than last month."
        }
        return "\(label.capitalized) has stayed much the same as last month."
    }

    private static func significantChanges(currentCount: Int, currentMood: Double?, previousMood: Double?) -> String {
        guard let currentMood else { return "No change-based mood summary is available yet." }
        let direction = if let previousMood {
            currentMood > previousMood ? "up" : currentMood < previousMood ? "down" : "steady"
        } else {
            "steady"
        }
        return "You logged \(currentCount) entries in the current month window and your mood trend is \(direction)."
    }

    private static func stressSignal(from checkIns: [MoodCheckIn]) -> String {
        let highStressTags = checkIns.filter { $0.stress >= 4 }.flatMap { $0.tags }
        let grouped = Dictionary(grouping: highStressTags, by: { $0.lowercased() })
            .sorted { $0.value.count > $1.value.count }
            .prefix(3)
        guard !grouped.isEmpty else { return "No strong recurring stress signals this month." }
        return "Common stress themes: \(grouped.map { "\($0.0) (\($0.1.count))" }.joined(separator: ", "))."
    }

    private static func supportiveActivities(from entries: [JournalEntry]) -> String {
        let positiveTags = entries.filter { $0.moodRaw >= MoodLevel.good.rawValue }.flatMap { $0.tags }
        let grouped = Dictionary(grouping: positiveTags, by: { $0.lowercased() })
            .sorted { $0.value.count > $1.value.count }
            .prefix(3)
        if grouped.isEmpty { return "No activity pattern with stronger moods yet." }
        return "Supportive activities: \(grouped.map { "\($0.0) (\($0.1.count))" }.joined(separator: ", "))."
    }

    private static func moodByTagCorrelation(from entries: [JournalEntry]) -> [MoodTagSignal] {
        let grouped = Dictionary(grouping: entries.flatMap { entry in
            entry.tags.map { ($0, entry.moodRaw) }
        }, by: { $0.0 })

        return grouped.compactMap { key, values in
            guard values.count >= 2 else { return nil }
            let avg = Double(values.reduce(0) { $0 + $1.1 }) / Double(values.count)
            return MoodTagSignal(tag: key, averageMood: avg, sampleCount: values.count)
        }
    }

    private struct MoodTagSignal {
        let tag: String
        let averageMood: Double
        let sampleCount: Int
    }
}
