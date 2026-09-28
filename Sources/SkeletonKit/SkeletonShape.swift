import SwiftUI

/// A shimmering placeholder primitive: text lines, a circle, a rounded rectangle or a capsule.
///
/// Use these to build a placeholder layout by hand, for example while no model exists yet:
///
/// ```swift
/// HStack(alignment: .top, spacing: 12) {
///     SkeletonShape.circle(diameter: 44)
///     SkeletonShape.text(lines: 3, seed: "welcome")
/// }
/// SkeletonShape.rectangle(height: 180)
/// ```
///
/// Text lines get ragged, deterministic widths from ``SkeletonLineWidths``: the same seed always
/// draws the same paragraph. Shapes read the ``EnvironmentValues/skeletonAppearance``, are hidden
/// from VoiceOver and announce "Loading" once.
public struct SkeletonShape: View {
    enum Kind: Hashable {
        case lines(count: Int, seed: UInt64, lineHeight: CGFloat, spacing: CGFloat)
        case circle(diameter: CGFloat)
        case rectangle(width: CGFloat?, height: CGFloat?, cornerRadius: CGFloat?)
        case capsule(width: CGFloat?, height: CGFloat)
    }

    let kind: Kind

    @Environment(\.skeletonAppearance) private var appearance
    @Environment(\.colorScheme) private var colorScheme

    init(kind: Kind) {
        self.kind = kind
    }

    // MARK: - Factories

    /// A paragraph of placeholder lines with ragged widths and a short last line.
    ///
    /// - Parameters:
    ///   - lines: The number of lines, at least `1`.
    ///   - seed: Picks the widths; the same seed always draws the same paragraph.
    ///   - lineHeight: The height of each bar. `12` matches body text well.
    ///   - spacing: The gap between bars.
    public static func text(lines: Int = 3, seed: UInt64 = 0, lineHeight: CGFloat = 12, spacing: CGFloat = 9) -> SkeletonShape {
        SkeletonShape(kind: .lines(
            count: max(lines, 1),
            seed: seed,
            lineHeight: max(lineHeight, 1),
            spacing: max(spacing, 0)
        ))
    }

    /// A paragraph of placeholder lines whose widths are picked by a string, such as an item's identifier.
    public static func text(lines: Int = 3, seed: String, lineHeight: CGFloat = 12, spacing: CGFloat = 9) -> SkeletonShape {
        text(lines: lines, seed: SkeletonLineWidths.seed(seed), lineHeight: lineHeight, spacing: spacing)
    }

    /// A circle, for avatars and icons.
    public static func circle(diameter: CGFloat = 44) -> SkeletonShape {
        SkeletonShape(kind: .circle(diameter: max(diameter, 0)))
    }

    /// A rounded rectangle, for photos, cards and buttons. A `nil` width fills the available width.
    ///
    /// - Parameter cornerRadius: `nil` uses the appearance's corner radius.
    public static func rectangle(width: CGFloat? = nil, height: CGFloat? = 120, cornerRadius: CGFloat? = nil) -> SkeletonShape {
        SkeletonShape(kind: .rectangle(
            width: width.map { max($0, 0) },
            height: height.map { max($0, 0) },
            cornerRadius: cornerRadius.map { max($0, 0) }
        ))
    }

    /// A capsule, for chips, tags and pill buttons. A `nil` width fills the available width.
    public static func capsule(width: CGFloat? = nil, height: CGFloat = 28) -> SkeletonShape {
        SkeletonShape(kind: .capsule(width: width.map { max($0, 0) }, height: max(height, 0)))
    }

    // MARK: - Body

    public var body: some View {
        ShimmerTimeline(configuration: appearance.shimmer, isActive: true) { frame in
            shapes(frame)
                .opacity(frame.opacity)
        }
        .modifier(SkeletonAccessibility(isLoading: true))
    }

    @ViewBuilder
    private func shapes(_ frame: ShimmerFrame) -> some View {
        switch kind {
        case let .lines(count, seed, lineHeight, spacing):
            let widths = SkeletonLineWidths.widths(count: count, seed: seed)
            let radius = min(appearance.cornerRadius, lineHeight / 2)
            VStack(alignment: .leading, spacing: spacing) {
                ForEach(widths.indices, id: \.self) { index in
                    GeometryReader { proxy in
                        surface(RoundedRectangle(cornerRadius: radius, style: .continuous), frame)
                            .frame(width: proxy.size.width * CGFloat(widths[index]), height: lineHeight)
                    }
                    .frame(height: lineHeight)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        case let .circle(diameter):
            surface(Circle(), frame)
                .frame(width: diameter, height: diameter)
        case let .rectangle(width, height, cornerRadius):
            surface(RoundedRectangle(cornerRadius: cornerRadius ?? appearance.cornerRadius, style: .continuous), frame)
                .frame(width: width, height: height)
        case let .capsule(width, height):
            surface(Capsule(style: .continuous), frame)
                .frame(width: width, height: height)
        }
    }

    private func surface<S: Shape>(_ shape: S, _ frame: ShimmerFrame) -> SkeletonSurface<S> {
        SkeletonSurface(
            shape: shape,
            appearance: appearance,
            bandProgress: frame.bandProgress,
            isDark: colorScheme == .dark
        )
    }
}

/// One placeholder shape, solid or glass, with the shimmer band drawn inside it.
struct SkeletonSurface<S: Shape>: View {
    let shape: S
    let appearance: SkeletonAppearance
    let bandProgress: Double?
    let isDark: Bool

    private var band: ShimmerBand? {
        bandProgress.map {
            ShimmerPhase.band(progress: $0, angle: appearance.shimmer.angle, bandWidth: appearance.shimmer.bandWidth)
        }
    }

    var body: some View {
        base
            .overlay { highlightOverlay }
    }

    @ViewBuilder
    private var base: some View {
        switch appearance.surface {
        case .solid:
            shape.fill(solidStyle)
        case .glass:
            glass
        }
    }

    /// The fill, dimmed outside the band while it sweeps.
    private var solidStyle: AnyShapeStyle {
        guard let band else { return AnyShapeStyle(appearance.fill) }
        return AnyShapeStyle(LinearGradient(
            stops: ShimmerStops.fill(appearance.fill, minimumOpacity: appearance.shimmer.minimumOpacity),
            startPoint: band.start.unitPoint,
            endPoint: band.end.unitPoint
        ))
    }

    @ViewBuilder
    private var glass: some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            Color.clear
                .glassEffect(.regular.tint(appearance.fill), in: shape)
        } else {
            shape
                .fill(.ultraThinMaterial)
                .overlay { shape.fill(appearance.fill) }
                .overlay { shape.stroke(Color.white.opacity(0.28), lineWidth: 0.5) }
        }
    }

    @ViewBuilder
    private var highlightOverlay: some View {
        if let band, let highlight = appearance.highlight {
            LinearGradient(
                stops: ShimmerStops.highlight(highlight, opacity: appearance.shimmer.highlightOpacity(isDark: isDark)),
                startPoint: band.start.unitPoint,
                endPoint: band.end.unitPoint
            )
            .clipShape(shape)
            .allowsHitTesting(false)
        }
    }
}
