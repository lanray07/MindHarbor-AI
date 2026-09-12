import SwiftUI
import SwiftData

struct MySupportView: View {
    @Environment(\.modelContext) private var context
    @Query private var contacts: [SupportContact]
    @Query(sort: \JournalEntry.createdAt, order: .reverse) private var entries: [JournalEntry]

    @State private var showAdd = false
    @State private var selectedContact: SupportContact?
    @State private var shareContact: SupportContact?
    @State private var selectedEntryIDs = Set<UUID>()

    var body: some View {
        NavigationStack {
            List {
                Section("Trusted support") {
                    if contacts.isEmpty {
                        Text("Add trusted contacts for support when you want help sharing outside MindHarbor.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(contacts, id: \.id) { contact in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(contact.name).font(.headline)
                                Text(contact.role).foregroundStyle(.secondary)
                                if let phoneURL = dialURL(for: contact.phone) {
                                    Link("Call \(contact.phone)", destination: phoneURL)
                                }
                                if let messageURL = messageURL(for: contact.messageHandle) {
                                    Link("Message", destination: messageURL)
                                }
                                Button("Share selected journal") {
                                    shareContact = contact
                                    selectedEntryIDs.removeAll()
                                }
                                if !contact.notes.isEmpty {
                                    Text(contact.notes)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture { selectedContact = contact }
                        }
                    }
                }
            }
            .navigationTitle("My Support")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") { showAdd = true }
                }
            }
            .sheet(isPresented: $showAdd) {
                AddSupportContactView()
            }
            .sheet(item: $selectedContact) { contact in
                AddSupportContactView(contact: contact)
            }
            .sheet(item: $shareContact) { contact in
                ShareSelectedJournalSheet(
                    contactName: contact.name,
                    entries: entries,
                    selectedEntryIDs: $selectedEntryIDs,
                    onDone: { shareContact = nil }
                )
            }
        }
    }
}

private struct ShareSelectedJournalSheet: View {
    let contactName: String
    let entries: [JournalEntry]
    @Binding var selectedEntryIDs: Set<UUID>
    let onDone: () -> Void

    private var selectedEntries: [JournalEntry] {
        entries.filter { selectedEntryIDs.contains($0.id) }
    }

    private var shareText: String {
        let body = selectedEntries.map { entry in
            [
                "Date: \(entry.createdAt.formatted(date: .abbreviated, time: .shortened))",
                "Mood: \(entry.mood.label)",
                entry.title.isEmpty ? "" : "Title: \(entry.title)",
                entry.excerpt
            ].joined(separator: "\n")
        }.joined(separator: "\n\n---\n\n")

        return [
            "MindHarbor journal export for \(contactName)",
            "Generated: \(Date().formatted())",
            "",
            body.isEmpty ? "No entries selected." : body
        ].joined(separator: "\n")
    }

    var body: some View {
        NavigationStack {
            List {
                if entries.isEmpty {
                    Text("No journal entries to share yet.")
                        .foregroundStyle(.secondary)
                } else {
                    Section("Select entries to share") {
                        Button("Select all visible") {
                            selectedEntryIDs = Set(entries.map { $0.id })
                        }
                        Button("Clear selection") {
                            selectedEntryIDs.removeAll()
                        }
                    }
                    Section {
                        ForEach(entries) { entry in
                            Toggle(isOn: Binding(
                                get: { selectedEntryIDs.contains(entry.id) },
                                set: { isSelected in
                                    if isSelected { selectedEntryIDs.insert(entry.id) }
                                    else { selectedEntryIDs.remove(entry.id) }
                                }
                            )) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(entry.title.isEmpty ? "Untitled entry" : entry.title)
                                        .font(.headline)
                                    Text(entry.createdAt.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(entry.excerpt)
                                        .font(.body)
                                }
                            }
                        }
                    }
                }

                if !selectedEntries.isEmpty {
                    ShareLink("Share selected entries", item: shareText)
                        .disabled(selectedEntries.isEmpty)
                }
            }
            .navigationTitle("Share with \(contactName)")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { onDone() }
                }
            }
        }
    }
}

private struct AddSupportContactView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var role: String = ""
    @State private var phone: String = ""
    @State private var messageHandle: String = ""
    @State private var notes: String = ""

    let contact: SupportContact?

    init(contact: SupportContact? = nil) {
        self.contact = contact
        if let contact = contact {
            _name = State(initialValue: contact.name)
            _role = State(initialValue: contact.role)
            _phone = State(initialValue: contact.phone)
            _messageHandle = State(initialValue: contact.messageHandle)
            _notes = State(initialValue: contact.notes)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
                TextField("Role", text: $role)
                TextField("Phone", text: $phone)
                    .keyboardType(.phonePad)
                TextField("Message handle (phone/email)", text: $messageHandle)
                TextField("Notes", text: $notes, axis: .vertical)

                Button(contact == nil ? "Save contact" : "Update contact") {
                    if let contact {
                        contact.name = name
                        contact.role = role
                        contact.phone = phone
                        contact.messageHandle = messageHandle
                        contact.notes = notes
                    } else {
                        let newContact = SupportContact(name: name, role: role, phone: phone, messageHandle: messageHandle, notes: notes)
                        context.insert(newContact)
                    }
                    try? context.save()
                    dismiss()
                }
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                if let contact {
                    Button("Delete", role: .destructive) {
                        context.delete(contact)
                        try? context.save()
                        dismiss()
                    }
                }
            }
            .navigationTitle(contact == nil ? "Add support contact" : "Edit support contact")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
            }
        }
    }
}

private func dialURL(for value: String) -> URL? {
    let digits = value.filter { $0.isWholeNumber || $0 == "+" }
    guard !digits.isEmpty else { return nil }
    return URL(string: "tel:\(digits)")
}

private func messageURL(for value: String) -> URL? {
    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return nil }
    if trimmed.contains("@") {
        let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? trimmed
        return URL(string: "mailto:\(encoded)")
    }
    let digits = trimmed.filter { $0.isWholeNumber || $0 == "+" }
    guard !digits.isEmpty else { return nil }
    return URL(string: "sms:\(digits)")
}
