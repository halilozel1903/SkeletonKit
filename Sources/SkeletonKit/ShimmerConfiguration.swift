import Foundation

/// How a shimmer moves: speed, pause, angle, band width and strength.
///
/// Every value is clamped to a sensible range, so a configuration can never produce a
/// broken animation. Non-finite values (`.nan`, `.infinity`) fall back to the defaults.
///
/// ```swift
/// var shimmer = ShimmerConfiguration.default
/// shimmer.angle = 60
/// shimmer = shimmer.speed(1.5)          // 50 % faster
/// ```
public struct ShimmerConfiguration: Sendable, Hashable {
    /// The allowed duration of one sweep, in seconds.
    public static let durationRange: ClosedRange<TimeInterval> = 0.25...20
    /// The allowed pause between two sweeps, in seconds.
    public static let delayRange: ClosedRange<TimeInterval> = 0...20
    /// The allowed band width, as a fraction of the view's extent along the sweep direction.
    public static let bandWidthRange: ClosedRange<Double> = 0.05...1

    private var _duration: TimeInterval
    private var _delay: TimeInterval
    private var _angle: Double
    private var _bandWidth: Double
    private var _minimumOpacity: Double
    private var _highlightOpacity: Double
    private var _frozenProgress: Double?

    /// Creates a configuration. Every value is clamped; see the properties for the ranges.
    public init(
        duration: TimeInterval = 1.5,
        delay: TimeInterval = 0.4,
        angle: Double = 20,
        bandWidth: Double = 0.45,
        minimumOpacity: Double = 0.45,
        highlightOpacity: Double = 0.55,
        frozenProgress: Double? = nil
    ) {
        _duration = Self.clamp(duration, to: Self.durationRange, fallback: 1.5)
        _delay = Self.clamp(delay, to: Self.delayRange, fallback: 0.4)
        _angle = Self.normalizedAngle(angle)
        _bandWidth = Self.clamp(bandWidth, to: Self.bandWidthRange, fallback: 0.45)
        _minimumOpacity = Self.clamp(minimumOpacity, to: 0...1, fallback: 0.45)
        _highlightOpacity = Self.clamp(highlightOpacity, to: 0...1, fallback: 0.55)
        _frozenProgress = Self.clampedProgress(frozenProgress)
    }

    /// The standard shimmer: a 1.5 s sweep every 1.9 s, tilted by 20°.
    public static let `default` = ShimmerConfiguration()

    /// A slower, softer shimmer for dense screens.
    public static let subtle = ShimmerConfiguration(
        duration: 2.4,
        delay: 0.6,
        bandWidth: 0.6,
        minimumOpacity: 0.7,
        highlightOpacity: 0.3
    )

    // MARK: - Properties

    /// Seconds for the band to cross the view, clamped to ``durationRange``.
    public var duration: TimeInterval {
        get { _duration }
        set { _duration = Self.clamp(newValue, to: Self.durationRange, fallback: 1.5) }
    }

    /// Seconds to wait between two sweeps, clamped to ``delayRange``.
    public var delay: TimeInterval {
        get { _delay }
        set { _delay = Self.clamp(newValue, to: Self.delayRange, fallback: 0.4) }
    }

    /// The sweep direction in degrees, normalized to `0..<360`.
    /// `0` sweeps left to right, `90` top to bottom; positive values tilt the band clockwise.
    public var angle: Double {
        get { _angle }
        set { _angle = Self.normalizedAngle(newValue) }
    }

    /// The width of the bright band as a fraction of the view, clamped to ``bandWidthRange``.
    public var bandWidth: Double {
        get { _bandWidth }
        set { _bandWidth = Self.clamp(newValue, to: Self.bandWidthRange, fallback: 0.45) }
    }

    /// How opaque the placeholders are outside the band, from `0` to `1`.
    /// Lower values give a stronger shimmer. Also the lowest point of the Reduce Motion pulse.
    public var minimumOpacity: Double {
        get { _minimumOpacity }
        set { _minimumOpacity = Self.clamp(newValue, to: 0...1, fallback: 0.45) }
    }

    /// The opacity of the highlight color at the center of the band, from `0` to `1`.
    /// Only used when the appearance has a highlight color.
    public var highlightOpacity: Double {
        get { _highlightOpacity }
        set { _highlightOpacity = Self.clamp(newValue, to: 0...1, fallback: 0.55) }
    }

    /// A fixed position of the band, from `0` (before the view) to `1` (past it), or `nil` to animate.
    ///
    /// Freezing the shimmer makes previews and snapshot tests deterministic.
    public var frozenProgress: Double? {
        get { _frozenProgress }
        set { _frozenProgress = Self.clampedProgress(newValue) }
    }

    // MARK: - Derived values

    /// Returns a copy that runs `multiplier` times faster (`2` halves the duration).
    /// Zero, negative and non-finite multipliers return the configuration unchanged.
    public func speed(_ multiplier: Double) -> ShimmerConfiguration {
        guard multiplier.isFinite, multiplier > 0 else { return self }
        var copy = self
        copy.duration = duration / multiplier
        return copy
    }

    /// Returns a copy whose band stays at `progress`, for previews and snapshot tests.
    public func frozen(at progress: Double) -> ShimmerConfiguration {
        var copy = self
        copy.frozenProgress = progress
        return copy
    }

    /// The seconds from the start of one sweep to the start of the next.
    public var cycle: TimeInterval { duration + delay }

    /// The band position at `time`: ``frozenProgress`` when set, otherwise the animated value.
    public func progress(at time: TimeInterval) -> Double {
        if let frozenProgress { return frozenProgress }
        return ShimmerPhase.progress(time: time, duration: duration, delay: delay)
    }

    /// The opacity used instead of a moving band when Reduce Motion is on:
    /// a slow pulse between ``minimumOpacity`` and `1`, one pulse per ``cycle``.
    public func pulseOpacity(at time: TimeInterval) -> Double {
        let time = frozenProgress.map { $0 * cycle } ?? time
        return ShimmerPhase.pulseOpacity(time: time, period: cycle, minimum: minimumOpacity)
    }

    /// The highlight opacity for the current color scheme: softer in dark mode, where a bright
    /// band on dark placeholders reads much stronger than on light ones.
    public func highlightOpacity(isDark: Bool) -> Double {
        isDark ? highlightOpacity * 0.6 : highlightOpacity
    }

    // MARK: - Clamping

    static func clamp(_ value: Double, to range: ClosedRange<Double>, fallback: Double) -> Double {
        guard value.isFinite else { return fallback }
        return min(max(value, range.lowerBound), range.upperBound)
    }

    static func normalizedAngle(_ degrees: Double) -> Double {
        guard degrees.isFinite else { return 20 }
        let remainder = degrees.truncatingRemainder(dividingBy: 360)
        let normalized = remainder < 0 ? remainder + 360 : remainder
        return normalized == 0 ? 0 : normalized   // turns -0.0 into 0
    }

    static func clampedProgress(_ progress: Double?) -> Double? {
        guard let progress, progress.isFinite else { return nil }
        return min(max(progress, 0), 1)
    }
}
