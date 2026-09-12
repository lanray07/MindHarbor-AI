import Foundation
import AVFoundation

final class VoiceService: ObservableObject {
    enum Mode {
        case talkItOut
        case justListen
        case handsFree
    }

    enum State: Equatable {
        case idle
        case recording
        case paused
        case finished
    }

    @Published var state: State = .idle
    @Published var elapsedSeconds: Int = 0
    @Published var transcript: String = ""
    @Published var mode: Mode = .talkItOut
    @Published var waveformLevel: Double = 0.15
    @Published var isPrompting = false
    @Published var currentPrompt = "Speak however it comes out."
    @Published var canAdvancePrompt = false
    @Published private(set) var followUpEnabled = true

    var promptMode: Bool { mode != .justListen }

    private var timer: Timer?
    private var phase = 0
    private var promptIndex = 0
    private let promptCadenceSeconds = 18
    private let talkItOutPrompts = [
        "What has taken up the most space in your mind today?",
        "Was there a moment that felt easier?",
        "What would you like to carry forward from this moment?"
    ]
    private let handsFreePrompts = [
        "What has taken up the most space in your mind today?",
        "Would another question be useful, or keep this flowing?",
        "What felt a little easier today?"
    ]

    func requestPermissionIfNeeded() async -> Bool {
        true
    }

    func start(mode: Mode = .talkItOut) {
        phase = 0
        promptIndex = 0
        self.mode = mode
        state = .recording
        elapsedSeconds = 0
        transcript = ""
        waveformLevel = 0.15
        configurePromptState()

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.elapsedSeconds += 1
            self.waveformLevel = 0.25 + (Double((self.phase + 1).isMultiple(of: 3) ? 4 : 0) / 20.0)
            self.phase += 1
            if self.elapsedSeconds.isMultiple(of: 2) {
                self.appendTranscriptChunk()
            }
            if self.isPrompting {
                self.canAdvancePrompt = self.elapsedSeconds.isMultiple(of: self.promptCadenceSeconds)
            }
        }
    }

    func pause() {
        guard state == .recording else { return }
        state = .paused
        timer?.invalidate()
        canAdvancePrompt = false
    }

    func resume() {
        guard state == .paused else { return }
        state = .recording
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.elapsedSeconds += 1
            self.waveformLevel = 0.25 + (Double((self.phase + 1).isMultiple(of: 3) ? 4 : 0) / 20.0)
            self.phase += 1
            if self.elapsedSeconds.isMultiple(of: 2) {
                self.appendTranscriptChunk()
            }
            if self.isPrompting {
                self.canAdvancePrompt = self.elapsedSeconds.isMultiple(of: self.promptCadenceSeconds)
            }
        }
    }

    func finish() {
        state = .finished
        timer?.invalidate()
        isPrompting = false
        canAdvancePrompt = false
    }

    func cancel() {
        state = .idle
        elapsedSeconds = 0
        transcript = ""
        waveformLevel = 0.1
        isPrompting = false
        canAdvancePrompt = false
        promptIndex = 0
        currentPrompt = "Speak however it comes out."
        timer?.invalidate()
    }

    func acknowledgePrompt() {
        guard isPrompting else { return }
        advancePrompt()
    }

    func keepJustListening() {
        mode = .justListen
        isPrompting = false
        canAdvancePrompt = false
        currentPrompt = "Speak however it comes out."
    }

    func stopPrompting() {
        isPrompting = false
        canAdvancePrompt = false
        currentPrompt = "Continue speaking for now. You can save whenever you’re ready."
    }

    func setFollowUpEnabled(_ enabled: Bool) {
        followUpEnabled = enabled
        if mode == .justListen {
            if !enabled {
                currentPrompt = "Speak however it comes out."
            }
            return
        }

        configurePromptState()
    }

    private func configurePromptState() {
        if mode == .justListen || !followUpEnabled {
            isPrompting = false
            canAdvancePrompt = false
            currentPrompt = "Speak however it comes out."
            return
        }
        isPrompting = true
        currentPrompt = mode == .handsFree ?
            "What has taken up the most space in your mind today?" :
            "What has taken up the most space in your mind today?"
        canAdvancePrompt = false
    }

    private func appendTranscriptChunk() {
        let bank = [
            "I had a lot on my mind.",
            "Today felt a little heavier than expected.",
            "I think I managed to get through a lot.",
            "There were moments I wished I could rest.",
            "I kept thinking about my next step."
        ]
        let next = bank[phase % bank.count]
        transcript = transcript.isEmpty ? next : "\(transcript) \(next)"
    }

    private func advancePrompt() {
        let prompts = mode == .handsFree ? handsFreePrompts : talkItOutPrompts
        promptIndex += 1
        if promptIndex < prompts.count {
            currentPrompt = prompts[promptIndex]
            canAdvancePrompt = false
        } else {
            stopPrompting()
        }
    }
}
