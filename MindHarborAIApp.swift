import SwiftData
import SwiftUI

@main
struct MindHarborAIApp: App {
    init() {
        if UserDefaults.standard.object(forKey: MindHarborKeys.shouldSpeakPrompts) == nil {
            UserDefaults.standard.setValue(true, forKey: MindHarborKeys.shouldSpeakPrompts)
        }
        if UserDefaults.standard.object(forKey: MindHarborKeys.shouldReadWeekly) == nil {
            UserDefaults.standard.setValue(true, forKey: MindHarborKeys.shouldReadWeekly)
        }
        if UserDefaults.standard.object(forKey: MindHarborKeys.shouldReadMonthly) == nil {
            UserDefaults.standard.setValue(true, forKey: MindHarborKeys.shouldReadMonthly)
        }
        if UserDefaults.standard.object(forKey: MindHarborKeys.shouldFollowUpWithVoice) == nil {
            UserDefaults.standard.setValue(true, forKey: MindHarborKeys.shouldFollowUpWithVoice)
        }
        if UserDefaults.standard.object(forKey: MindHarborKeys.shouldSpeakAudioFeedback) == nil {
            UserDefaults.standard.setValue(true, forKey: MindHarborKeys.shouldSpeakAudioFeedback)
        }
        if UserDefaults.standard.object(forKey: MindHarborKeys.appLockEnabled) == nil {
            UserDefaults.standard.setValue(false, forKey: MindHarborKeys.appLockEnabled)
        }
        if UserDefaults.standard.object(forKey: MindHarborKeys.lockInBackground) == nil {
            UserDefaults.standard.setValue(true, forKey: MindHarborKeys.lockInBackground)
        }
        if UserDefaults.standard.object(forKey: MindHarborKeys.cloudAIEnabled) == nil {
            UserDefaults.standard.setValue(false, forKey: MindHarborKeys.cloudAIEnabled)
        }
        if UserDefaults.standard.object(forKey: MindHarborKeys.reminderMorning) == nil {
            UserDefaults.standard.setValue(false, forKey: MindHarborKeys.reminderMorning)
        }
        if UserDefaults.standard.object(forKey: MindHarborKeys.reminderAfternoon) == nil {
            UserDefaults.standard.setValue(false, forKey: MindHarborKeys.reminderAfternoon)
        }
        if UserDefaults.standard.object(forKey: MindHarborKeys.reminderEvening) == nil {
            UserDefaults.standard.setValue(true, forKey: MindHarborKeys.reminderEvening)
        }
        if UserDefaults.standard.object(forKey: MindHarborKeys.reminderCustomEnabled) == nil {
            UserDefaults.standard.setValue(false, forKey: MindHarborKeys.reminderCustomEnabled)
        }
        if UserDefaults.standard.object(forKey: MindHarborKeys.reminderCustomHour) == nil {
            UserDefaults.standard.setValue(18, forKey: MindHarborKeys.reminderCustomHour)
        }
        if UserDefaults.standard.object(forKey: MindHarborKeys.reminderCustomMinute) == nil {
            UserDefaults.standard.setValue(30, forKey: MindHarborKeys.reminderCustomMinute)
        }
    }

    var body: some Scene {
        WindowGroup {
            AppShellView()
                .modelContainer(for: [JournalEntry.self, MoodCheckIn.self, CopilotMessage.self, SupportContact.self])
        }
    }
}

