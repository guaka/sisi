import Dependencies
import Foundation

/// Words that should never appear in notification content. Spam often comes from
/// rotating npubs, so we filter by text instead of author.
enum NotificationBlocklist {
    static let defaultWords = ["airdrop"]
    static let storageKey = "com.verse.nos.settings.notificationBlocklist"

    /// The user's blocked words, or `defaultWords` if they have never edited the list.
    static var words: [String] {
        get {
            @Dependency(\.userDefaults) var userDefaults
            guard let stored = userDefaults.array(forKey: storageKey) as? [String] else {
                return defaultWords
            }
            return stored
        }
        set {
            @Dependency(\.userDefaults) var userDefaults
            userDefaults.set(newValue, forKey: storageKey)
        }
    }

    /// Adds `word` to the blocklist if it is non-empty and not already present.
    static func add(_ word: String) {
        let trimmed = word.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return
        }
        var current = words
        guard !current.contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) else {
            return
        }
        current.append(trimmed)
        words = current
    }

    /// Removes the word at `index` from the persisted list.
    static func remove(at index: Int) {
        var current = words
        guard current.indices.contains(index) else {
            return
        }
        current.remove(at: index)
        words = current
    }

    /// Whether `text` contains any blocked word, ignoring case and diacritics.
    static func containsBlockedWord(_ text: String?) -> Bool {
        containsBlockedWord(text, words: words)
    }

    static func containsBlockedWord(_ text: String?, words: [String]) -> Bool {
        guard let text, !text.isEmpty else {
            return false
        }
        return words.contains { word in
            let trimmed = word.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                return false
            }
            return text.range(of: trimmed, options: [.caseInsensitive, .diacriticInsensitive]) != nil
        }
    }

    /// Predicate that excludes events whose `content` contains any blocked word.
    static func excludingPredicate(words: [String] = NotificationBlocklist.words) -> NSPredicate? {
        let trimmed = words
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard !trimmed.isEmpty else {
            return nil
        }
        let predicates = trimmed.map { word in
            NSPredicate(format: "NOT (content CONTAINS[cd] %@)", word)
        }
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }
}
