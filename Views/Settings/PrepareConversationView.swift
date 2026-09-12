import SwiftUI
import SwiftData

struct PrepareConversationView: View {
    @Query(sort: \JournalEntry.createdAt, order: .reverse) private var entries: [JournalEntry]
    @Query(sort: \MoodCheckIn.recordedAt, order: .reverse) private var checkIns: [MoodCheckIn]
    @StateObject private var model = MindHarborViewModel()

    @State private var selectedContext: ConversationContext = .therapy
    @State private var summary = ""

    private let contexts: [ConversationContext] = [
        .therapy,
        .doctor,
        .partner,
        .family,
        .manager,
        .personal
    ]

    var body: some View {
        NavigationStack {
            List {
                Section("Prepare a factual summary") {
                    Picker("Choose destination", selection: $selectedContext) {
                        ForEach(contexts, id: \.self) { context in
                            Text(context.title).tag(context)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Button("Generate summary from selected period") {
                    summary = model.prepareConversationSummary(for: selectedContext.title, entries: entries, checkIns: checkIns)
                }

                if !summary.isEmpty {
                    Section("Summary") {
                        Text(summary)
                            .font(.callout)
                        ShareLink("Share this summary", item: summary)
                    }
                }
            }
            .navigationTitle("Prepare for conversation")
            .onAppear {
                summary = model.prepareConversationSummary(for: selectedContext.title, entries: entries, checkIns: checkIns)
            }
        }
    }
}

private enum ConversationContext: String, CaseIterable, Identifiable {
    case therapy = "Therapy session"
    case doctor = "Doctor appointment"
    case partner = "Conversation with partner"
    case family = "Conversation with family"
    case manager = "Conversation with manager"
    case personal = "Personal reflection"

    var id: String { rawValue }
    var title: String { rawValue }
}
