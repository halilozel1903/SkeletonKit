import SkeletonKit
import SwiftUI

/// A profile with recent posts that shows skeletons while it "loads".
struct ProfileFeedView: View {
    /// Keeps the skeleton on screen forever (screenshot scene).
    let staysLoading: Bool
    /// Freezes the shimmer mid-sweep (screenshot scenes).
    let isFrozen: Bool

    @State private var isLoading = true
    @State private var hasLoaded = false

    private let profile = Profile.sample
    private let posts = Post.samples

    init(staysLoading: Bool = false, isFrozen: Bool = false) {
        self.staysLoading = staysLoading
        self.isFrozen = isFrozen
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ProfileHeader(profile: profile, isLoading: isLoading)

                    Text("Recent posts")
                        .font(.title3.weight(.semibold))
                        .padding(.horizontal, 4)
                        .padding(.top, 8)

                    ForEach(posts) { post in
                        PostCard(post: post, isLoading: isLoading)
                    }
                }
                .padding(16)
                .frame(maxWidth: 620)
                .frame(maxWidth: .infinity)
            }
            .background(Color.screenBackground)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await load() }
                    } label: {
                        Label("Reload", systemImage: "arrow.clockwise")
                    }
                    .disabled(isLoading)
                }
            }
            .refreshable { await load() }
        }
        .skeletonAppearance(SkeletonAppearance.default.frozen(if: isFrozen))
        .task {
            guard !staysLoading, !hasLoaded else { return }
            hasLoaded = true
            await load()
        }
    }

    /// Pretends to fetch the profile from a server.
    private func load() async {
        guard !staysLoading else { return }
        isLoading = true
        try? await Task.sleep(for: .seconds(2.2))
        withAnimation(.easeInOut(duration: 0.35)) {
            isLoading = false
        }
    }
}

private struct ProfileHeader: View {
    let profile: Profile
    let isLoading: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // The cover is cached artwork, so it shows right away.
            CoverArt()
                .frame(height: 118)

            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .bottom) {
                    Avatar(initials: profile.initials, colors: [.orange, .pink], size: 84)
                        .skeleton(isLoading)
                        .padding(4)
                        .background(Circle().fill(Color.cardBackground))
                    Spacer()
                    Button("Follow") {}
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.capsule)
                        .skeletonFill(in: Capsule())
                        .skeleton(isLoading)
                        .padding(.bottom, 6)
                }
                .padding(.top, -46)

                VStack(alignment: .leading, spacing: 4) {
                    Text(profile.name)
                        .font(.title2.bold())
                    Text("\(profile.handle) · \(profile.role)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .skeleton(isLoading)

                Text(profile.bio)
                    .font(.callout)
                    .fixedSize(horizontal: false, vertical: true)
                    .skeleton(isLoading)

                HStack(spacing: 0) {
                    Stat(value: profile.posts, label: "Posts")
                    Stat(value: profile.followers, label: "Followers")
                    Stat(value: profile.following, label: "Following")
                }
                .skeleton(isLoading)
                .padding(.top, 4)
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 20)
        }
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

private struct Stat: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline.monospacedDigit())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct PostCard: View {
    let post: Post
    let isLoading: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Avatar(initials: post.initials, colors: post.avatarColors, size: 40)
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.author)
                        .font(.subheadline.weight(.semibold))
                    Text(post.time)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "ellipsis")
                    .foregroundStyle(.secondary)
            }

            Text(post.text)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)

            if let photo = post.photo {
                PhotoTile(photo: photo)
                    .frame(height: 190)
            }

            HStack(spacing: 20) {
                Label(post.likes, systemImage: "heart")
                Label(post.comments, systemImage: "bubble.right")
                Spacer()
                Image(systemName: "square.and.arrow.up")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .skeleton(isLoading)
        .padding(16)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

/// A gradient avatar with initials. Redaction would leave the gradient alone,
/// so it is marked with `skeletonFill(in:)`.
struct Avatar: View {
    let initials: String
    let colors: [Color]
    let size: CGFloat

    var body: some View {
        Circle()
            .fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay {
                Text(initials)
                    .font(.system(size: size * 0.36, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .frame(width: size, height: size)
            .skeletonFill(in: Circle())
    }
}

private struct PhotoTile: View {
    let photo: Post.Photo

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 18, style: .continuous)
        shape
            .fill(LinearGradient(colors: photo.colors, startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay {
                Image(systemName: photo.symbol)
                    .font(.system(size: 64))
                    .foregroundStyle(.white.opacity(0.9))
                    .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
            }
            .overlay(alignment: .bottomLeading) {
                Label(photo.caption, systemImage: "mappin.and.ellipse")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(12)
            }
            .skeletonFill(in: shape)
    }
}

/// Soft abstract artwork for the profile cover.
private struct CoverArt: View {
    var body: some View {
        LinearGradient(colors: [.indigo, .purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
            .overlay(alignment: .topTrailing) {
                Circle()
                    .fill(RadialGradient(colors: [.orange.opacity(0.85), .clear], center: .center, startRadius: 0, endRadius: 110))
                    .frame(width: 220, height: 220)
                    .offset(x: 50, y: -70)
            }
            .overlay(alignment: .bottomLeading) {
                Circle()
                    .fill(RadialGradient(colors: [.teal.opacity(0.7), .clear], center: .center, startRadius: 0, endRadius: 120))
                    .frame(width: 240, height: 240)
                    .offset(x: -60, y: 110)
            }
            .clipped()
    }
}

#Preview("Loading") {
    ProfileFeedView(staysLoading: true, isFrozen: false)
}

#Preview("Loaded") {
    ProfileFeedView(staysLoading: false, isFrozen: false)
}
