import XCTest

final class FederatedProfileURLTests: XCTestCase {

    func testParseMastodonHandle() {
        XCTAssertEqual(
            FederatedProfileURL.parse("@alice@mastodon.social"),
            .mastodon(username: "alice", host: "mastodon.social")
        )
    }

    func testParseMastodonProfileURL() {
        XCTAssertEqual(
            FederatedProfileURL.parse("https://mastodon.social/@alice"),
            .mastodon(username: "alice", host: "mastodon.social")
        )
    }

    func testParseMastodonUsersPath() {
        XCTAssertEqual(
            FederatedProfileURL.parse("https://example.social/users/bob"),
            .mastodon(username: "bob", host: "example.social")
        )
    }

    func testParseBlueskyProfileURL() {
        XCTAssertEqual(
            FederatedProfileURL.parse("https://bsky.app/profile/mkfain.bsky.social"),
            .bluesky(handleOrDID: "mkfain.bsky.social")
        )
    }

    func testParseBlueskyHandle() {
        XCTAssertEqual(
            FederatedProfileURL.parse("alice.bsky.social"),
            .bluesky(handleOrDID: "alice.bsky.social")
        )
        XCTAssertEqual(
            FederatedProfileURL.parse("@alice.bsky.social"),
            .bluesky(handleOrDID: "alice.bsky.social")
        )
    }

    func testParseBlueskyDID() {
        XCTAssertEqual(
            FederatedProfileURL.parse("did:plc:abcdef"),
            .bluesky(handleOrDID: "did:plc:abcdef")
        )
    }

    func testParseNIP05() {
        XCTAssertEqual(
            FederatedProfileURL.parse("bob@example.com"),
            .nip05("bob@example.com")
        )
    }

    func testMostrResolutionUsernames() {
        XCTAssertEqual(
            FederatedProfileURL.resolutionUsername(
                for: .mastodon(username: "alice", host: "mastodon.social")
            ),
            "alice_at_mastodon.social"
        )
        XCTAssertEqual(
            FederatedProfileURL.resolutionUsername(for: .bluesky(handleOrDID: "mkfain.bsky.social")),
            "mkfain.bsky.social_at_bsky.brid.gy"
        )
        XCTAssertTrue(
            FederatedProfileURL.usesMostrBridge(.bluesky(handleOrDID: "x.bsky.social"))
        )
        XCTAssertFalse(
            FederatedProfileURL.usesMostrBridge(.nip05("user@domain.com"))
        )
    }

    func testIgnoresUnrelatedText() {
        XCTAssertNil(FederatedProfileURL.parse("hello world"))
        XCTAssertNil(FederatedProfileURL.parse("npub1abc"))
    }
}
