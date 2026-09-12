import Foundation

enum PromptCategory: String, CaseIterable {
    case open = "Open Journal"
    case work = "Work"
    case relationships = "Relationships"
    case family = "Family"
    case rest = "Rest"
    case change = "Change"
    case uncertainty = "Uncertainty"
    case confidence = "Confidence"
    case boundaries = "Boundaries"
    case gratitude = "Gratitude"
    case smallWins = "Small Wins"
    case difficultDays = "Difficult Days"
    case selfCompassion = "Self-compassion"
    case futureSelf = "Future Self"
}

struct PromptLibrary {
    static let prompts: [PromptCategory: [String]] = [
        .open: [
            "What are you noticing right now?",
            "What are you carrying into tomorrow?",
            "What would you like to leave with today?"
        ],
        .work: [
            "What took the most energy today?",
            "What has helped you stay with your work?",
            "What felt helpful, and what felt heavy in your workday?"
        ],
        .relationships: [
            "What felt meaningful in your relationships today?",
            "What made connection easier, or harder, today?",
            "What did you appreciate in one conversation?"
        ],
        .family: [
            "How did home feel today?",
            "What made you feel supported at home?",
            "What would you change at home this week?"
        ],
        .rest: [
            "What helped your body settle down?",
            "Where did you feel space in your day?",
            "What made your evening feel gentler?"
        ],
        .change: [
            "What might be worth adjusting this week?",
            "What helped you keep moving through a change?",
            "What feels worth keeping?"
        ],
        .uncertainty: [
            "What part of this moment feels unclear?",
            "What information would help you make the next move?",
            "Where is uncertainty most present?"
        ],
        .confidence: [
            "Where did you act with confidence today?",
            "What small win can you notice?",
            "What would make the next step feel possible?"
        ],
        .boundaries: [
            "What did you say yes to that didn't need a yes?",
            "Where would a small boundary help?",
            "What boundary felt kind to you this week?"
        ],
        .gratitude: [
            "What small win happened today?",
            "What helped you show up?",
            "Who or what made it possible?"
        ],
        .smallWins: [
            "What is one thing that went slightly better?",
            "Which moment felt surprisingly easier?",
            "What progress do you want to keep?"
        ],
        .difficultDays: [
            "What made this day feel harder?",
            "What did you do when things were heavy?",
            "What would be kinder to yourself right now?"
        ],
        .selfCompassion: [
            "What words would you speak to a friend right now?",
            "What is one kind thing you did today?",
            "How could you be gentler with yourself?"
        ],
        .futureSelf: [
            "What support do you want from your future self?",
            "What would make tomorrow easier?",
            "What do you want to remember from today?"
        ]
    ]

    static func randomPrompt(for category: PromptCategory) -> String {
        prompts[category, default: []].randomElement() ?? "What would you like to notice today?"
    }

    static func randomPromptText() -> String {
        prompts.values.flatMap { $0 }.randomElement() ?? "What took the most energy today?"
    }
}
