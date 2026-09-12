import Foundation
import SwiftData

@Model
final class JournalEntry {
    @Attribute(.unique) var id: UUID
    var title: String
    var bodyText: String
    var createdAt: Date
    var kindRaw: Int
    var moodRaw: Int
    var includeInAI: Bool
    var isPrivateNote: Bool
    var isFavorite: Bool
    var tags: [String]
    var transcript: String?
    var audioFileName: String?
    var reflectionPromptCount: Int
    var keepAudio: Bool
    var deletedAudio: Bool

    init(
        title: String = "",
        bodyText: String,
        createdAt: Date = .now,
        kind: JournalEntryKind = .written,
        mood: MoodLevel = .okay,
        includeInAI: Bool = true,
        isPrivateNote: Bool = false,
        isFavorite: Bool = false,
        tags: [String] = [],
        transcript: String? = nil,
        audioFileName: String? = nil,
        reflectionPromptCount: Int = 0,
        keepAudio: Bool = false,
        deletedAudio: Bool = false
    ) {
        self.id = UUID()
        self.title = title
        self.bodyText = bodyText
        self.createdAt = createdAt
        self.kindRaw = kind.rawValue
        self.moodRaw = mood.rawValue
        self.includeInAI = includeInAI
        self.isPrivateNote = isPrivateNote
        self.isFavorite = isFavorite
        self.tags = tags
        self.transcript = transcript
        self.audioFileName = audioFileName
        self.reflectionPromptCount = reflectionPromptCount
        self.keepAudio = keepAudio
        self.deletedAudio = deletedAudio
    }

    var kind: JournalEntryKind { JournalEntryKind(rawValue: kindRaw) ?? .written }
    var mood: MoodLevel { MoodLevel(rawValue: moodRaw) ?? .okay }
    var excerpt: String {
        let trimmed = bodyText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return transcript?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "No content captured yet."
        }
        return String(trimmed.prefix(140))
    }
}

@Model
final class MoodCheckIn {
    @Attribute(.unique) var id: UUID
    var recordedAt: Date
    var moodRaw: Int
    var energy: Int
    var stress: Int
    var sleepQuality: Int
    var focus: Int
    var social: Int
    var tags: [String]

    init(recordedAt: Date = .now, mood: MoodLevel = .okay, energy: Int = 3, stress: Int = 3, sleepQuality: Int = 3, focus: Int = 3, social: Int = 3, tags: [String] = []) {
        self.id = UUID()
        self.recordedAt = recordedAt
        self.moodRaw = mood.rawValue
        self.energy = energy
        self.stress = stress
        self.sleepQuality = sleepQuality
        self.focus = focus
        self.social = social
        self.tags = tags
    }

    var mood: MoodLevel { MoodLevel(rawValue: moodRaw) ?? .okay }
}

@Model
final class CopilotMessage {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var role: String
    var content: String

    init(role: String, content: String, createdAt: Date = .now) {
        self.id = UUID()
        self.createdAt = createdAt
        self.role = role
        self.content = content
    }
}

@Model
final class SupportContact {
    @Attribute(.unique) var id: UUID
    var name: String
    var role: String
    var phone: String
    var messageHandle: String
    var notes: String
    var createdAt: Date

    init(name: String, role: String, phone: String = "", messageHandle: String = "", notes: String = "", createdAt: Date = .now) {
        self.id = UUID()
        self.name = name
        self.role = role
        self.phone = phone
        self.messageHandle = messageHandle
        self.notes = notes
        self.createdAt = createdAt
    }
}

enum JournalEntryKind: Int, Codable, CaseIterable {
    case written = 0
    case voice = 1
    case prompted = 2
    case checkIn = 3
}

enum MoodLevel: Int, Codable, CaseIterable {
    case veryLow = 1
    case low = 2
    case okay = 3
    case good = 4
    case veryGood = 5

    var label: String {
        switch self {
        case .veryLow: return "Very low"
        case .low: return "Low"
        case .okay: return "Okay"
        case .good: return "Good"
        case .veryGood: return "Very good"
        }
    }

    static let scale = [veryLow, low, okay, good, veryGood]
}
