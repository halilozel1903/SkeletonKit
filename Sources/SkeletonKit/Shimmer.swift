import SwiftUI

/// Drives a shimmer from the display clock and hands each frame to `content`.
///
/// The timeline is paused while inactive and while the shimmer is frozen, so an idle or
/// frozen skeleton costs nothing per frame.
struct ShimmerTimeline<Content: View>: View {
    let configuration: ShimmerConfiguration
    let isActive: Bool
    let content: (ShimmerFrame) -> Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(
        configuration: ShimmerConfiguration,
        isActive: Bool,
        @ViewBuilder content: @escaping (ShimmerFrame) -> Content
    ) {
        self.configuration = configuration
        self.isActive = isActive
        self.content = content
    }

    var body: some View {
        let isPaused = !isActive || configuration.frozenProgress != nil
        TimelineView(.animation(minimumInterval: nil, paused: isPaused)) { context in
            content(ShimmerFrame(
                configuration: configuration,
                time: context.date.timeIntervalSinceReferenceDate,
                isActive: isActive,
                reduceMotion: reduceMotion
            ))
        }
    }
}

/// Shimmers any content without masking or clipping it.
///
/// Inside a compositing group, a `destinationOut` gradient lowers the content's alpha outside
/// the band and an optional `sourceAtop` gradient tints the band. Both only touch pixels the
/// content already draws, so text placeholders shimmer and the empty space around them stays
/// empty. The view structure never changes with `isActive`, so the content keeps its state.
struct ContentShimmer: ViewModifier {
    let isActive: Bool
    let configuration: ShimmerConfiguration
    let highlight: Color?

    @Environment(\.colorScheme) private var colorScheme

    @ViewBuilder
    func body(content: Content) -> some View {
        ShimmerTimeline(configuration: configuration, isActive: isActive) { frame in
            let band = ShimmerPhase.band(
                progress: frame.bandProgress ?? 0,
                angle: configuration.angle,
                bandWidth: configuration.bandWidth
            )
            let bandOpacity: Double = frame.bandProgress == nil ? 0 : 1

            content
                .overlay {
                    if let highlight {
                        LinearGradient(
                            stops: ShimmerStops.highlight(
                                highlight,
                                opacity: configuration.highlightOpacity(isDark: colorScheme == .dark)
                            ),
                            startPoint: band.start.unitPoint,
                            endPoint: band.end.unitPoint
                        )
                        .opacity(bandOpacity)
                        .blendMode(.sourceAtop)
                        .allowsHitTesting(false)
                    }
                }
                .overlay {
                    LinearGradient(
                        stops: ShimmerStops.dimming(minimumOpacity: configuration.minimumOpacity),
                        startPoint: band.start.unitPoint,
                        endPoint: band.end.unitPoint
                    )
                    .opacity(bandOpacity)
                    .blendMode(.destinationOut)
                    .allowsHitTesting(false)
                }
                .compositingGroup()
                .opacity(frame.opacity)
        }
    }
}

/// Redacts content into placeholders, shimmers it, blocks interaction and hides it from VoiceOver.
struct SkeletonModifier: ViewModifier {
    let isLoading: Bool
    let appearance: SkeletonAppearance?

    @Environment(\.skeletonAppearance) private var environmentAppearance

    @ViewBuilder
    func body(content: Content) -> some View {
        let appearance = self.appearance ?? environmentAppearance
        let tintOpacity: Double = isLoading && appearance.tint != nil ? 1 : 0

        content
            .redacted(reason: isLoading ? .placeholder : [])
            .overlay {
                (appearance.tint ?? Color.clear)
                    .opacity(tintOpacity)
                    .blendMode(.sourceAtop)
                    .allowsHitTesting(false)
            }
            .modifier(ContentShimmer(
                isActive: isLoading,
                configuration: appearance.shimmer,
                highlight: appearance.highlight
            ))
            .environment(\.skeletonAppearance, appearance)
            .allowsHitTesting(!isLoading)
            .modifier(SkeletonAccessibility(isLoading: isLoading))
    }
}

/// Replaces a view that redaction leaves alone (a shape, gradient, photo or control) with a
/// placeholder shape while its skeleton is loading.
struct SkeletonFillModifier<S: Shape>: ViewModifier {
    let shape: S

    @Environment(\.redactionReasons) private var redactionReasons
    @Environment(\.skeletonAppearance) private var appearance

    @ViewBuilder
    func body(content: Content) -> some View {
        let isPlaceholder = redactionReasons.contains(.placeholder)
        content
            .opacity(isPlaceholder ? 0 : 1)
            .overlay {
                shape
                    .fill(appearance.fill)
                    .opacity(isPlaceholder ? 1 : 0)
                    .allowsHitTesting(false)
            }
    }
}

extension View {
    /// Shows the view as a shimmering skeleton while `isLoading` is `true`.
    ///
    /// Text and images become rounded placeholder bars of the same size (through
    /// `redacted(reason: .placeholder)`), a gradient band sweeps across them, taps are blocked
    /// and VoiceOver skips the placeholders and hears "Loading" once. With Reduce Motion on,
    /// the placeholders pulse gently instead of sweeping.
    ///
    /// ```swift
    /// PostRow(post: post ?? .placeholder)
    ///     .skeleton(post == nil)
    /// ```
    ///
    /// Apply it to the content itself rather than to a card with an opaque background or to a
    /// `List` or `ScrollView`: everything the view draws becomes part of the placeholder.
    /// Mark shapes, gradients and controls that redaction leaves alone with ``skeletonFill(in:)``.
    ///
    /// - Parameters:
    ///   - isLoading: Shows the skeleton when `true`, the real content when `false`.
    ///     The view keeps its identity and state either way.
    ///   - appearance: The look, or `nil` for the ``EnvironmentValues/skeletonAppearance``.
    public func skeleton(_ isLoading: Bool, appearance: SkeletonAppearance? = nil) -> some View {
        modifier(SkeletonModifier(isLoading: isLoading, appearance: appearance))
    }

    /// Draws the view as a plain placeholder `shape` inside a loading ``skeleton(_:appearance:)``
    /// (or any `redacted(reason: .placeholder)` context), and normally otherwise.
    ///
    /// ```swift
    /// AsyncImage(url: user.avatarURL)
    ///     .frame(width: 48, height: 48)
    ///     .skeletonFill(in: Circle())
    /// ```
    public func skeletonFill(in shape: some Shape) -> some View {
        modifier(SkeletonFillModifier(shape: shape))
    }

    /// Adds a shimmer to any view, without redacting it.
    ///
    /// - Parameters:
    ///   - isActive: Runs the shimmer when `true`; the view is drawn unchanged when `false`.
    ///   - configuration: Speed, angle, band width and strength.
    ///   - highlight: A color swept with the band, or `nil` for an opacity-only shimmer.
    public func shimmer(
        _ isActive: Bool = true,
        configuration: ShimmerConfiguration = .default,
        highlight: Color? = nil
    ) -> some View {
        modifier(ContentShimmer(isActive: isActive, configuration: configuration, highlight: highlight))
    }

    /// Sets the appearance of every skeleton in this view that is not given one explicitly.
    public func skeletonAppearance(_ appearance: SkeletonAppearance) -> some View {
        environment(\.skeletonAppearance, appearance)
    }
}
