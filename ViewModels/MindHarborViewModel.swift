import Foundation
import SwiftData

@MainActor
final class MindHarborViewModel: ObservableObject {
    func safetyPrompt(for text: String) -> String {
        if SafetyEngine.detectCrisis(text: text) {
            return SafetyEngine.safetyMessage(for: text, regionCode: Locale.current.regionCode)
        }
        return "Would you like a gentle prompt?"
    }

    func weeklySummary(checkIns: [MoodCheckIn], entries: [JournalEntry]) -> String {
        PatternEngine.weeklyHarborSummary(entries: entries, checkIns: checkIns)
    }

    func monthlySummary(checkIns: [MoodCheckIn], entries: [JournalEntry]) -> String {
        PatternEngine.monthlyHarborSummary(entries: entries, checkIns: checkIns)
    }

    func weeklyReflections(checkIns: [MoodCheckIn], entries: [JournalEntry]) -> String {
        ReflectionSnippet.weeklyHarbor(entries: entries, checkIns: checkIns)
    }

    func prepareConversationSummary(for contextType: String, entries: [JournalEntry], checkIns: [MoodCheckIn]) -> String {
        let filteredEntries = entries.filter { $0.includeInAI && !$0.isPrivateNote }
        let safeContext = contextType.trimmingCharacters(in: .whitespacesAndNewlines)
        let topTags = PatternEngine.themeBuckets(from: filteredEntries, maxCount: 6)
            .map { "\($0.0) (\($0.1))" }
        let recentCheckIns = Array(checkIns.prefix(30))
        let moodAvg = recentCheckIns.isEmpty ? nil : recentCheckIns.reduce(0) { $0 + $1.moodRaw } / recentCheckIns.count

        let contextSentence = safeContext.isEmpty ? "your upcoming conversation" : safeContext
        return """
        Personal journal summary — not a medical assessment.
        Focus: \(contextSentence).

        Notable themes:
        \(topTags.isEmpty ? "• fewer stable themes from this period" : topTags.map { "• \($0)" }.joined(separator: "\\n"))

        \(checkIns.isEmpty ? "• No check-ins in this period yet." : "• You logged \(checkIns.count) mood check-ins with an average of \(moodAvg ?? 0) on a 1–5 scale.")

        Notes:
        • You can share this summary only when you choose to.
        """
    }

    func copilotResponse(
        prompt: String,
        entries: [JournalEntry],
        checkIns: [MoodCheckIn],
        previousMessages: [CopilotMessage] = []
    ) -> String {
        let normalized = prompt.lowercased()
        if SafetyEngine.detectCrisis(text: normalized) {
            return "Observation: High-risk language detected.\n\(SafetyEngine.safetyMessage(for: normalized, regionCode: Locale.current.regionCode))"
        }

        if normalized.contains("summarise my week") || normalized.contains("summarize my week") {
            let summary = PatternEngine.weeklyHarborSummary(entries: entries, checkIns: checkIns)
            return """
            Observation: \(summary)
            User-provided fact: You asked for a weekly summary of your stored records.
            Reflection: Which day pattern feels most useful to carry forward?
            AI-generated question: What would you like to try next week?
            """
        }

        if normalized.contains("better days") {
            let betterCount = checkIns.filter { $0.moodRaw >= 4 }.count
            return """
            Observation: You logged \(betterCount) check-ins with mood 4 or above.
            User-provided fact: This is based on your check-ins.
            Reflection: What stayed steadier on those days?
            AI-generated question: Want to compare this week with the previous one?
            """
        }

        if normalized.contains("work") && normalized.contains("about") {
            let workEntries = entries.filter {
                $0.tags.map { $0.lowercased() }.contains("work") ||
                $0.bodyText.lowercased().contains("work") ||
                $0.title.lowercased().contains("work")
            }
            return """
            Observation: We found \(workEntries.count) entries tied to work.
            User-provided fact: The count uses your saved tags and text mentions.
            Reflection: Pick one to reflect on again when you're ready.
            AI-generated question: What part of work felt most repeated this week?
            """
        }

        if normalized.contains("sleep") {
            let sleepEntries = entries.filter { $0.tags.map { $0.lowercased() }.contains("sleep") || $0.bodyText.lowercased().contains("sleep") }
            let sleepMention = sleepEntries.count
            return """
            Observation: Sleep is mentioned in \(sleepMention) entries.
            User-provided fact: This is grounded in your logged entries.
            Reflection: Compare how sleep appears near your check-in mood pattern.
            AI-generated question: Do you want a gentler prompt from your recent themes?
            """
        }

        if let promptCategory = PromptCategory.allCases.first(where: { normalized.contains($0.rawValue.lowercased()) }) {
            return """
            Observation: You asked about \(promptCategory.rawValue).
            User-provided fact: No diagnosis or prediction is being made.
            Reflection: \(PromptLibrary.randomPrompt(for: promptCategory))
            AI-generated question: Which phrase here feels most useful?
            """
        }

        let random = PromptLibrary.randomPromptText()
        return """
        Observation: We don't have a dedicated answer yet.
        User-provided fact: This reflects on available patterns and recent activity.
        Reflection: \(random)
        AI-generated question: Want to open a fresh written entry from this prompt?
        """
    }
}
