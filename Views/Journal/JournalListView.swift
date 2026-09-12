import SwiftUI
import SwiftData

private enum JournalFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case written = "Written"
    case voice = "Voice"
    case prompted = "Prompted"
    case favorites = "Favourites"
    var id: String { rawValue }
}

struct JournalListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \JournalEntry.createdAt, order: .reverse) private var entries: [JournalEntry]
    @State private var searchText = ""
    @State private var selectedFilter: JournalFilter = .all
    @State private var selectedEntry: JournalEntry?
    @State private var showAIOnly = false
    @State private var showOnlyReflection = false
    @State private var selectedMood: MoodLevel?
    @State private var selectedTag: String = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                List {
                    Section("Search & filters") {
                        TextField("Show entries about work", text: $searchText)
                            .textInputAutocapitalization(.never)
                        Picker("Type", selection: $selectedFilter) {
                            ForEach(JournalFilter.allCases) { value in
                                Text(value.rawValue).tag(value)
                            }
                        }
                        .pickerStyle(.segmented)

                        Toggle("Include prompts with AI", isOn: $showAIOnly)
                        Toggle("Reflection history only", isOn: $showOnlyReflection)

                        Picker("Mood", selection: $selectedMood) {
                            Text("Any").tag(nil as MoodLevel?)
                            ForEach(MoodLevel.allCases, id: \.self) { Text($0.label).tag(Optional($0)) }
                        }

                        if !availableTags.isEmpty {
                            Picker("Tag", selection: $selectedTag) {
                                Text("Any").tag("")
                                ForEach(availableTags, id: \.self) { tag in
                                    Text(tag).tag(tag)
                                }
                            }
                        }
                    }

                    Section("Journal timeline") {
                        if filteredEntries.isEmpty {
                            Text("No matching entries yet. Ask the Journal tab to add your first note.")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(filteredEntries) { entry in
                                JournalRow(entry: entry)
                                    .contentShape(Rectangle())
                                    .onTapGesture { selectedEntry = entry }
                            }
                            .onDelete(perform: deleteEntries)
                        }
                    }
                }
            }
            .navigationTitle("Journal")
            .sheet(item: $selectedEntry) { entry in
                JournalEntryDetailView(entry: entry)
            }
        }
    }

    private var availableTags: [String] {
        Array(Set(entries.flatMap { $0.tags })).sorted()
    }

    private var filteredEntries: [JournalEntry] {
        entries.filter { entry in
            if let selectedMood = selectedMood, entry.mood != selectedMood { return false }
            if showAIOnly && !entry.includeInAI { return false }
            if showOnlyReflection && entry.reflectionPromptCount == 0 { return false }
            if selectedFilter == .written && entry.kind != .written { return false }
            if selectedFilter == .voice && entry.kind != .voice { return false }
            if selectedFilter == .prompted && entry.kind != .prompted { return false }
            if selectedFilter == .favorites && !entry.isFavorite { return false }

            if !selectedTag.isEmpty && !entry.tags.contains(selectedTag) { return false }
            if !searchText.isEmpty && !NaturalLanguageSearch.matches(entry: entry, query: searchText, allEntries: entries) {
                return false
            }
            return true
        }
    }

    private func deleteEntries(at offsets: IndexSet) {
        for index in offsets {
            context.delete(filteredEntries[index])
        }
        try? context.save()
    }
}

struct JournalEntryDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let entry: JournalEntry

    @State private var title: String
    @State private var text: String
    @State private var confirmDeleteAudio = false
    @State private var confirmDeleteTranscript = false

    init(entry: JournalEntry) {
        self.entry = entry
        _title = State(initialValue: entry.title)
        _text = State(initialValue: entry.bodyText)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Title") {
                    TextField("Title", text: $title)
                }
                Section("Body") {
                    TextEditor(text: $text)
                        .frame(minHeight: 240)
                }
                Section("Details") {
                    HStack {
                        Text("Date")
                        Spacer()
                        Text(entry.createdAt.formatted(date: .abbreviated, time: .shortened))
                    }
                    HStack {
                        Text("Mood")
                        Spacer()
                        Text(entry.mood.label)
                    }
                    if entry.kind == .voice {
                        HStack {
                            Text("Type")
                            Spacer()
                            Text("Voice entry")
                        }
                    }
                    if !entry.tags.isEmpty {
                        Text("Tags: \(entry.tags.joined(separator: ", "))")
                    }
                    Text("AI included: \(entry.includeInAI ? "Yes" : "No")")
                        .foregroundStyle(.secondary)
                }
                Section("Support actions") {
                    ShareLink(
                        "Share selected journal entry",
                        item: shareableText,
                        subject: Text("MindHarbor journal entry"),
                        message: Text("Shared entry from MindHarbor")
                    )

                    if entry.kind == .voice && !entry.deletedAudio {
                        Button("Delete audio file", role: .destructive) {
                            confirmDeleteAudio = true
                        }
                    }
                    if entry.transcript != nil {
                        Button("Delete transcript", role: .destructive) {
                            confirmDeleteTranscript = true
                        }
                    }
                }

                Button("Save updates") {
                    entry.title = title
                    entry.bodyText = text
                    try? context.save()
                    dismiss()
                }
                Button("Delete entry", role: .destructive) {
                    context.delete(entry)
                    try? context.save()
                    dismiss()
                }
            }
            .navigationTitle("Entry")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .alert("Delete audio file?", isPresented: $confirmDeleteAudio) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) { deleteAudio() }
            } message: {
                Text("This removes the local audio reference for this entry.")
            }
            .alert("Delete transcript?", isPresented: $confirmDeleteTranscript) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteTranscript()
                }
            } message: {
                Text("This permanently removes the transcript for this entry.")
            }
        }
    }

    private var shareableText: String {
        [
            "MindHarbor journal entry",
            "Date: \(entry.createdAt.formatted(date: .abbreviated, time: .shortened))",
            "Mood: \(entry.mood.label)",
            "Tags: \(entry.tags.joined(separator: ", "))",
            "",
            title.isEmpty ? "" : "Title: \(title)",
            text
        ].joined(separator: "\n")
    }

    private func deleteAudio() {
        entry.deletedAudio = true
        entry.audioFileName = nil
        entry.keepAudio = false
        try? context.save()
    }

    private func deleteTranscript() {
        entry.transcript = nil
        try? context.save()
    }
}
