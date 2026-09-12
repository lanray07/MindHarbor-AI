import Foundation

enum NaturalLanguageSearch {
    static func matches(entry: JournalEntry, query: String, allEntries: [JournalEntry] = []) -> Bool {
        let normalized = query
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return true }

        if let month = monthFromQuery(normalized), matchesMonth(entry, month: month) {
            if normalized.contains("better days") || normalized.contains("better day") {
                return entry.moodRaw >= MoodLevel.good.rawValue
            }
            return true
        }

        if normalized.contains("better days") || normalized.contains("better day") {
            return entry.moodRaw >= MoodLevel.good.rawValue
        }

        if normalized.contains("show my better days in") || normalized.contains("better days in") {
            if let month = monthFromQuery(normalized) {
                return matchesMonth(entry, month: month) && entry.moodRaw >= MoodLevel.good.rawValue
            }
            return entry.moodRaw >= MoodLevel.good.rawValue
        }

        if let keyword = extractedKeyword(from: normalized, allEntries: allEntries) {
            let normalizedKeyword = keyword
            if normalizedKeyword.isEmpty { return true }
            return entry.bodyText.lowercased().contains(normalizedKeyword) ||
                entry.title.lowercased().contains(normalizedKeyword) ||
                entry.tags.contains(where: { sanitize($0).lowercased() == normalizedKeyword }) ||
                (entry.transcript?.lowercased().contains(normalizedKeyword) ?? false)
        }

        if normalized.contains("transcript") {
            return entry.transcript?.lowercased().contains(normalized.replacingOccurrences(of: "transcript", with: "")) ?? false
        }

        return entry.bodyText.lowercased().contains(normalized) || entry.title.lowercased().contains(normalized)
    }

    private static func extractedKeyword(from query: String, allEntries: [JournalEntry]) -> String? {
        let lowered = query.lowercased()

        let patterns = [
            "show entries where i mentioned",
            "show entries where i wrote",
            "show entries about",
            "show my entries about",
            "what have i written about",
            "what have i mentioned",
            "what have i said",
            "what do i write about",
            "what did i mention",
            "what did i write about",
            "entries about",
            "mentioned",
            "where",
            "about",
            "did i write",
            "did i mention"
        ]

        for marker in patterns {
            if let range = lowered.range(of: marker) {
                let candidate = String(lowered[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
                if let keyword = bestKeyword(from: candidate, allEntries: allEntries) {
                    return keyword
                }
            }
        }

        return bestKeyword(from: lowered, allEntries: allEntries)
    }

    private static func bestKeyword(from raw: String, allEntries: [JournalEntry]) -> String? {
        let rawSanitized = sanitize(raw)
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !rawSanitized.isEmpty else { return nil }

        let words = rawSanitized
            .split(separator: " ")
            .map { String($0) }
        let meaningful = words.filter { !stopWords.contains($0) }
        guard !meaningful.isEmpty else { return nil }

        let vocab = extractVocabulary(from: allEntries)
        if meaningful.count == 1 {
            return meaningful[0]
        }

        for width in stride(from: min(2, meaningful.count), through: 1, by: -1) {
            for start in 0...(meaningful.count - width) {
                let phrase = meaningful[start..<start + width].joined(separator: " ")
                if vocab.contains(phrase) {
                    return phrase
                }
            }
        }
        return meaningful.first
    }

    private static func extractVocabulary(from entries: [JournalEntry]) -> Set<String> {
        var terms = Set<String>()
        for entry in entries {
            for tag in entry.tags {
                terms.insert(sanitize(tag).lowercased())
            }
            let words = entry.bodyText
                .lowercased()
                .components(separatedBy: CharacterSet.alphanumerics.inverted)
                .filter { $0.count >= 3 }
                .map(sanitize)
            for word in words where !word.isEmpty {
                terms.insert(word)
            }
        }
        return terms
    }

    private static func sanitize(_ value: String) -> String {
        value
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined(separator: " ")
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func monthFromQuery(_ query: String) -> Int? {
        let normalized = query.lowercased()
        let months = [
            "january": 1, "february": 2, "march": 3, "april": 4, "may": 5, "june": 6,
            "july": 7, "august": 8, "september": 9, "october": 10, "november": 11, "december": 12
        ]
        return months.first(where: { normalized.contains($0.key) })?.value
    }

    private static func matchesMonth(_ entry: JournalEntry, month: Int) -> Bool {
        Calendar.current.component(.month, from: entry.createdAt) == month
    }

    private static let stopWords: Set<String> = [
        "a", "an", "the", "is", "are", "was", "were", "i", "you", "we", "my", "me", "this", "that",
        "what", "when", "where", "how", "did", "have", "has", "have", "had", "has", "please",
        "show", "entries", "entry", "entrys", "recent", "recently", "now", "in", "on", "at", "to", "for",
        "of", "and", "or", "it", "be", "been", "all", "any", "about", "mentioned", "mention", "wrote",
        "write", "written", "say", "said", "saying", "just", "would", "should"
    ]
}
