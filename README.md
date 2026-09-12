# MindHarbor AI

SwiftUI iOS scaffold implementing a premium mental wellbeing journal experience.

## Files added

- [MindHarborAIApp.swift](MindHarborAI/MindHarborAIApp.swift)
- [AppShellView.swift](MindHarborAI/Views/AppShellView.swift)
- [OnboardingView.swift](MindHarborAI/Views/Onboarding/OnboardingView.swift)
- [TodayView.swift](MindHarborAI/Views/Today/TodayView.swift)
- [JournalListView.swift](MindHarborAI/Views/Journal/JournalListView.swift)
- [PatternsView.swift](MindHarborAI/Views/Patterns/PatternsView.swift)
- [SettingsView.swift](MindHarborAI/Views/Settings/SettingsView.swift)
- [DomainModels.swift](MindHarborAI/Models/DomainModels.swift)
- [PatternEngine.swift](MindHarborAI/Services/PatternEngine.swift)
- [SafetyEngine.swift](MindHarborAI/Services/SafetyEngine.swift)
- [PromptLibrary.swift](MindHarborAI/Services/PromptLibrary.swift)
- [VoiceService.swift](MindHarborAI/Services/VoiceService.swift)
- [MindHarborIntents.swift](MindHarborAI/Intents/MindHarborIntents.swift)

## Next

1. Open a new Xcode iOS project and add this folder as sources.
2. Wire real Speech/AVFoundation transcription and cloud AI call path.
3. Add SwiftUI persistence policies, authentication, and App Store privacy copy.
4. Expand validation for safety workflows and local notification reminders.

## GitHub iOS CI / Xcode through GitHub Actions

This repo now includes `.github/workflows/ios-ci.yml`, which runs `xcodebuild` on macOS runners.

What it does:
- Builds on every push to `master`.
- On manual dispatch (`workflow_dispatch`), it can archive and upload to TestFlight.

Required repository secrets/variables for end-to-end TestFlight export + upload:
- `BUILD_CERTIFICATE_BASE64`
- `BUILD_CERTIFICATE_PASSWORD`
- `BUILD_MOBILEPROVISION_BASE64`
- `KEYCHAIN_PASSWORD` (optional)
- `XCODE_DEVELOPMENT_TEAM`
- `APP_STORE_CONNECT_API_KEY_ID`
- `APP_STORE_CONNECT_API_ISSUER_ID`
- `APP_STORE_CONNECT_API_PRIVATE_KEY`
- Optional variable: `XCODE_SCHEME` (repository variable) when auto-detection is not desired.

Manual run steps:
1. In GitHub Actions, open the `iOS CI (Xcode on GitHub)` workflow.
2. Run `workflow_dispatch`.
3. Set `export_ipa` to `true`.
