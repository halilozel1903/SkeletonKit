import SwiftUI

/// How skeleton placeholders look: fill, tint, highlight, corner radius, surface and shimmer.
///
/// Use a preset or build your own, then pass it to ``SwiftUICore/View/skeleton(_:appearance:)``
/// or set it for a whole screen with ``SwiftUICore/View/skeletonAppearance(_:)``.
///
/// ```swift
/// FeedView()
///     .skeletonAppearance(.subtle)
/// ```
public struct SkeletonAppearance: Sendable, Hashable {
    /// What the ``SkeletonShape`` primitives are made of.
    public enum Surface: Sendable, Hashable, CaseIterable {
        /// A flat fill with ``SkeletonAppearance/fill``.
        case solid
        /// Liquid Glass on iOS 26 and macOS 26, `.ultraThinMaterial` with a hairline border before.
        case glass
    }

    /// The color of ``SkeletonShape`` primitives and of views marked with ``SwiftUICore/View/skeletonFill(in:)``.
    /// The defaults are based on `Color.primary`, so they adapt to light and dark mode.
    public var fill: Color
    /// Recolors redacted text and images. `nil` keeps the system placeholder color,
    /// which follows each view's foreground style.
    public var tint: Color?
    /// A color swept across the placeholders with the band, or `nil` for an opacity-only shimmer.
    public var highlight: Color?
    /// The corner radius of rectangles and text lines (lines are never rounder than a capsule).
    public var cornerRadius: CGFloat {
        didSet { cornerRadius = Self.clampedRadius(cornerRadius) }
    }
    /// What the primitives are made of.
    public var surface: Surface
    /// How the shimmer moves.
    public var shimmer: ShimmerConfiguration

    public init(
        fill: Color = Color.primary.opacity(0.11),
        tint: Color? = nil,
        highlight: Color? = nil,
        cornerRadius: CGFloat = 8,
        surface: Surface = .solid,
        shimmer: ShimmerConfiguration = .default
    ) {
        self.fill = fill
        self.tint = tint
        self.highlight = highlight
        self.cornerRadius = Self.clampedRadius(cornerRadius)
        self.surface = surface
        self.shimmer = shimmer
    }

    /// Neutral gray placeholders with a clearly visible sweep.
    public static let `default` = SkeletonAppearance()

    /// Lighter placeholders and a slow, soft sweep, for dense or calm screens.
    public static let subtle = SkeletonAppearance(
        fill: Color.primary.opacity(0.06),
        cornerRadius: 6,
        shimmer: .subtle
    )

    /// Liquid Glass primitives with a white highlight, for colorful or photo backgrounds.
    /// Falls back to `.ultraThinMaterial` before iOS 26 and macOS 26.
    public static let glass = SkeletonAppearance(
        fill: Color.white.opacity(0.14),
        highlight: .white,
        cornerRadius: 12,
        surface: .glass,
        shimmer: ShimmerConfiguration(highlightOpacity: 0.5)
    )

    /// Returns a copy whose shimmer stays at `progress`, for previews and snapshot tests.
    public func frozen(at progress: Double) -> SkeletonAppearance {
        var copy = self
        copy.shimmer = shimmer.frozen(at: progress)
        return copy
    }

    static func clampedRadius(_ radius: CGFloat) -> CGFloat {
        guard radius.isFinite else { return 8 }
        return max(radius, 0)
    }
}

private struct SkeletonAppearanceKey: EnvironmentKey {
    static let defaultValue = SkeletonAppearance.default
}

extension EnvironmentValues {
    /// The appearance used by skeletons that are not given one explicitly.
    public var skeletonAppearance: SkeletonAppearance {
        get { self[SkeletonAppearanceKey.self] }
        set { self[SkeletonAppearanceKey.self] = newValue }
    }
}

extension ShimmerPoint {
    var unitPoint: UnitPoint { UnitPoint(x: x, y: y) }
}

/// Gradient stops shared by the shimmer renderers.
enum ShimmerStops {
    /// Transparent, `color` at `opacity` in the middle, transparent.
    static func highlight(_ color: Color, opacity: Double) -> [Gradient.Stop] {
        [
            Gradient.Stop(color: color.opacity(0), location: 0),
            Gradient.Stop(color: color.opacity(opacity), location: 0.5),
            Gradient.Stop(color: color.opacity(0), location: 1),
        ]
    }

    /// Erases `1 - minimumOpacity` of the alpha outside the band, nothing at its center.
    static func dimming(minimumOpacity: Double) -> [Gradient.Stop] {
        let erase = 1 - minimumOpacity
        return [
            Gradient.Stop(color: Color.black.opacity(erase), location: 0),
            Gradient.Stop(color: Color.black.opacity(0), location: 0.5),
            Gradient.Stop(color: Color.black.opacity(erase), location: 1),
        ]
    }

    /// `fill` at `minimumOpacity` outside the band, full strength at its center.
    static func fill(_ color: Color, minimumOpacity: Double) -> [Gradient.Stop] {
        let dim = color.opacity(minimumOpacity)
        return [
            Gradient.Stop(color: dim, location: 0),
            Gradient.Stop(color: color, location: 0.5),
            Gradient.Stop(color: dim, location: 1),
        ]
    }
}
