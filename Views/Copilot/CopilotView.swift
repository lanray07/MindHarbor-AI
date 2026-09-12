import SwiftUI
import SwiftData
import AVFoundation

struct CopilotView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \JournalEntry.createdAt, order: .reverse) private var entries: [JournalEntry]
    @Query(sort: \MoodCheckIn.recordedAt, order: .reverse) private var checkIns: [MoodCheckIn]
    @Query(sort: \CopilotMessage.createdAt, order: .reverse) private var messages: [CopilotMessage]

    @AppStorage(MindHarborKeys.shouldSpeakPrompts) private var shouldSpeakPrompts = true
    @AppStorage(MindHarborKeys.shouldSpeakAudioFeedback) private var shouldSpeakAudioFeedback = true
    @StateObject private var model = MindHarborViewModel()
    @State private var prompt = ""
    @State private var speechSynth = AVSpeechSynthesizer()

    private let suggestions = [
        "What have I written about work recently?",
        "What keeps coming up on difficult days?",
        "What appears on my better days?",
        "Summarise my week.",
        "Give me a gentle prompt.",
        "Show entries where I mentioned sleep.",
        "How have my check-ins been this week?"
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(messages.reversed()) { message in
                            MessageBubble(message: message)
                        }
                    }
                    .padding(.horizontal)
                }

                if messages.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Ready for gentle guidance when you ask.")
                            .foregroundStyle(.secondary)
                        ForEach(suggestions, id: \.self) { suggestion in
                            Button(suggestion) {
                                sendPrompt(suggestion)
                            }
                            .font(.footnote)
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10))
                        }
                    }
                    .padding(.horizontal)
                }

                Divider()

                HStack {
                    TextField("Ask for a gentle reflection", text: $prompt)
                        .textInputAutocapitalization(.never)
                    Button("Send") {
                        sendPrompt(prompt)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding()
            }
            .navigationTitle("MindHarbor Copilot")
            .onAppear {
                if messages.isEmpty {
                    addAssistant("How can I help you reflect today?")
                }
            }
        }
    }

    private func sendPrompt(_ rawPrompt: String) {
        let trimmed = rawPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        context.insert(CopilotMessage(role: "user", content: trimmed))
        let response = model.copilotResponse(prompt: trimmed, entries: entries, checkIns: checkIns, previousMessages: messages)
        addAssistant(response)
        if shouldSpeakPrompts && shouldSpeakAudioFeedback {
            speakText(response)
        }
        prompt = ""
    }

    private func addAssistant(_ text: String) {
        context.insert(CopilotMessage(role: "assistant", content: text))
        try? context.save()
    }

    private func speakText(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-GB")
        speechSynth.speak(utterance)
    }
}

private struct MessageBubble: View {
    let message: CopilotMessage

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(message.role.uppercased())
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(message.content)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(message.createdAt.formatted(date: .omitted, time: .shortened))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .background(message.role == "user" ? Color.blue.opacity(0.07) : Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        .padding(.vertical, 3)
    }
}
