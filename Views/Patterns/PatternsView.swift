import AVFoundation
import SwiftData
import SwiftUI

struct PatternsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \JournalEntry.createdAt, order: .reverse) private var entries: [JournalEntry]
    @Query private var checkIns: [MoodCheckIn]
    @StateObject private var model = MindHarborViewModel()
    @StateObject private var speechSynth = AVSpeechSynthesizerState()

    @AppStorage(MindHarborKeys.shouldReadWeekly) private var shouldReadWeekly = true
    @AppStorage(MindHarborKeys.shouldReadMonthly) private var shouldReadMonthly = true
    @State private var selectedTheme: ThemeBucket?
    @State private var weeklyHarborHidden = false
    @State private var monthlyHarborHidden = false
    @State private var weeklySaved = false
    @State private var monthlySaved = false

    var body: some View {
        NavigationStack {
            List {
                Section("What keeps coming back?") {
                    let themes = PatternEngine.themeBuckets(from: entries, maxCount: 8)
                    if themes.isEmpty {
                        Text("Not enough information yet. Keep checking in when it feels useful. Patterns will appear here when there's enough information.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(themes, id: \.0) { item in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(item.0).font(.headline)
                                    Text("\(item.1) entries")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Button("View") {
                                    selectedTheme = ThemeBucket(name: item.0, count: item.1)
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                }

                Section("Observed patterns") {
                    let patterns = PatternEngine.analyze(entries: entries, checkIns: checkIns)
                    if patterns.isEmpty {
                        Text("Not enough information yet. Keep checking in when it feels useful.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(patterns) { item in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.title).font(.headline)
                                Text(item.detail)
                                Text("Observed across \(item.sampleCount) samples • \(item.confidence.rawValue)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Divider()
                        }
                    }
                }

                if !weeklyHarborHidden {
                    Section("YOUR WEEKLY HARBOR") {
                        Text(weeklySummary)
                            .font(.body)
                        HStack {
                            Button("Save") {
                                saveEntry(title: "Your weekly harbor", body: weeklySummary)
                                weeklySaved = true
                            }
                            .buttonStyle(.bordered)
                            Button("Listen") { speak(weeklySummary, isWeekly: true) }
                                .buttonStyle(.bordered)
                            Button("Reflect") {
                                createReflectionNote(title: "Weekly reflection prompt", body: weeklySummary)
                            }
                            .buttonStyle(.bordered)
                            Button("Dismiss", role: .cancel) { weeklyHarborHidden = true }
                                .buttonStyle(.plain)
                                .foregroundStyle(.secondary)
                        }
                        .font(.footnote)
                        if weeklySaved {
                            Text("Saved to journal.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                if !monthlyHarborHidden {
                    Section("YOUR MONTHLY HARBOR") {
                        Text(monthlySummary)
                            .font(.body)
                        HStack {
                            Button("Save") {
                                saveEntry(title: "Your monthly harbor", body: monthlySummary)
                                monthlySaved = true
                            }
                            .buttonStyle(.bordered)
                            Button("Listen") { speak(monthlySummary, isWeekly: false) }
                                .buttonStyle(.bordered)
                            Button("Reflect") {
                                createReflectionNote(title: "Monthly reflection prompt", body: monthlySummary)
                            }
                            .buttonStyle(.bordered)
                            Button("Dismiss", role: .cancel) { monthlyHarborHidden = true }
                                .buttonStyle(.plain)
                                .foregroundStyle(.secondary)
                        }
                        .font(.footnote)
                        if monthlySaved {
                            Text("Saved to journal.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("What would you like to do next?") {
                    if shouldReadWeekly {
                        Button("Revisit this week") {
                            speak(weeklySummary, isWeekly: true)
                        }
                    }
                    if shouldReadMonthly {
                        Button("Revisit this month") {
                            speak(monthlySummary, isWeekly: false)
                        }
                    }
                    Button("Dismiss all weekly/monthly cards", role: .cancel) {
                        weeklyHarborHidden = true
                        monthlyHarborHidden = true
                    }
                }
            }
            .navigationTitle("Patterns")
            .sheet(item: $selectedTheme) { theme in
                ThemeDetailSheet(
                    themeName: theme.name,
                    entries: themeMatchingEntries(theme.name),
                    onDone: { selectedTheme = nil }
                )
            }
        }
    }

    private var weeklySummary: String {
        model.weeklySummary(checkIns: checkIns, entries: entries)
    }

    private var monthlySummary: String {
        model.monthlySummary(checkIns: checkIns, entries: entries)
    }

    private func themeMatchingEntries(_ name: String) -> [JournalEntry] {
        entries.filter { entry in
            entry.tags.contains(where: { $0.caseInsensitiveCompare(name) == .orderedSame }) ||
            entry.bodyText.localizedCaseInsensitiveContains(name) ||
            entry.title.localizedCaseInsensitiveContains(name)
        }
    }

    private func speak(_ text: String, isWeekly: Bool) {
        guard !(isWeekly ? !shouldReadWeekly : !shouldReadMonthly) else { return }
        speechSynth.speak(text)
    }

    private func saveEntry(title: String, body: String) {
        context.insert(
            JournalEntry(
                title: title,
                bodyText: body,
                kind: .prompted,
                mood: .okay,
                includeInAI: true,
                isPrivateNote: false,
                isFavorite: false,
                tags: ["harbor", "reflection"],
                reflectionPromptCount: 0
            )
        )
        try? context.save()
    }

    private func createReflectionNote(title: String, body: String) {
        context.insert(
            JournalEntry(
                title: title,
                bodyText: "\(body)\n\nWhat would you like to reflect on next?",
                kind: .prompted,
                mood: .okay,
                includeInAI: true,
                isPrivateNote: false,
                isFavorite: false,
                tags: ["reflection", "prompted"],
                reflectionPromptCount: 1
            )
        )
        try? context.save()
    }
}

private final class AVSpeechSynthesizerState: NSObject, ObservableObject {
    private let synthesizer = AVSpeechSynthesizer()

    func speak(_ text: String) {
        if synthesizer.isSpeaking { synthesizer.stopSpeaking(at: .immediate) }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        synthesizer.speak(utterance)
    }
}

private struct ThemeBucket: Identifiable, Equatable {
    let name: String
    let count: Int
    var id: String { name }
}

private struct ThemeDetailSheet: View {
    let themeName: String
    let entries: [JournalEntry]
    let onDone: () -> Void

    var body: some View {
        NavigationStack {
            List {
                if entries.isEmpty {
                    Text("No entries found for this theme yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(entries) { entry in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(entry.title.isEmpty ? "Untitled entry" : entry.title)
                                .font(.headline)
                            Text(entry.createdAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(entry.excerpt)
                                .font(.body)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle(themeName)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { onDone() }
                }
            }
        }
    }
}
