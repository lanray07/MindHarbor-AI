import Foundation

private extension String {
    var digitsOnly: String { filter(\.isNumber) }
}

struct SafetyContact: Identifiable {
    let id = UUID()
    let title: String
    let phone: String
    let note: String?
}

struct SafetyEngine {
    private static let crisisKeywords: [String] = [
        "suicide", "kill myself", "kill me", "end it", "want to die", "i want to die", "self harm", "self-harm",
        "no point living", "not worth living", "better off without me", "can't go on"
    ]

    static func detectCrisis(text: String) -> Bool {
        let normalized = text.lowercased()
        return crisisKeywords.contains { normalized.contains($0) }
    }

    static func riskScore(text: String) -> Int {
        let normalized = text.lowercased()
        let directHits = crisisKeywords.filter { normalized.contains($0) }.count
        let urgentSignals = ["emergency", "hurting myself", "hurt myself", "plan", "plan to", "crisis", "i don't want to be here"]
            .filter { normalized.contains($0) }.count
        return directHits + urgentSignals
    }

    static func safetyMessage(for text: String, regionCode: String?) -> String {
        if !detectCrisis(text: text) {
            return ""
        }

        let region = regionCode?.uppercased() ?? Locale.current.regionCode ?? "US"
        let localLine = supportLine(for: region)
        return """
        I’m glad you shared this. I’m not able to provide crisis support, but I can help you get immediate human support now.
        Immediate help: \(localLine)
        You can also call your local emergency services.
        """
    }

    static func supportMessage() -> String {
        supportLine(for: Locale.current.regionCode ?? "US")
    }

    static func isCrisisText(_ text: String) -> Bool {
        detectCrisis(text: text)
    }

    static func crisisSupportPrompt() -> String {
        "If this feels urgent, use crisis support now: \(supportMessage())"
    }

    static func supportDialURL(for regionCode: String?) -> URL? {
        supportContacts(for: regionCode)
            .compactMap { supportDialURL(for: $0.phone) }
            .first
    }

    static func supportDialURL(for phone: String) -> URL? {
        let digits = phone.filter { $0.isNumber || $0 == "+" }
        guard !digits.isEmpty else { return nil }
        return URL(string: "tel:\(digits)")
    }

    static func supportContacts(for regionCode: String?) -> [SafetyContact] {
        let region = regionCode?.uppercased() ?? Locale.current.regionCode ?? "US"
        switch region {
        case "US", "CA":
            return [
                SafetyContact(title: "Call 988 (US/Canada)", phone: "988", note: "Immediate mental-health line"),
                SafetyContact(title: "Call emergency services", phone: "911", note: "For immediate danger")
            ]
        case "GB", "IE":
            return [
                SafetyContact(title: "Call Samaritans", phone: "116123", note: "United Kingdom/Ireland, 24/7"),
                SafetyContact(title: "Call emergency services", phone: "999", note: "For immediate danger")
            ]
        case "AU":
            return [
                SafetyContact(title: "Call Lifeline", phone: "131114", note: "Australia"),
                SafetyContact(title: "Call emergency services", phone: "000", note: "For immediate danger")
            ]
        case "NZ":
            return [
                SafetyContact(title: "Call 1737", phone: "1737", note: "New Zealand crisis support"),
                SafetyContact(title: "Call emergency services", phone: "111", note: "For immediate danger")
            ]
        case "IN":
            return [
                SafetyContact(title: "Call Tele-MANAS", phone: "14416", note: "India"),
                SafetyContact(title: "Call emergency services", phone: "112", note: "For immediate danger")
            ]
        case "ZA":
            return [
                SafetyContact(title: "Call 08000567567", phone: "08000567567", note: "South Africa crisis support"),
                SafetyContact(title: "Call emergency services", phone: "10111", note: "For immediate danger")
            ]
        default:
            return [
                SafetyContact(title: "Call local emergency services", phone: "112", note: "For immediate danger")
            ]
        }
    }

    private static func supportLine(for region: String) -> String {
        switch region {
        case "US", "CA":
            "US/Canada: If you are in immediate danger, call 988 or call emergency services (911)."
        case "GB", "IE":
            "United Kingdom/Ireland: Samaritans 116 123 (free, 24/7) and emergency 999/112."
        case "AU":
            "Australia: Lifeline 13 11 14 and emergency 000."
        case "NZ":
            "New Zealand: 1737 (Suicide Crisis), 111 for emergency."
        case "IN":
            "India: Tele-MANAS 14416 and emergency 112."
        case "ZA":
            "South Africa: 08000 567 567 and emergency 10111/112."
        default:
            "If this feels urgent, call your local emergency number and seek immediate support from crisis services available in your country."
        }
    }
}
