import XCTest

final class FollowPackCatalogTests: XCTestCase {

    func testDocsPacksJSONDecodes() throws {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // Service or Models
            .deletingLastPathComponent() // NosTests
            .deletingLastPathComponent() // repo root
            .appendingPathComponent("docs/packs.json")

        let packs = try XCTUnwrap(FollowPackCatalog.load(from: url))
        XCTAssertGreaterThanOrEqual(packs.count, 2)
        XCTAssertTrue(packs.contains(where: { $0.id == "old-school-media" }))
        XCTAssertTrue(packs.contains(where: { $0.id == "stringer-journalists" }))
        XCTAssertFalse(packs[0].members.isEmpty)
    }
}
