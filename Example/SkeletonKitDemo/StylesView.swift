import SkeletonKit
import SwiftUI

/// Every appearance preset side by side.
struct StylesView: View {
    /// Freezes the shimmer mid-sweep (screenshot scenes).
    var isFrozen = false

    private var indigo: SkeletonAppearance {
        SkeletonAppearance(
            fill: Color.indigo.opacity(0.2),
            tint: .indigo,
            cornerRadius: 10,
            shimmer: ShimmerConfiguration(angle: 60, minimumOpacity: 0.35).speed(1.3)
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    Demo(".default", detail: "Neutral, clear sweep") {
                        Card {
                            SkeletonList(count: 2, spacing: 18)
                            SkeletonShape.rectangle(height: 96)
                        }
                    }
                    .skeletonAppearance(SkeletonAppearance.default.frozen(if: isFrozen))

                    Demo(".subtle", detail: "Softer and slower") {
                        Card {
                            SkeletonList(count: 2, spacing: 18, avatar: false, lines: 3)
                        }
                    }
                    .skeletonAppearance(SkeletonAppearance.subtle.frozen(if: isFrozen))

                    Demo(".glass", detail: "Material on iOS 17 and 18") {
                        VStack(alignment: .leading, spacing: 18) {
                            SkeletonRow(avatarDiameter: 48, lines: 2, seed: 7)
                            SkeletonShape.rectangle(height: 86)
                            HStack(spacing: 10) {
                                SkeletonShape.capsule(width: 84)
                                SkeletonShape.capsule(width: 64)
                                Spacer()
                            }
                        }
                        .padding(20)
                        .background(
                            LinearGradient(
                                colors: [.indigo, .purple, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
                        )
                    }
                    .skeletonAppearance(SkeletonAppearance.glass.frozen(if: isFrozen))

                    Demo("Any view", detail: ".skeleton(true)") {
                        Card {
                            ArticleRow()
                                .skeleton(true, appearance: indigo.frozen(if: isFrozen))
                        }
                    }

                    Demo("Shapes", detail: "SkeletonShape") {
                        Card {
                            HStack(spacing: 14) {
                                SkeletonShape.circle(diameter: 56)
                                SkeletonShape.rectangle(width: 56, height: 56, cornerRadius: 14)
                                SkeletonShape.capsule(width: 96, height: 30)
                                Spacer(minLength: 0)
                            }
                            SkeletonShape.text(lines: 3, seed: "shapes")
                        }
                    }
                    .skeletonAppearance(SkeletonAppearance.default.frozen(if: isFrozen))
                }
                .padding(20)
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }
            .background(Color.screenBackground)
            .navigationTitle("Styles")
        }
    }
}

/// A real view: `.skeleton` turns its text and symbol into tinted bars.
private struct ArticleRow: View {
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "tram.fill")
                .font(.title)
                .frame(width: 52, height: 52)
            VStack(alignment: .leading, spacing: 6) {
                Text("A weekend in Lisbon")
                    .font(.headline)
                Text("Tram 28, pastel de nata and sunsets over the Tagus river.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text("6 min read")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

private struct Card<Content: View>: View {
    @ViewBuilder var content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            content
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

private struct Demo<Content: View>: View {
    let title: String
    let detail: String
    @ViewBuilder var content: Content

    init(_ title: String, detail: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.detail = detail
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(title).font(.headline.monospaced())
                Spacer()
                Text(detail).font(.footnote).foregroundStyle(.secondary)
            }
            content
        }
    }
}

#Preview {
    StylesView()
}
