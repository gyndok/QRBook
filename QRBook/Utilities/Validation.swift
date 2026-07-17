import Foundation

struct Validation {
    static func validateTitle(_ title: String) -> String? {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "Title is required" }
        if trimmed.count > 200 { return "Title must be less than 200 characters" }
        return nil
    }

    static func validateURL(_ url: String) -> String? {
        let trimmed = url.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "URL is required" }
        if trimmed.count > 2048 { return "URL must be less than 2048 characters" }
        let normalized = normalizeURL(trimmed)
        guard URL(string: normalized) != nil else {
            return "Please enter a valid URL"
        }
        return nil
    }

    /// Adds https:// if no scheme is present. Existing schemes of any case
    /// (HTTP://, mailto:, tel:) are left untouched; a host:port like
    /// "example.com:8080" is not mistaken for a scheme.
    static func normalizeURL(_ url: String) -> String {
        let trimmed = url.trimmingCharacters(in: .whitespacesAndNewlines)
        if let match = trimmed.range(of: "^[A-Za-z][A-Za-z0-9+.-]*:", options: .regularExpression) {
            let firstSegment = trimmed[match.upperBound...].prefix(while: { $0 != "/" })
            let looksLikePort = !firstSegment.isEmpty && firstSegment.allSatisfy(\.isNumber)
            if !looksLikePort {
                return trimmed
            }
        }
        return "https://\(trimmed)"
    }

    static func validateText(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "Text content is required" }
        if trimmed.count > 4296 { return "Text must be less than 4296 characters" }
        return nil
    }

    static func validateTag(_ tag: String) -> String? {
        let trimmed = tag.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "Tag cannot be empty" }
        if trimmed.count > 50 { return "Tag must be less than 50 characters" }
        let allowed = CharacterSet.alphanumerics.union(.whitespaces).union(CharacterSet(charactersIn: "-_"))
        if trimmed.unicodeScalars.contains(where: { !allowed.contains($0) }) {
            return "Tags can only contain letters, numbers, spaces, hyphens, and underscores"
        }
        return nil
    }

    static func validateRequired(_ value: String, fieldName: String) -> String? {
        if value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "\(fieldName) is required"
        }
        return nil
    }
}
