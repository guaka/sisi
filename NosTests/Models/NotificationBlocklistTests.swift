import CoreData
import Dependencies
import XCTest

final class NotificationBlocklistTests: CoreDataTestCase {

    @MainActor
    func testDefaultIncludesAirdrop() {
        withIsolatedDefaults {
            XCTAssertEqual(NotificationBlocklist.words, ["airdrop"])
        }
    }

    @MainActor
    func testContainsBlockedWordIsCaseInsensitive() {
        withIsolatedDefaults {
            XCTAssertTrue(NotificationBlocklist.containsBlockedWord("Free AIRDROP tokens"))
            XCTAssertTrue(NotificationBlocklist.containsBlockedWord("claim your airdrop now"))
            XCTAssertFalse(NotificationBlocklist.containsBlockedWord("hello from a friend"))
            XCTAssertFalse(NotificationBlocklist.containsBlockedWord(nil))
        }
    }

    @MainActor
    func testAddAndRemoveWords() {
        withIsolatedDefaults {
            NotificationBlocklist.add("  Giveaway  ")
            XCTAssertEqual(NotificationBlocklist.words, ["airdrop", "Giveaway"])

            NotificationBlocklist.add("airdrop")
            XCTAssertEqual(NotificationBlocklist.words, ["airdrop", "Giveaway"])

            NotificationBlocklist.remove(at: 0)
            XCTAssertEqual(NotificationBlocklist.words, ["Giveaway"])
            XCTAssertFalse(NotificationBlocklist.containsBlockedWord("airdrop spam"))
        }
    }

    @MainActor
    func testEmptyPersistedListDoesNotRestoreDefaults() {
        withIsolatedDefaults {
            NotificationBlocklist.words = []
            XCTAssertEqual(NotificationBlocklist.words, [])
            XCTAssertFalse(NotificationBlocklist.containsBlockedWord("airdrop"))
        }
    }

    @MainActor
    func testFetchRequestHidesBlockedMentions() throws {
        try withIsolatedDefaults {
            let bob = try Author.findOrCreate(by: KeyFixture.bob.publicKeyHex, context: testContext)
            let aliceHex = KeyFixture.pubKeyHex

            let spam = try EventFixture.build(
                in: testContext,
                publicKey: aliceHex,
                content: "Claim your airdrop at https://scam.example",
                createdAt: Date(timeIntervalSince1970: 100)
            )
            spam.kind = EventKind.text.rawValue
            attachMention(of: bob, to: spam)

            let genuine = try EventFixture.build(
                in: testContext,
                publicKey: aliceHex,
                content: "Hey bob, nice note",
                createdAt: Date(timeIntervalSince1970: 200)
            )
            genuine.kind = EventKind.text.rawValue
            attachMention(of: bob, to: genuine)

            try testContext.save()

            let events = try testContext.fetch(Event.all(notifying: bob))
            XCTAssertEqual(events.map(\.content), ["Hey bob, nice note"])
        }
    }

    // MARK: - Helpers

    @MainActor
    private func attachMention(of user: Author, to event: Event) {
        let reference = AuthorReference(context: testContext)
        reference.pubkey = user.hexadecimalPublicKey
        event.authorReferences = NSMutableOrderedSet(array: [reference])
    }

    @MainActor
    private func withIsolatedDefaults(_ operation: () throws -> Void) rethrows {
        let suiteName = "NotificationBlocklistTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        try withDependencies {
            $0.userDefaults = defaults
        } operation: {
            try operation()
        }
        defaults.removePersistentDomain(forName: suiteName)
    }
}
