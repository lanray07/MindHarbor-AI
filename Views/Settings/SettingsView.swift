import SwiftUI
import SwiftData
import UIKit

struct SettingsView: View {
    @EnvironmentObject private var subscriptionStore: SubscriptionStore
    @AppStorage(MindHarborKeys.shouldSpeakPrompts) private var shouldSpeakPrompts = true
    @AppStorage(MindHarborKeys.shouldReadWeekly) private var shouldReadWeekly = true
    @AppStorage(MindHarborKeys.shouldReadMonthly) private var shouldReadMonthly = true
    @AppStorage(MindHarborKeys.shouldFollowUpWithVoice) private var shouldFollowUpWithVoice = true
    @AppStorage(MindHarborKeys.cloudAIEnabled) private var cloudAIEnabled = false
    @AppStorage(MindHarborKeys.cloudTranscriptConsent) private var cloudTranscriptConsent = false
    @AppStorage(MindHarborKeys.privateNotifications) private var privateNotifications = true
    @AppStorage(MindHarborKeys.keepAudioLocally) private var keepAudioLocally = true
    @AppStorage(MindHarborKeys.reminderMorning) private var reminderMorning = false
    @AppStorage(MindHarborKeys.reminderAfternoon) private var reminderAfternoon = false
    @AppStorage(MindHarborKeys.reminderEvening) private var reminderEvening = true
    @AppStorage(MindHarborKeys.reminderCustomEnabled) private var reminderCustomEnabled = false
    @AppStorage(MindHarborKeys.reminderCustomHour) private var reminderCustomHour = 18
    @AppStorage(MindHarborKeys.reminderCustomMinute) private var reminderCustomMinute = 30
    @AppStorage(MindHarborKeys.appLockEnabled) private var appLockEnabled = false
    @AppStorage(MindHarborKeys.lockInBackground) private var lockInBackground = true
    @AppStorage(MindHarborKeys.shouldSpeakAudioFeedback) private var shouldSpeakAudioFeedback = true

    @Environment(\.modelContext) private var context
    @Query private var entries: [JournalEntry]
    @Query private var checkIns: [MoodCheckIn]
    @Query private var messages: [CopilotMessage]
    @Query private var contacts: [SupportContact]

    @State private var showDeleteAlert = false
    @State private var deleteAllData = false
    @State private var showDeleteAudioAlert = false
    @State private var showDeleteTranscriptsAlert = false
    @State private var showSubscription = ProcessInfo.processInfo.arguments.contains("-showSubscription")

    var body: some View {
        NavigationStack {
            List {
                Section("MindHarbor Plus") {
                    Button {
                        showSubscription = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: subscriptionStore.hasActiveSubscription ? "checkmark.seal.fill" : "sparkles")
                                .foregroundStyle(.teal)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(subscriptionStore.hasActiveSubscription ? "MindHarbor Plus is active" : "Explore MindHarbor Plus")
                                    .foregroundStyle(.primary)
                                Text(subscriptionStore.hasActiveSubscription ? "Your premium reflections are unlocked." : "AI reflections and deeper personal patterns.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .accessibilityIdentifier("mindharbor-plus-button")
                }

                Section("Spoken responses") {
                    Toggle("Spoken prompts", isOn: $shouldSpeakPrompts)
                    Toggle("Voice follow-ups", isOn: $shouldFollowUpWithVoice)
                    Toggle("Read weekly reflection", isOn: $shouldReadWeekly)
                    Toggle("Read monthly reflection", isOn: $shouldReadMonthly)
                }

                Section("Voice & privacy") {
                    Toggle("Keep app voice local", isOn: $keepAudioLocally)
                    Toggle("Enable cloud AI features", isOn: $cloudAIEnabled)
                    Toggle("Private lock screen notifications", isOn: $privateNotifications)
                    Toggle("Enable app lock", isOn: $appLockEnabled)
                    Toggle("Lock when returning to app", isOn: $lockInBackground)
                }

                Section("My support") {
                    NavigationLink("My support") { MySupportView() }
                    NavigationLink("Prepare me for conversation") { PrepareConversationView() }
                }

                Section("Reminders") {
                    Toggle("Morning check-in", isOn: $reminderMorning)
                    Toggle("Afternoon check-in", isOn: $reminderAfternoon)
                    Toggle("Evening check-in", isOn: $reminderEvening)
                    Toggle("Custom reminder", isOn: $reminderCustomEnabled)
                    if reminderCustomEnabled {
                        DatePicker("Reminder time", selection: customReminderDate, displayedComponents: .hourAndMinute)
                    }
                }

                Section("Spoken options") {
                    Toggle("Audio feedback", isOn: $shouldSpeakAudioFeedback)
                }

                Section("Data controls") {
                    ShareLink("Export data", item: exportText, subject: Text("MindHarbor export"), message: Text("Personal journal export"))
                    Button("Delete AI history") { deleteMessages() }
                    Button("Delete all voice recordings", role: .destructive) { showDeleteAudioAlert = true }
                    Button("Delete all transcripts", role: .destructive) { showDeleteTranscriptsAlert = true }
                    Button("Delete all journal data", role: .destructive) { showDeleteAlert = true }
                    Button("Delete account") { deleteAllData = true; showDeleteAlert = true }
                }
                
                Section("Privacy commitments") {
                    Text("No journal data is sold.")
                    Text("No third-party diagnosis or condition claims are made.")
                    Text("Private moments stay private by default. You control deletion.")
                }

                Section("Safety resources") {
                    Text("Regional support and emergency guidance:")
                    Text(SafetyEngine.supportMessage())
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    ForEach(SafetyEngine.supportContacts(for: Locale.current.regionCode)) { contact in
                        if let phoneURL = supportURL(for: contact.phone) {
                            Button {
                                UIApplication.shared.open(phoneURL)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(contact.title)
                                    if let note = contact.note {
                                        Text(note).font(.caption).foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .foregroundStyle(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showSubscription) {
                SubscriptionView()
            }
            .onAppear {
                NotificationManager.shared.configureReminders(
                    morning: reminderMorning,
                    afternoon: reminderAfternoon,
                    evening: reminderEvening,
                    customEnabled: reminderCustomEnabled,
                    customHour: reminderCustomHour,
                    customMinute: reminderCustomMinute
                )
            }
            .onChange(of: reminderMorning) { _, _ in scheduleReminders() }
            .onChange(of: reminderAfternoon) { _, _ in scheduleReminders() }
                .onChange(of: reminderEvening) { _, _ in scheduleReminders() }
                .onChange(of: reminderCustomEnabled) { _, _ in scheduleReminders() }
                .onChange(of: reminderCustomHour) { _, _ in scheduleReminders() }
                .onChange(of: reminderCustomMinute) { _, _ in scheduleReminders() }
                .onChange(of: privateNotifications) { _, _ in scheduleReminders() }
                .onChange(of: cloudAIEnabled) { _, newValue in
                    cloudTranscriptConsent = newValue
                }
            .alert("Delete journal data?", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) {
                    showDeleteAlert = false
                    deleteAllData = false
                }
                Button("Delete", role: .destructive) {
                    if deleteAllData {
                        clearEverything()
                    }
                    showDeleteAlert = false
                    deleteAllData = false
                }
            } message: {
                Text(deleteAllData ? "This will permanently remove all journal entries, check-ins, and copilot history." : "Delete AI history only?")
            }
            .alert("Delete all voice recordings?", isPresented: $showDeleteAudioAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) { clearAudioRecordings() }
            } message: {
                Text("This removes local links to every saved recording.")
            }
            .alert("Delete all transcripts?", isPresented: $showDeleteTranscriptsAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) { clearTranscripts() }
            } message: {
                Text("This removes transcript text but keeps the journal entry body.")
            }
        }
    }

    private var exportText: String {
        var lines: [String] = [
            "MindHarbor AI Export",
            "Generated: \(Date().formatted())",
            ""
        ]
        for entry in entries {
            lines.append("ENTRY|\(entry.id)|\(entry.createdAt)|\(entry.kindRaw)|\(entry.title)|\(entry.mood.label)|\(entry.includeInAI)|\(entry.bodyText)")
        }
        for checkIn in checkIns {
            lines.append("CHECKIN|\(checkIn.id)|\(checkIn.recordedAt)|\(checkIn.moodRaw)|\(checkIn.energy)|\(checkIn.stress)|\(checkIn.sleepQuality)|\(checkIn.focus)|\(checkIn.social)")
        }
        for message in messages {
            lines.append("COPILOT|\(message.id)|\(message.createdAt)|\(message.role)|\(message.content)")
        }
        return lines.joined(separator: "\n")
    }

    private func deleteMessages() {
        messages.forEach(context.delete)
        try? context.save()
    }

    private func clearEverything() {
        entries.forEach(context.delete)
        checkIns.forEach(context.delete)
        messages.forEach(context.delete)
        contacts.forEach(context.delete)
        try? context.save()
    }

    private func clearAudioRecordings() {
        entries.forEach {
            $0.deletedAudio = true
            $0.audioFileName = nil
            $0.keepAudio = false
        }
        try? context.save()
    }

    private func clearTranscripts() {
        entries.forEach { $0.transcript = nil }
        try? context.save()
    }

    private func supportURL(for phone: String) -> URL? {
        if let directURL = SafetyEngine.supportDialURL(for: phone) { return directURL }
        let cleaned = phone.filter { $0.isNumber || $0 == "+" }
        guard !cleaned.isEmpty else { return nil }
        return URL(string: "tel:\(cleaned)")
    }

    private var customReminderDate: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(
                    bySettingHour: reminderCustomHour,
                    minute: reminderCustomMinute,
                    second: 0,
                    of: Date()
                ) ?? Date()
            },
            set: { newDate in
                let components = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                reminderCustomHour = components.hour ?? reminderCustomHour
                reminderCustomMinute = components.minute ?? reminderCustomMinute
            }
        )
    }

    private func scheduleReminders() {
        NotificationManager.shared.configureReminders(
            morning: reminderMorning,
            afternoon: reminderAfternoon,
            evening: reminderEvening,
            customEnabled: reminderCustomEnabled,
            customHour: reminderCustomHour,
            customMinute: reminderCustomMinute
        )
    }
}
