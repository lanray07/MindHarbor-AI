import AppIntents

enum PendingMindHarborIntent: String {
    case unknown
    case startJournal
    case startTalkItOut
    case startHandsFree
    case justListen
    case logMood
    case saveEntry
    case pauseJournal
    case resumeJournal
    case finishJournal
    case reflectionPrompt
    case readWeekly
    case readMonthly
    case askReflectionPrompt
}

struct StartMindHarborJournal: AppIntent {
    static var title: LocalizedStringResource = "Start a MindHarbor journal"
    static var description = IntentDescription("Open a quick written journal entry.")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        setPendingIntent(.startJournal)
        return .result(dialog: "Starting a written MindHarbor entry.")
    }
}

struct StartTalkItOut: AppIntent {
    static var title: LocalizedStringResource = "Start voice journal"
    static var description = IntentDescription("Open voice journaling in MindHarbor.")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        setPendingIntent(.startTalkItOut)
        return .result(dialog: "Ready to record a voice entry.")
    }
}

struct StartHandsFreeReflection: AppIntent {
    static var title: LocalizedStringResource = "Start hands-free reflection"
    static var openAppWhenRun: Bool = true
    func perform() async throws -> some IntentResult {
        setPendingIntent(.startHandsFree)
        return .result(dialog: "Hands-free reflection mode is ready.")
    }
}

struct JustListenIntent: AppIntent {
    static var title: LocalizedStringResource = "Just listen"
    static var openAppWhenRun: Bool = true
    func perform() async throws -> some IntentResult {
        setPendingIntent(.justListen)
        return .result(dialog: "Entering just listen mode.")
    }
}

struct LogMoodIntent: AppIntent {
    static var title: LocalizedStringResource = "Log my mood"
    static var openAppWhenRun: Bool = true
    func perform() async throws -> some IntentResult {
        setPendingIntent(.logMood)
        return .result(dialog: "Ready to log a mood check-in.")
    }
}

struct SaveThisEntryIntent: AppIntent {
    static var title: LocalizedStringResource = "Save this entry"
    static var openAppWhenRun: Bool = true
    func perform() async throws -> some IntentResult {
        setPendingIntent(.saveEntry)
        return .result(dialog: "Please save the current draft in the open voice or written entry.")
    }
}

struct PauseJournalIntent: AppIntent {
    static var title: LocalizedStringResource = "Pause journal"
    static var openAppWhenRun: Bool = true
    func perform() async throws -> some IntentResult {
        setPendingIntent(.pauseJournal)
        return .result(dialog: "Pause command acknowledged.")
    }
}

struct ResumeJournalIntent: AppIntent {
    static var title: LocalizedStringResource = "Resume journal"
    static var openAppWhenRun: Bool = true
    func perform() async throws -> some IntentResult {
        setPendingIntent(.resumeJournal)
        return .result(dialog: "Resume command acknowledged.")
    }
}

struct FinishJournalIntent: AppIntent {
    static var title: LocalizedStringResource = "Finish journal"
    static var openAppWhenRun: Bool = true
    func perform() async throws -> some IntentResult {
        setPendingIntent(.finishJournal)
        return .result(dialog: "Finish command acknowledged.")
    }
}

struct ReflectPromptIntent: AppIntent {
    static var title: LocalizedStringResource = "Give me a reflection prompt"
    static var openAppWhenRun: Bool = false
    func perform() async throws -> some IntentResult {
        setPendingIntent(.reflectionPrompt)
        return .result(value: PromptLibrary.randomPromptText())
    }
}

struct ReadReflectionPromptIntent: AppIntent {
    static var title: LocalizedStringResource = "Read my reflection prompt"
    static var openAppWhenRun: Bool = false
    func perform() async throws -> some IntentResult {
        setPendingIntent(.askReflectionPrompt)
        return .result(dialog: PromptLibrary.randomPromptText())
    }
}

struct ReadWeeklyReflectionIntent: AppIntent {
    static var title: LocalizedStringResource = "How have my check-ins been this week?"
    static var openAppWhenRun: Bool = true
    func perform() async throws -> some IntentResult {
        setPendingIntent(.readWeekly)
        return .result(dialog: "Your weekly trend is available in Patterns.")
    }
}

struct ReadMonthlyReflectionIntent: AppIntent {
    static var title: LocalizedStringResource = "Read my monthly reflection"
    static var openAppWhenRun: Bool = true
    func perform() async throws -> some IntentResult {
        setPendingIntent(.readMonthly)
        return .result(dialog: "Your monthly trend is available in Patterns.")
    }
}

struct MindHarborIntentGroup: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        [
            AppShortcut(intent: StartMindHarborJournal(), phrases: ["Start a MindHarbor journal"]),
            AppShortcut(intent: StartTalkItOut(), phrases: ["Start voice journal", "Start Talk It Out"]),
            AppShortcut(intent: StartHandsFreeReflection(), phrases: ["Start hands-free reflection"]),
            AppShortcut(intent: JustListenIntent(), phrases: ["Just listen"]),
            AppShortcut(intent: LogMoodIntent(), phrases: ["Log my mood"]),
            AppShortcut(intent: SaveThisEntryIntent(), phrases: ["Save this entry"]),
            AppShortcut(intent: PauseJournalIntent(), phrases: ["Pause journal"]),
            AppShortcut(intent: ResumeJournalIntent(), phrases: ["Resume journal"]),
            AppShortcut(intent: FinishJournalIntent(), phrases: ["Finish journal"]),
            AppShortcut(intent: ReflectPromptIntent(), phrases: ["Give me a reflection prompt", "Read my reflection prompt"]),
            AppShortcut(intent: ReadReflectionPromptIntent(), phrases: ["Read my reflection prompt"]),
            AppShortcut(intent: ReadWeeklyReflectionIntent(), phrases: ["How have my check-ins been this week", "Read my weekly reflection"]),
            AppShortcut(intent: ReadMonthlyReflectionIntent(), phrases: ["Read my monthly reflection"])
        ]
    }
}

private func setPendingIntent(_ action: PendingMindHarborIntent) {
    let token = "\(action.rawValue)#\(UUID().uuidString)"
    UserDefaults.standard.setValue(token, forKey: MindHarborKeys.pendingIntentAction)
}
