import Foundation

/// A single member of a curated follow pack.
struct FollowPackMember: Codable, Identifiable, Hashable {
    var id: String { identifier }
    let name: String
    /// npub, Mastodon handle (`@user@host`), Bluesky URL/handle, or NIP-05.
    let identifier: String
}

/// A curated follow pack from `packs.json` (GitHub Pages + app bundle).
struct FollowPack: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let description: String
    let naddr: String?
    let members: [FollowPackMember]
}

struct FollowPackCatalogFile: Codable {
    let packs: [FollowPack]
}

/// Loads the shared follow-pack catalog bundled with the app (same file as `docs/packs.json`).
enum FollowPackCatalog {
    static let pagesURL = URL(string: "https://guaka.github.io/sisi/")!

    static func loadBundled() -> [FollowPack] {
        let candidates = [
            Bundle.main.url(forResource: "packs", withExtension: "json"),
            Bundle.main.url(forResource: "packs", withExtension: "json", subdirectory: "docs")
        ]
        for url in candidates.compactMap({ $0 }) {
            if let packs = load(from: url) {
                return packs
            }
        }
        return []
    }

    static func load(from url: URL) -> [FollowPack]? {
        guard let data = try? Data(contentsOf: url),
            let file = try? JSONDecoder().decode(FollowPackCatalogFile.self, from: data) else {
            return nil
        }
        return file.packs
    }
}
