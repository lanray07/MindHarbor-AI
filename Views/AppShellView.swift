import SwiftUI
import UIKit

struct AppShellView: View {
    @AppStorage(MindHarborKeys.appLockEnabled) private var appLockEnabled = false
    @AppStorage(MindHarborKeys.lockInBackground) private var lockInBackground = true
    @AppStorage(MindHarborKeys.pendingIntentAction) private var pendingIntentAction = ""
    @State private var unlockInProgress = false
    @State private var isLocked = false
    @State private var showOnboarding = true
    @State private var selection: Int = 0
    @State private var unlockFailed = false
    @State private var shortcutMessage = ""
    @State private var showShortcutMessage = false
    @State private var handledPendingIntent = ""

    var body: some View {
        TabView(selection: $selection) {
            TodayView()
                .tabItem {
                    Label("Today", systemImage: "sun.max.fill")
                }
                .tag(0)

            JournalListView()
                .tabItem {
                    Label("Journal", systemImage: "book.closed")
                }
                .tag(1)

            PatternsView()
                .tabItem {
                    Label("Patterns", systemImage: "waveform.path.ecg")
                }
                .tag(2)

            CopilotView()
                .tabItem {
                    Label("Copilot", systemImage: "bubble.left.and.bubble.right.fill")
                }
                .tag(3)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(4)
        }
        .tint(.teal)
        .privacySensitive()
        .sheet(isPresented: $showOnboarding, onDismiss: {
            showOnboarding = false
        }) {
            OnboardingView()
        }
        .fullScreenCover(isPresented: $isLocked) {
            PrivacyLockScreen(
                canUseBiometrics: PrivacyProtectionService.shared.canUseBiometrics(),
                onUnlock: unlock,
                unlockFailed: $unlockFailed
            )
        }
        .onAppear {
            showOnboarding = !UserDefaults.standard.bool(forKey: MindHarborKeys.didFinishOnboarding)
            if appLockEnabled {
                lockNow()
            }
            handlePendingIntent()
        }
        .onChange(of: appLockEnabled) { _, enabled in
            if enabled {
                lockNow()
            } else {
                isLocked = false
            }
        }
        .onChange(of: pendingIntentAction) { _, _ in
            handlePendingIntent()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIScene.willEnterForegroundNotification)) { _ in
            if lockInBackground && appLockEnabled {
                lockNow()
            }
        }
        .alert("MindHarbor shortcut", isPresented: $showShortcutMessage) {
            Button("Continue in app") { showShortcutMessage = false }
        } message: {
            Text(shortcutMessage)
        }
    }

    private func lockNow() {
        if !isLocked {
            isLocked = true
        }
    }

    private func unlock() {
        if unlockInProgress { return }
        unlockInProgress = true
        Task {
            let unlocked = await PrivacyProtectionService.shared.unlock(reason: "Open your private journal")
            await MainActor.run {
                unlockInProgress = false
                isLocked = !unlocked
                unlockFailed = !unlocked
            }
        }
    }

    private func handlePendingIntent() {
        guard !pendingIntentAction.isEmpty else { return }
        if pendingIntentAction == handledPendingIntent { return }
        let action = pendingIntentAction.split(separator: "#").map(String.init).first ?? pendingIntentAction
        let shouldKeepForToday = [
            PendingMindHarborIntent.startJournal.rawValue,
            PendingMindHarborIntent.startTalkItOut.rawValue,
            PendingMindHarborIntent.startHandsFree.rawValue,
            PendingMindHarborIntent.justListen.rawValue,
            PendingMindHarborIntent.logMood.rawValue
        ].contains(action)

        handledPendingIntent = pendingIntentAction

        switch action {
        case PendingMindHarborIntent.startJournal.rawValue:
            selection = 0
            shortcutMessage = "Siri requested: open written entry mode."
        case PendingMindHarborIntent.startTalkItOut.rawValue:
            selection = 0
            shortcutMessage = "Siri requested: open Talk It Out mode."
        case PendingMindHarborIntent.startHandsFree.rawValue:
            selection = 0
            shortcutMessage = "Siri requested: open hands-free voice mode."
        case PendingMindHarborIntent.justListen.rawValue:
            selection = 0
            shortcutMessage = "Siri requested: open just-listen flow."
        case PendingMindHarborIntent.logMood.rawValue:
            selection = 0
            shortcutMessage = "Siri requested: open check-in mode."
        case PendingMindHarborIntent.saveEntry.rawValue:
            selection = 0
            shortcutMessage = "Siri requested: save this entry. If a recording is active, finish and use save manually."
        case PendingMindHarborIntent.pauseJournal.rawValue:
            selection = 0
            shortcutMessage = "Siri requested: pause mode is not active until a journal flow is open."
        case PendingMindHarborIntent.resumeJournal.rawValue:
            selection = 0
            shortcutMessage = "Siri requested: resume mode is not active until a journal flow is open."
        case PendingMindHarborIntent.finishJournal.rawValue:
            selection = 0
            shortcutMessage = "Siri requested: finish command received."
        case PendingMindHarborIntent.readWeekly.rawValue:
            selection = 2
            shortcutMessage = "Your weekly reflection is ready in the Patterns tab."
        case PendingMindHarborIntent.readMonthly.rawValue:
            selection = 2
            shortcutMessage = "Your monthly reflection is ready in the Patterns tab."
        default:
            selection = 0
            shortcutMessage = "MindHarbor received a voice shortcut command."
        }
        showShortcutMessage = true
        if !shouldKeepForToday { pendingIntentAction = "" }
    }
}

private struct PrivacyLockScreen: View {
    let canUseBiometrics: Bool
    let onUnlock: () -> Void
    @Binding var unlockFailed: Bool

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.shield")
                .font(.system(size: 56))
                .foregroundStyle(.teal)
            Text("Your journal is private")
                .font(.title2.weight(.semibold))
            Text("Use Face ID / Touch ID to continue.")
            if unlockFailed {
                Text("Unlock failed. Try again.")
                    .foregroundStyle(.red)
                    .font(.callout)
            }
            if canUseBiometrics {
                Button("Unlock now") {
                    onUnlock()
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button("Retry") { onUnlock() }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
}
