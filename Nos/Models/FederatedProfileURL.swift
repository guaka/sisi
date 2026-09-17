import Foundation

/// A profile identity on Mastodon, Bluesky, or Nostr that can be resolved to a Nostr pubkey.
enum FederatedProfileIdentity: Equatable {
    /// A Mastodon / ActivityPub account, e.g. `@alice@mastodon.social`.
    case mastodon(username: String, host: String)
    /// A Bluesky handle (e.g. `alice.bsky.social`) or DID, bridged via Bridgy Fed + Mostr.
    case bluesky(handleOrDID: String)
    /// A Nostr NIP-05 identifier (`user@domain`).
    case nip05(String)
}

/// Parses Mastodon, Bluesky, and related profile URLs / handles into identities we can resolve via Mostr.
enum FederatedProfileURL {

    /// Parses a search query or pasted URL into a federated identity, if recognized.
    /// - Parameter query: Raw user input (may include scheme, path, or `@` handles). Case is preserved for parsing.
    /// - Returns: A recognizable identity, or `nil` if this is not a federated profile reference.
    static func parse(_ query: String) -> FederatedProfileIdentity? {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let bluesky = parseBluesky(trimmed) {
            return bluesky
        }
        if let mastodon = parseMastodon(trimmed) {
            return mastodon
        }
        if let nip05 = parseNIP05(trimmed) {
            return nip05
        }
        return nil
    }

    /// Builds the Mostr / NIP-05 username used to look up a Nostr pubkey.
    /// - Mastodon `@user@host` → `user_at_host` (fetched from mostr.pub)
    /// - Bluesky handle → `handle_at_bsky.brid.gy` (fetched from mostr.pub)
    /// - NIP-05 → returned as-is for standard NIP-05 fetch
    static func resolutionUsername(for identity: FederatedProfileIdentity) -> String {
        switch identity {
        case .mastodon(let username, let host):
            return "\(username)_at_\(host)"
        case .bluesky(let handleOrDID):
            let normalized = handleOrDID
                .trimmingCharacters(in: CharacterSet(charactersIn: "@"))
                .lowercased()
            return "\(normalized)_at_bsky.brid.gy"
        case .nip05(let identifier):
            return identifier
        }
    }

    /// Whether the identity should be resolved through mostr.pub rather than the account's own domain.
    static func usesMostrBridge(_ identity: FederatedProfileIdentity) -> Bool {
        switch identity {
        case .mastodon, .bluesky:
            return true
        case .nip05:
            return false
        }
    }

    // MARK: - Private

    private static func parseBluesky(_ input: String) -> FederatedProfileIdentity? {
        let lower = input.lowercased()

        if lower.hasPrefix("https://bsky.app/") || lower.hasPrefix("http://bsky.app/") {
            guard let url = URL(string: input),
                let host = url.host?.lowercased(),
                host == "bsky.app" || host.hasSuffix(".bsky.app") else {
                return nil
            }
            let parts = url.pathComponents.filter { $0 != "/" }
            guard parts.count >= 2, parts[0].lowercased() == "profile" else { return nil }
            let handle = parts[1]
            guard !handle.isEmpty else { return nil }
            return .bluesky(handleOrDID: handle)
        }

        // Bare Bluesky handles: alice.bsky.social or @alice.bsky.social
        let withoutAt = input.hasPrefix("@") ? String(input.dropFirst()) : input
        if withoutAt.lowercased().hasSuffix(".bsky.social") || withoutAt.lowercased().hasPrefix("did:") {
            // Avoid treating Mastodon @user@host as Bluesky
            guard withoutAt.filter({ $0 == "@" }).isEmpty else { return nil }
            return .bluesky(handleOrDID: withoutAt)
        }

        return nil
    }

    private static func parseMastodon(_ input: String) -> FederatedProfileIdentity? {
        // @user@host
        if input.filter({ $0 == "@" }).count == 2 {
            let withoutLeading = input.hasPrefix("@") ? String(input.dropFirst()) : input
            let parts = withoutLeading.split(separator: "@", maxSplits: 1).map(String.init)
            guard parts.count == 2,
                !parts[0].isEmpty,
                !parts[1].isEmpty,
                parts[1].contains(".") else {
                return nil
            }
            return .mastodon(username: parts[0], host: parts[1].lowercased())
        }

        guard let url = URL(string: input),
            let host = url.host,
            let scheme = url.scheme?.lowercased(),
            scheme == "http" || scheme == "https" else {
            return nil
        }

        // Skip Bluesky URLs (handled elsewhere)
        if host.lowercased() == "bsky.app" || host.lowercased().hasSuffix(".bsky.app") {
            return nil
        }

        let parts = url.pathComponents.filter { $0 != "/" }
        guard !parts.isEmpty else { return nil }

        // /@username or /@username/...
        if parts[0].hasPrefix("@") {
            let username = String(parts[0].dropFirst())
            guard !username.isEmpty else { return nil }
            return .mastodon(username: username, host: host.lowercased())
        }

        // /users/username
        if parts.count >= 2, parts[0].lowercased() == "users" {
            let username = parts[1]
            guard !username.isEmpty else { return nil }
            return .mastodon(username: username, host: host.lowercased())
        }

        return nil
    }

    private static func parseNIP05(_ input: String) -> FederatedProfileIdentity? {
        // Single @ → NIP-05 (user@domain). Leading @_@domain is also NIP-05.
        guard input.filter({ $0 == "@" }).count == 1 else { return nil }
        let normalized = input.hasPrefix("@") ? String(input.dropFirst()) : input
        let parts = normalized.split(separator: "@", maxSplits: 1).map(String.init)
        guard parts.count == 2, !parts[0].isEmpty, parts[1].contains(".") else { return nil }
        // Bluesky-style bare handles already handled; don't treat foo.bsky.social as NIP-05 without local part.
        return .nip05(normalized)
    }
}
