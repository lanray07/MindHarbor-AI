import SwiftUI
import SwiftData
import UIKit

struct TodayView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \JournalEntry.createdAt, order: .reverse) private var entries: [JournalEntry]
    @Query private var checkIns: [MoodCheckIn]
    @AppStorage(MindHarborKeys.pendingIntentAction) private var pendingIntentAction = ""

    @State private var showWrite = false
    @State private var showTalk = false
    @State private var showCheckIn = false
    @State private var selectedEntry: JournalEntry?
    @State private var activeTalkMode: VoiceService.Mode = .talkItOut

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    GreetingCard(greeting: greeting)

                    VStack(spacing: 10) {
                        Text("How are things today?")
                            .font(.title3)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 12) {
                            PrimaryActionButton(title: "WRITE", color: .teal, action: { showWrite = true })
                            PrimaryActionButton(title: "TALK", color: .blue, action: { openTalkSheet(.talkItOut) })
                        }

                        Button("CHECK IN") { showCheckIn = true }
                            .buttonStyle(.borderedProminent)
                            .frame(maxWidth: .infinity)
                    }

                    sectionCard(title: "A MOMENT TO REFLECT") {
                        Text("What took the most energy today?")
                        Divider()
                        Text("Would you like to capture one line about it?")
                        Button("Start with a prompt") { showWrite = true }
                            .buttonStyle(.bordered)
                    }

                    sectionCard(title: "SOMETHING TO NOTICE") {
                        Text(ReflectionSnippet.daily)
                            .font(.headline)
                        Text("Explore your patterns for more context.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        NavigationLink("Explore", destination: PatternsView())
                            .buttonStyle(.plain)
                    }

                    sectionCard(title: "Recent Entries") {
                        if entries.isEmpty {
                            Text("No entries yet. Start writing or speaking when you're ready.")
                        } else {
                            ForEach(Array(entries.prefix(4)), id: \.id) { entry in
                                JournalRow(entry: entry)
                                    .contentShape(Rectangle())
                                    .onTapGesture { selectedEntry = entry }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Today")
            .sheet(isPresented: $showWrite) {
                JournalComposeSheet()
            }
            .sheet(isPresented: $showTalk) {
                TalkSheet(initialMode: activeTalkMode)
            }
            .sheet(isPresented: $showCheckIn) {
                MoodCheckInSheet(entriesCount: entries.count)
            }
            .sheet(item: $selectedEntry) { entry in
                JournalEntryDetailView(entry: entry)
            }
            .onAppear {
                if checkIns.isEmpty == false && checkIns.suffix(7).count >= 3 {
                    NotificationManager.shared.requestAuthorizationIfNeeded()
                }
                handlePendingIntentAction()
            }
            .onChange(of: pendingIntentAction) { _, _ in
                handlePendingIntentAction()
            }
        }
    }

    private func openTalkSheet(_ mode: VoiceService.Mode) {
        activeTalkMode = mode
        showTalk = true
    }

    private func handlePendingIntentAction() {
        guard !pendingIntentAction.isEmpty else { return }
        let action = pendingIntentAction.split(separator: "#").map(String.init).first ?? pendingIntentAction
        pendingIntentAction = ""

        switch action {
        case PendingMindHarborIntent.startJournal.rawValue:
            showWrite = true
        case PendingMindHarborIntent.startTalkItOut.rawValue:
            openTalkSheet(.talkItOut)
        case PendingMindHarborIntent.startHandsFree.rawValue:
            openTalkSheet(.handsFree)
        case PendingMindHarborIntent.justListen.rawValue:
            openTalkSheet(.justListen)
        case PendingMindHarborIntent.logMood.rawValue:
            showCheckIn = true
        default:
            break
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        if hour < 12 { return "Good morning." }
        if hour < 17 { return "Good afternoon." }
        return "Good evening."
    }

    @ViewBuilder
    private func sectionCard<Content: View>(title: String, @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.caption.weight(.bold)).foregroundStyle(.secondary)
            content()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct CrisisSupportAlertModifier: ViewModifier {
    @Binding var showSafetyAlert: Bool
    let onContinue: () -> Void

    func body(content: Content) -> some View {
        let contacts = SafetyEngine.supportContacts(for: Locale.current.regionCode)
        let crisisContact = contacts.first(where: { !$0.title.lowercased().contains("emergency") })
        let emergencyContact = contacts.first(where: { $0.title.lowercased().contains("emergency") })

        content.alert("Need support now?", isPresented: $showSafetyAlert) {
            Button("Continue saving privately") { onContinue() }
            if let crisisContact, let supportURL = SafetyEngine.supportDialURL(for: crisisContact.phone) {
                Button("Call \(crisisContact.title)") {
                    UIApplication.shared.open(supportURL)
                }
            }
            if let emergencyContact, let emergencyURL = SafetyEngine.supportDialURL(for: emergencyContact.phone) {
                Button("Call \(emergencyContact.title)") {
                    UIApplication.shared.open(emergencyURL)
                }
            }
            Button("Keep this entry private for now", role: .cancel) {}
        } message: {
            Text("I’m glad you shared this. If this feels urgent, use crisis support now: \(SafetyEngine.supportMessage())")
        }
    }
}

private extension View {
    func crisisSupportAlert(isPresented: Binding<Bool>, onContinue: @escaping () -> Void) -> some View {
        modifier(CrisisSupportAlertModifier(showSafetyAlert: isPresented, onContinue: onContinue))
    }
}

private func attemptCrisisAwareSave(text: String, showSafetyAlert: Binding<Bool>, save: @escaping () -> Void) {
    if SafetyEngine.detectCrisis(text: text) {
        showSafetyAlert.wrappedValue = true
    } else {
        save()
    }
}

private struct GreetingCard: View {
    let greeting: String
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(greeting)
                .font(.system(.title, design: .rounded).weight(.bold))
            Text("How are things today?")
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(colors: [Color.teal.opacity(0.18), Color.blue.opacity(0.08)], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 18)
        )
    }
}

private struct PrimaryActionButton: View {
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(.headline, design: .rounded).weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .foregroundStyle(.white)
                .background(color.gradient, in: RoundedRectangle(cornerRadius: 14))
        }
    }
}

struct JournalRow: View {
    let entry: JournalEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(entry.createdAt.formatted(date: .numeric, time: .omitted))
                Spacer()
                HStack(spacing: 6) {
                    if entry.kind == .voice {
                        Image(systemName: "waveform")
                    }
                    if entry.isFavorite {
                        Image(systemName: "star.fill")
                    }
                    if entry.reflectionPromptCount > 0 {
                        Image(systemName: "lightbulb.fill")
                    }
                    Text(entry.mood.label)
                }
                .font(.caption)
            }
            Text(entry.title.isEmpty ? "Untitled entry" : entry.title)
                .font(.headline)
            Text(entry.excerpt)
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            if !entry.tags.isEmpty {
                WrapLayout(spacing: 8) {
                    ForEach(entry.tags, id: \.self) { tag in
                        Text(tag)
                            .font(.caption2)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.secondary.opacity(0.18), in: Capsule())
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct JournalComposeSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var bodyText = ""
    @State private var mood: MoodLevel = .okay
    @State private var includeAI = true
    @State private var isPrivateNote = false
    @State private var isFavorite = false
    @State private var selectedTags: Set<String> = []
    @State private var includePrompt = ""
    @State private var promptWasAdded = false
    @State private var customTag = ""
    @State private var showSafetyAlert = false

    private let baseTags = ["Work", "Relationships", "Family", "Money", "Health", "Sleep", "Study", "Exercise", "Social", "Change", "Other"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Journal entry") {
                    TextField("Title (optional)", text: $title)
                    TextEditor(text: $bodyText)
                        .frame(minHeight: 220)
                }

                Section("Mood") {
                    Picker("How are you feeling?", selection: $mood) {
                        ForEach(MoodLevel.allCases, id: \.self) { level in
                            Text(level.label).tag(level)
                        }
                    }
                }

                Section("Privacy options") {
                    Toggle("Include in AI reflections", isOn: $includeAI)
                    Toggle("Private note", isOn: $isPrivateNote)
                    Toggle("Save as favourite", isOn: $isFavorite)
                }

                Section("Prompting") {
                    Text(includePrompt.isEmpty ? "Choose a prompt to get started" : includePrompt)
                        .foregroundStyle(includePrompt.isEmpty ? .secondary : .primary)
                    Button("Use gentle prompt") {
                        includePrompt = PromptLibrary.randomPromptText()
                        promptWasAdded = true
                        if bodyText.isEmpty {
                            bodyText = includePrompt
                        } else {
                            bodyText = "\(bodyText)\n\n\(includePrompt)"
                        }
                    }
                }

                Section("Tags") {
                    WrapLayout(spacing: 8) {
                ForEach(baseTags, id: \.self) { tag in
                            Button(action: { toggleTag(tag) }) {
                                Text(tag)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .foregroundStyle(selectedTags.contains(tag) ? .white : .primary)
                                    .background(selectedTags.contains(tag) ? Color.accentColor : Color.secondary.opacity(0.2), in: Capsule())
                            }
                        }
                    }

                    HStack {
                        TextField("Add custom tag", text: $customTag)
                        Button("Add") {
                            let tag = customTag.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !tag.isEmpty {
                                selectedTags.insert(tag)
                                customTag = ""
                            }
                        }
                    }
                }

                Button("Save entry") {
                    attemptCrisisAwareSave(text: bodyText, showSafetyAlert: $showSafetyAlert, save: saveEntry)
                }
                .disabled(bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .crisisSupportAlert(isPresented: $showSafetyAlert, onContinue: saveEntry)
            .navigationTitle("Write")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private func saveEntry() {
        let entry = JournalEntry(
            title: title,
            bodyText: bodyText,
            kind: .written,
            mood: mood,
            includeAI: includeAI,
            isPrivateNote: isPrivateNote,
            isFavorite: isFavorite,
            tags: Array(selectedTags),
            reflectionPromptCount: promptWasAdded ? 1 : 0
        )
        context.insert(entry)
        try? context.save()
        dismiss()
    }

    private func toggleTag(_ tag: String) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
    }
}
struct MoodCheckInSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    var entriesCount: Int

    @State private var mood: MoodLevel = .okay
    @State private var energy: Int = 3
    @State private var stress: Int = 3
    @State private var sleep: Int = 3
    @State private var focus: Int = 3
    @State private var social: Int = 3
    @State private var tags: Set<String> = []
    @State private var showOptional = false

    private let optionalTags = ["Work", "Relationships", "Family", "Money", "Health", "Sleep", "Study", "Exercise", "Social", "Change", "Other"]

    var body: some View {
        NavigationStack {
            Form {
                Section("How are you feeling right now?") {
                    Picker("Mood", selection: $mood) {
                        ForEach(MoodLevel.allCases, id: \.self) { value in
                            Text(value.label).tag(value)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                if showOptional {
                    Section("Optional dimensions (1–5)") {
                        Stepper("Energy \(energy)", value: $energy, in: 1...5)
                        Stepper("Stress \(stress)", value: $stress, in: 1...5)
                        Stepper("Sleep quality \(sleep)", value: $sleep, in: 1...5)
                        Stepper("Focus \(focus)", value: $focus, in: 1...5)
                        Stepper("Social connection \(social)", value: $social, in: 1...5)
                    }
                    Section("What influenced today?") {
                        WrapLayout(spacing: 8) {
                            ForEach(optionalTags, id: \.self) { tag in
                                Button(action: { toggleTag(tag) }) {
                                    Text(tag)
                                        .font(.footnote)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .foregroundStyle(tags.contains(tag) ? .white : .primary)
                                        .background(tags.contains(tag) ? Color.accentColor : Color.secondary.opacity(0.25), in: Capsule())
                                }
                            }
                        }
                    }
                }

                Toggle("Show optional details", isOn: $showOptional)

                Text("You have \(entriesCount) journal entries so far.")

                Button("Save check-in") {
                    context.insert(
                        MoodCheckIn(
                            mood: mood,
                            energy: energy,
                            stress: stress,
                            sleepQuality: sleep,
                            focus: focus,
                            social: social,
                            tags: Array(tags)
                        )
                    )
                    try? context.save()
                    dismiss()
                }
            }
            .navigationTitle("Check in")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private func toggleTag(_ tag: String) {
        if tags.contains(tag) { tags.remove(tag) } else { tags.insert(tag) }
    }
}

struct TalkSheet: View {
    let initialMode: VoiceService.Mode
    @Environment(\.dismiss) private var dismiss
    @StateObject private var voice = VoiceService()
    @State private var reviewTranscript = ""
    @State private var showReview = false
    @State private var mode: VoiceService.Mode = .talkItOut
    @AppStorage(MindHarborKeys.shouldFollowUpWithVoice) private var shouldFollowUpWithVoice = true

    init(initialMode: VoiceService.Mode = .talkItOut) {
        self.initialMode = initialMode
        _mode = State(initialValue: initialMode)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Speak however it comes out.")
                    .font(.title3.weight(.semibold))
                WaveformMock(active: voice.state == .recording, level: voice.waveformLevel)
                Text(String(format: "%d:%02d", voice.elapsedSeconds / 60, voice.elapsedSeconds % 60))
                    .font(.title2.monospacedDigit())

                if voice.promptMode {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("MindHarbor prompt")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(voice.currentPrompt)
                            .font(.body.weight(.semibold))
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        HStack(spacing: 10) {
                            Button("Yes") { voice.acknowledgePrompt() }
                                .buttonStyle(.borderedProminent)
                                .disabled(!voice.canAdvancePrompt)
                                .sensoryFeedback(.impact, trigger: voice.canAdvancePrompt)
                            Button("Not now") { voice.stopPrompting() }
                                .buttonStyle(.bordered)
                            Button("Just listen") { voice.keepJustListening() }
                                .buttonStyle(.bordered)
                        }
                        .font(.footnote)
                    }
                } else if mode == .justListen {
                    Text("Just listen mode: keep speaking without reflective prompts.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                Picker("Mode", selection: $mode) {
                    Text("Talk It Out").tag(VoiceService.Mode.talkItOut)
                    Text("Hands-Free").tag(VoiceService.Mode.handsFree)
                    Text("Just Listen").tag(VoiceService.Mode.justListen)
                }
                .pickerStyle(.segmented)

                HStack(spacing: 12) {
                    Button(voice.state == .recording ? "Pause" : "Resume") {
                        if voice.state == .recording { voice.pause() } else if voice.state == .paused { voice.resume() }
                        else if voice.state == .idle { voice.start(mode: mode) }
                    }
                    Button("Finish") {
                        reviewTranscript = voice.transcript
                        voice.finish()
                        showReview = true
                    }
                    Button("Cancel") {
                        voice.cancel()
                        dismiss()
                    }
                }
                .buttonStyle(.bordered)

                Spacer()
            }
            .padding()
            .navigationTitle("Talk it out")
            .onAppear {
                if voice.state == .idle { voice.start(mode: mode) }
                voice.setFollowUpEnabled(shouldFollowUpWithVoice)
            }
            .onChange(of: mode) { _, newValue in
                if voice.state == .recording || voice.state == .paused {
                    voice.cancel()
                    voice.start(mode: newValue)
                }
            }
            .onChange(of: shouldFollowUpWithVoice) { _, enabled in
                voice.setFollowUpEnabled(enabled)
            }
            .onDisappear { voice.cancel() }
            .sheet(isPresented: $showReview) {
                VoiceReviewSheet(transcript: reviewTranscript)
            }
        }
    }
}

private struct VoicePromptButton: View {
    let text: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(text)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(.thinMaterial, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct VoiceReviewSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage(MindHarborKeys.keepAudioLocally) private var keepAudioLocally = true
    @AppStorage(MindHarborKeys.cloudTranscriptConsent) private var cloudTranscriptConsent = false
    @AppStorage(MindHarborKeys.cloudAIEnabled) private var cloudAIEnabled = false
    @State private var title = ""
    @State private var bodyText: String
    @State private var mood: MoodLevel = .okay
    @State private var includeAI = true
    @State private var keepAudio = false
    @State private var selectedTags: Set<String> = []
    @State private var showSafetyAlert = false
    @State private var reflectionPromptUsed = false

    init(transcript: String) {
        _bodyText = State(initialValue: transcript)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Transcript") {
                    TextField("Title", text: $title)
                    .textInputAutocapitalization(.sentences)
                    VoicePromptButton(text: "Reflect on this") {
                        reflectionPromptUsed = true
                        bodyText = "\(bodyText)\n\n\(PromptLibrary.randomPromptText())"
                    }
                    TextEditor(text: $bodyText).frame(minHeight: 200)
                }
                Section("Mood") {
                    Picker("Mood", selection: $mood) {
                        ForEach(MoodLevel.allCases, id: \.self) { Text($0.label).tag($0) }
                    }
                }
                Section("Recording options") {
                    Toggle("Keep audio on this device", isOn: $keepAudio)
                        .disabled(!keepAudioLocally)
                    Toggle("Include in AI reflections", isOn: $includeAI)
                }
                if cloudAIEnabled && !cloudTranscriptConsent {
                    Text("Cloud transcription is currently disabled by your privacy setting.")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }

                Button("Save entry") {
                    attemptCrisisAwareSave(text: bodyText, showSafetyAlert: $showSafetyAlert, save: saveEntry)
                }
                .disabled(bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .crisisSupportAlert(isPresented: $showSafetyAlert, onContinue: saveEntry)
            .navigationTitle("Your Entry")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Discard") { dismiss() }
                }
            }
            .onAppear {
                if !keepAudioLocally {
                    keepAudio = false
                }
            }
        }
    }

    private func saveEntry() {
        let entry = JournalEntry(
            title: title,
            bodyText: bodyText,
            kind: .voice,
            mood: mood,
            includeInAI: includeAI,
            tags: Array(selectedTags),
            transcript: bodyText,
            keepAudio: keepAudio,
            reflectionPromptCount: reflectionPromptUsed ? 1 : 0
        )
        context.insert(entry)
        try? context.save()
        dismiss()
    }

}
struct WaveformMock: View {
    let active: Bool
    let level: Double
    var body: some View {
        GeometryReader { proxy in
            RoundedRectangle(cornerRadius: 12)
                .fill(active ? .blue.opacity(0.7) : .secondary.opacity(0.3))
                .frame(height: 78)
                .overlay(
                    HStack(alignment: .bottom, spacing: 4) {
                        ForEach(0..<12, id: \.self) { index in
                            Capsule()
                                .fill(Color.white.opacity(active ? 0.5 : 0.3))
                                .frame(width: 6, height: CGFloat((index % 3 == 0 ? 32 : 14)) * (level + 0.3))
                                .animation(.easeInOut(duration: 0.2), value: level)
                        }
                    }
                        .padding(.horizontal, 6)
                )
                .frame(height: 78)
        }
        .frame(height: 78)
    }
}

struct WrapLayout: Layout {
    let spacing: CGFloat

    init(spacing: CGFloat) { self.spacing = spacing }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        return CGSize(width: proposal.width ?? 0, height: 32)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.width {
                x = bounds.minX
                y += size.height + spacing
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(width: size.width, height: size.height))
            x += size.width + spacing
        }
    }
}
