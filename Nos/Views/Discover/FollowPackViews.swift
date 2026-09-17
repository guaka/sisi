import Dependencies
import Logger
import SwiftUI

/// Card summarizing a curated follow pack on Discover.
struct FollowPackCard: View {
    let pack: FollowPack
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                Text(pack.title)
                    .font(.clarity(.bold, textStyle: .headline))
                    .foregroundStyle(Color.primaryTxt)
                    .multilineTextAlignment(.leading)

                Text(pack.description)
                    .font(.clarity(.regular, textStyle: .footnote))
                    .foregroundStyle(Color.secondaryTxt)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)

                Text("\(pack.members.count) accounts")
                    .font(.clarity(.medium, textStyle: .caption))
                    .foregroundStyle(Color.secondaryTxt)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.cardBgBottom)
            )
        }
        .buttonStyle(.plain)
    }
}

/// Detail view for a curated pack with Follow all.
struct FollowPackDetailView: View {
    let pack: FollowPack

    @Environment(CurrentUser.self) private var currentUser
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var router: Router
    @Dependency(\.relayService) private var relayService

    @State private var resolvedAuthors: [Author] = []
    @State private var isResolving = true
    @State private var isFollowing = false
    @State private var followStatusMessage: String?
    @State private var subscriptions = [ObjectIdentifier: SubscriptionCancellable]()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ListCircle()

                VStack(spacing: 3) {
                    Text(pack.title)
                        .font(.headline.weight(.bold))
                        .multilineTextAlignment(.center)

                    Text(pack.description)
                        .foregroundStyle(Color.secondaryTxt)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)

                    if isResolving {
                        ProgressView()
                            .padding(.top, 12)
                    } else {
                        Text("\(resolvedAuthors.count) of \(pack.members.count) resolved")
                            .foregroundStyle(Color.secondaryTxt)
                            .font(.footnote)
                            .padding(.top, 8)
                    }
                }

                ActionButton(title: "Follow all") {
                    await followAll()
                }
                .disabled(isResolving || resolvedAuthors.isEmpty || isFollowing)
                .padding(.horizontal, 24)

                if let followStatusMessage {
                    Text(followStatusMessage)
                        .font(.footnote)
                        .foregroundStyle(Color.secondaryTxt)
                }
            }
            .padding(.top, 24)

            LazyVStack {
                ForEach(resolvedAuthors) { author in
                    AuthorObservationView(authorID: author.hexadecimalPublicKey) { observed in
                        AuthorCard(
                            author: observed,
                            avatarOverlayView: { EmptyView() },
                            onTap: { router.push(observed) }
                        )
                        .padding(.horizontal, 13)
                        .padding(.top, 5)
                        .readabilityPadding()
                        .task {
                            subscriptions[observed.id] = await relayService.requestMetadata(
                                for: observed.hexadecimalPublicKey,
                                since: observed.lastUpdatedMetadata
                            )
                        }
                    }
                }
            }
            .padding(.vertical, 12)
        }
        .nosNavigationBar(title: AttributedString(pack.title))
        .background(Color.appBg)
        .task { await resolve() }
    }

    private func resolve() async {
        isResolving = true
        defer { isResolving = false }
        resolvedAuthors = await FollowPackResolver.resolveMembers(
            pack.members,
            relayService: relayService,
            context: viewContext
        )
        try? viewContext.saveIfNeeded()
    }

    private func followAll() async {
        isFollowing = true
        defer { isFollowing = false }
        do {
            try await currentUser.follow(authors: resolvedAuthors)
            followStatusMessage = "Followed \(resolvedAuthors.count) accounts"
        } catch {
            followStatusMessage = "Could not follow everyone"
            Log.optional(error)
        }
    }
}
