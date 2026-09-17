import Foundation
import CoreData
import Dependencies
import Logger

/// Resolves follow-pack members (and optional naddr packs) into ``Author`` records.
@MainActor
enum FollowPackResolver {

    /// Resolves catalog members to authors. Skips identifiers that cannot be resolved.
    static func resolveMembers(
        _ members: [FollowPackMember],
        relayService: RelayService,
        context: NSManagedObjectContext
    ) async -> [Author] {
        var authors: [Author] = []
        var seen = Set<RawAuthorID>()

        for member in members {
            if let author = await resolveIdentifier(
                member.identifier,
                relayService: relayService,
                context: context
            ),
            let hex = author.hexadecimalPublicKey,
            !seen.contains(hex) {
                seen.insert(hex)
                authors.append(author)
            }
        }
        return authors
    }

    static func resolveIdentifier(
        _ identifier: String,
        relayService: RelayService,
        context: NSManagedObjectContext
    ) async -> Author? {
        let trimmed = identifier.trimmingCharacters(in: .whitespacesAndNewlines)

        if let publicKey = PublicKey.build(npubOrHex: trimmed),
            let author = try? Author.findOrCreate(by: publicKey.hex, context: context) {
            return author
        }

        if let identity = FederatedProfileURL.parse(trimmed),
            let hex = try? await relayService.fetchPublicKey(for: identity),
            let author = try? Author.findOrCreate(by: hex, context: context) {
            return author
        }

        if trimmed.contains("@"),
            let hex = await relayService.retrievePublicKeyFromUsername(trimmed),
            let author = try? Author.findOrCreate(by: hex, context: context) {
            return author
        }

        Log.info("Could not resolve follow-pack member: \(trimmed)")
        return nil
    }
}
