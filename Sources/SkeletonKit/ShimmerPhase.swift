import Foundation

/// A point in unit coordinates: `(0, 0)` is the top-leading corner of a view, `(1, 1)` the bottom-trailing one.
/// Values outside `0...1` lie outside the view.
public struct ShimmerPoint: Sendable, Hashable {
    public var x: Double
    public var y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}

/// Where the bright band of a shimmer is: a linear gradient from ``start`` to ``end``,
/// transparent at both ends and brightest halfway.
public struct ShimmerBand: Sendable, Hashable {
    public var start: ShimmerPoint
    public var end: ShimmerPoint

    public init(start: ShimmerPoint, end: ShimmerPoint) {
        self.start = start
        self.end = end
    }
}

/// The pure math behind the shimmer animation, free of SwiftUI so it can be unit tested.
public enum ShimmerPhase {
    /// The band position at `time`, from `0` (fully before the view) to `1` (fully past it).
    ///
    /// Each cycle lasts `duration + delay` seconds: the band sweeps for `duration`, then stays
    /// at `1` (out of sight) for `delay`. Negative times are handled like positive ones.
    public static func progress(time: TimeInterval, duration: TimeInterval, delay: TimeInterval) -> Double {
        guard time.isFinite, duration.isFinite, duration > 0 else { return 0 }
        let delay = delay.isFinite ? max(delay, 0) : 0
        let cycle = duration + delay
        var t = time.truncatingRemainder(dividingBy: cycle)
        if t < 0 { t += cycle }
        return min(t / duration, 1)
    }

    /// The gradient end points of the band for a given progress.
    ///
    /// The band travels along the direction given by `angle` (degrees, `0` = left to right,
    /// `90` = top to bottom). At progress `0` its trailing edge touches the first corner of the
    /// view; at `1` its leading edge has passed the opposite corner, so the band enters and
    /// leaves the view completely, whatever the angle.
    ///
    /// - Parameter bandWidth: The band's width as a fraction of the view's extent along the
    ///   sweep direction, clamped to ``ShimmerConfiguration/bandWidthRange``.
    public static func band(progress: Double, angle: Double, bandWidth: Double) -> ShimmerBand {
        let progress = progress.isFinite ? min(max(progress, 0), 1) : 0
        let width = ShimmerConfiguration.clamp(bandWidth, to: ShimmerConfiguration.bandWidthRange, fallback: 0.45)
        let radians = ShimmerConfiguration.normalizedAngle(angle) * .pi / 180
        let dx = cos(radians)
        let dy = sin(radians)

        // Half of the unit square's extent along the direction, and half of the band.
        let halfExtent = (abs(dx) + abs(dy)) / 2
        let halfBand = width * halfExtent

        let travel = halfExtent + halfBand
        let offset = -travel + progress * 2 * travel
        let centerX = 0.5 + offset * dx
        let centerY = 0.5 + offset * dy

        return ShimmerBand(
            start: ShimmerPoint(x: centerX - halfBand * dx, y: centerY - halfBand * dy),
            end: ShimmerPoint(x: centerX + halfBand * dx, y: centerY + halfBand * dy)
        )
    }

    /// A smooth pulse between `minimum` and `1`, used instead of a moving band when
    /// Reduce Motion is on. It starts at `1`, reaches `minimum` after half a period and repeats.
    public static func pulseOpacity(time: TimeInterval, period: TimeInterval, minimum: Double) -> Double {
        let minimum = minimum.isFinite ? min(max(minimum, 0), 1) : 0.45
        guard time.isFinite, period.isFinite, period > 0 else { return 1 }
        let wave = 0.5 + 0.5 * cos(2 * .pi * time / period)
        return minimum + (1 - minimum) * wave
    }
}

/// What a shimmering view draws in one frame.
struct ShimmerFrame: Equatable {
    /// The band position, or `nil` when no band is drawn (inactive, or Reduce Motion).
    var bandProgress: Double?
    /// The opacity of the whole placeholder; below `1` only while pulsing for Reduce Motion.
    var opacity: Double

    init(bandProgress: Double?, opacity: Double) {
        self.bandProgress = bandProgress
        self.opacity = opacity
    }

    init(configuration: ShimmerConfiguration, time: TimeInterval, isActive: Bool, reduceMotion: Bool) {
        if !isActive {
            self.init(bandProgress: nil, opacity: 1)
        } else if reduceMotion {
            self.init(bandProgress: nil, opacity: configuration.pulseOpacity(at: time))
        } else {
            self.init(bandProgress: configuration.progress(at: time), opacity: 1)
        }
    }
}
