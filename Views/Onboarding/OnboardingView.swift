import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(MindHarborKeys.cloudTranscriptConsent) private var cloudTranscriptConsent = false
    @AppStorage(MindHarborKeys.cloudAIEnabled) private var cloudAIEnabled = false
    @AppStorage(MindHarborKeys.keepAudioLocally) private var keepAudioLocally = true
    @State private var currentPage = 0

    private let pages = 6

    var body: some View {
        NavigationStack {
            TabView(selection: $currentPage) {
                OnboardingScreen(
                    title: "A private place to put things into words.",
                    body: "Write, talk, or simply check in. MindHarbor helps you reflect and notice patterns over time.",
                    imageHint: "figure.wave",
                    secondaryBody: "Write or speak when writing feels too hard. Start with a thought, sentence, or a breath.",
                    primaryButtonTitle: "Enter MindHarbor",
                    onPrimary: nextPage
                )
                .tag(0)

                OnboardingScreen(
                    title: "Sometimes it’s easier to say it.",
                    body: "Speak naturally. MindHarbor can turn your thoughts into a private journal entry.",
                    imageHint: "waveform",
                    secondaryBody: "“Work was a lot today. I got everything done, but I still couldn’t switch off when I got home…”",
                    primaryButtonTitle: "Next",
                    onPrimary: nextPage
                )
                .tag(1)

                OnboardingScreen(
                    title: "Notice what keeps coming back.",
                    body: "Patterns are grounded in what you actually log. No pressure. No diagnosis. Just grounded observations.",
                    imageHint: "chart.bar.doc.horizontal",
                    secondaryBody: "THIS MONTH\nWork 14 entries\nSleep 8 entries\nExercise 6 entries",
                    primaryButtonTitle: "Next",
                    onPrimary: nextPage
                )
                .tag(2)

                OnboardingScreen(
                    title: "Reflection without judgment.",
                    body: "Your space to notice the moments that matter, at your pace.",
                    imageHint: "text.bubble",
                    secondaryBody: "“You’ve mentioned feeling rushed several times this week. What tends to make those days feel different?”",
                    primaryButtonTitle: "Reflect",
                    secondaryButtonTitle: "Just save",
                    onPrimary: nextPage,
                    onSecondary: nextPage
                )
                .tag(3)

                OnboardingScreen(
                    title: "Understand your week.",
                    body: "Your weekly harbour appears as practical reflections, not pressure.",
                    imageHint: "calendar.badge.clock",
                    secondaryBody: "6 check-ins · 4 journal entries\nCommon theme: Work deadlines\nBetter days: Walking appeared often",
                    primaryButtonTitle: "Next",
                    onPrimary: nextPage
                )
                .tag(4)

                PrivacyOnboarding(
                    onConsentChange: { value in
                        cloudTranscriptConsent = value
                        cloudAIEnabled = value
                    },
                    keepAudioLocally: $keepAudioLocally
                )
                .tag(5)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 6) {
                        ForEach(0..<pages, id: \.self) { index in
                            Capsule()
                                .fill(index <= currentPage ? Color.accentColor : Color.secondary.opacity(0.3))
                                .frame(width: 18, height: 6)
                        }
                    }
                }
            }
        }
    }

    private func nextPage() {
        if currentPage < pages - 1 {
            withAnimation { currentPage += 1 }
        } else {
            finish()
        }
    }

    @ViewBuilder
    private func OnboardingScreen(
        title: String,
        body: String,
        imageHint: String,
        secondaryBody: String? = nil,
        primaryButtonTitle: String,
        secondaryButtonTitle: String? = nil,
        onPrimary: @escaping () -> Void,
        onSecondary: (() -> Void)? = nil
    ) -> some View {
        VStack(spacing: 22) {
            Spacer()

            Image(systemName: imageHint)
                .font(.system(size: 56, weight: .semibold))
                .padding(28)
                .background(.ultraThinMaterial, in: Circle())

            Text(title)
                .font(.system(.title2, design: .rounded).weight(.bold))
                .multilineTextAlignment(.center)

            Text(body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            if let secondaryBody {
                Text(secondaryBody)
                    .font(.callout)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 10) {
                if let secondaryButtonTitle, let onSecondary {
                    Button(secondaryButtonTitle) { onSecondary() }
                        .buttonStyle(.bordered)
                }
                Button(primaryButtonTitle, action: onPrimary)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
            }

            Spacer()
        }
        .padding()
    }

    private func finish() {
        UserDefaults.standard.setValue(true, forKey: MindHarborKeys.didFinishOnboarding)
        dismiss()
    }
}

private struct PrivacyOnboarding: View {
    let onConsentChange: (Bool) -> Void
    @Binding var keepAudioLocally: Bool
    @State private var useCloudAI = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 18) {
            Spacer()
            Text("Your journal is personal.")
                .font(.system(.title2, design: .rounded).weight(.bold))
                .multilineTextAlignment(.center)
            Text("How we handle privacy")
                .font(.title3.weight(.semibold))

            VStack(alignment: .leading, spacing: 10) {
                Text("• What stays on-device by default.")
                Text("• What may be sent for optional AI-assisted reflection.")
                Text("• How transcription is handled.")
                Text("• Whether voice recordings are retained.")
                Text("• Whether cloud sync is enabled.")
                Text("• Clear controls to delete or export anything.")
                Text("• Notifications stay private.")
            }
            .font(.callout)
            .foregroundStyle(.secondary)

            Toggle("Keep audio copy on this device", isOn: $keepAudioLocally)
            Toggle("Use secure cloud transcription when needed", isOn: $useCloudAI)
                .onChange(of: useCloudAI) { _, newValue in
                    onConsentChange(newValue)
                }

            Button("Continue Privately") {
                onConsentChange(useCloudAI)
                UserDefaults.standard.setValue(true, forKey: MindHarborKeys.didFinishOnboarding)
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Spacer()
        }
        .padding()
    }
}
