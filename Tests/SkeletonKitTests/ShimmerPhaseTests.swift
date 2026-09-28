import Foundation
import Testing
@testable import SkeletonKit

private func isClose(_ a: Double, _ b: Double, tolerance: Double = 1e-9) -> Bool {
    abs(a - b) <= tolerance
}

private func isClose(_ a: ShimmerPoint, _ b: ShimmerPoint) -> Bool {
    isClose(a.x, b.x) && isClose(a.y, b.y)
}

@Suite("Shimmer progress")
struct ShimmerProgressTests {
    @Test func progressRisesDuringTheSweep() {
        #expect(ShimmerPhase.progress(time: 0, duration: 2, delay: 0) == 0)
        #expect(ShimmerPhase.progress(time: 0.5, duration: 2, delay: 0) == 0.25)
        #expect(ShimmerPhase.progress(time: 1.5, duration: 2, delay: 0) == 0.75)
    }

    @Test func progressHoldsAtTheEndDuringTheDelay() {
        #expect(ShimmerPhase.progress(time: 2, duration: 2, delay: 1) == 1)
        #expect(ShimmerPhase.progress(time: 2.9, duration: 2, delay: 1) == 1)
        #expect(ShimmerPhase.progress(time: 3, duration: 2, delay: 1) == 0)
    }

    @Test func progressRepeats() {
        let a = ShimmerPhase.progress(time: 0.7, duration: 1.5, delay: 0.5)
        let b = ShimmerPhase.progress(time: 0.7 + 2 * 10, duration: 1.5, delay: 0.5)
        #expect(isClose(a, b, tolerance: 1e-6))
    }

    @Test func negativeTimeWrapsAround() {
        #expect(isClose(ShimmerPhase.progress(time: -0.5, duration: 2, delay: 0), 0.75))
    }

    @Test func invalidInputsAreSafe() {
        #expect(ShimmerPhase.progress(time: .nan, duration: 2, delay: 0) == 0)
        #expect(ShimmerPhase.progress(time: 1, duration: 0, delay: 0) == 0)
        #expect(ShimmerPhase.progress(time: 1, duration: -1, delay: 0) == 0)
        #expect(ShimmerPhase.progress(time: 1, duration: 2, delay: .nan) == 0.5)
        #expect(ShimmerPhase.progress(time: 1, duration: 2, delay: -5) == 0.5)
    }
}

@Suite("Shimmer band")
struct ShimmerBandTests {
    @Test func horizontalBandIsCenteredHalfway() {
        let band = ShimmerPhase.band(progress: 0.5, angle: 0, bandWidth: 0.5)
        #expect(isClose(band.start, ShimmerPoint(x: 0.25, y: 0.5)))
        #expect(isClose(band.end, ShimmerPoint(x: 0.75, y: 0.5)))
    }

    @Test func bandStartsBeforeAndEndsAfterTheView() {
        let first = ShimmerPhase.band(progress: 0, angle: 0, bandWidth: 0.4)
        #expect(isClose(first.end.x, 0))          // trailing edge touches the leading side
        let last = ShimmerPhase.band(progress: 1, angle: 0, bandWidth: 0.4)
        #expect(isClose(last.start.x, 1))         // fully past the trailing side
    }

    @Test func diagonalBandCrossesCornerToCorner() {
        let first = ShimmerPhase.band(progress: 0, angle: 45, bandWidth: 0.3)
        #expect(isClose(first.end, ShimmerPoint(x: 0, y: 0)))
        let last = ShimmerPhase.band(progress: 1, angle: 45, bandWidth: 0.3)
        #expect(isClose(last.start, ShimmerPoint(x: 1, y: 1)))
    }

    @Test func verticalBandMovesDown() {
        let top = ShimmerPhase.band(progress: 0.25, angle: 90, bandWidth: 0.5)
        let bottom = ShimmerPhase.band(progress: 0.75, angle: 90, bandWidth: 0.5)
        #expect(isClose(top.start.x, 0.5) && isClose(top.end.x, 0.5))
        #expect(bottom.start.y > top.start.y)
    }

    @Test func bandWidthIsClamped() {
        let tooWide = ShimmerPhase.band(progress: 0.5, angle: 0, bandWidth: 10)
        let widest = ShimmerPhase.band(progress: 0.5, angle: 0, bandWidth: 1)
        #expect(tooWide == widest)
        #expect(isClose(widest.end.x - widest.start.x, 1))
    }

    @Test func progressIsClamped() {
        #expect(ShimmerPhase.band(progress: -3, angle: 20, bandWidth: 0.4) == ShimmerPhase.band(progress: 0, angle: 20, bandWidth: 0.4))
        #expect(ShimmerPhase.band(progress: 7, angle: 20, bandWidth: 0.4) == ShimmerPhase.band(progress: 1, angle: 20, bandWidth: 0.4))
    }
}

@Suite("Reduce Motion pulse")
struct PulseTests {
    @Test func pulseStartsOpaqueAndDipsToTheMinimum() {
        #expect(isClose(ShimmerPhase.pulseOpacity(time: 0, period: 2, minimum: 0.4), 1))
        #expect(isClose(ShimmerPhase.pulseOpacity(time: 1, period: 2, minimum: 0.4), 0.4))
        #expect(isClose(ShimmerPhase.pulseOpacity(time: 2, period: 2, minimum: 0.4), 1))
    }

    @Test func pulseStaysInRange() {
        for step in 0..<50 {
            let opacity = ShimmerPhase.pulseOpacity(time: Double(step) * 0.13, period: 1.7, minimum: 0.55)
            #expect(opacity >= 0.55 - 1e-9 && opacity <= 1 + 1e-9)
        }
    }

    @Test func invalidPeriodIsOpaque() {
        #expect(ShimmerPhase.pulseOpacity(time: 1, period: 0, minimum: 0.3) == 1)
        #expect(ShimmerPhase.pulseOpacity(time: .infinity, period: 2, minimum: 0.3) == 1)
    }
}

@Suite("Shimmer frame")
struct ShimmerFrameTests {
    let configuration = ShimmerConfiguration(duration: 2, delay: 0, minimumOpacity: 0.5)

    @Test func inactiveFrameDrawsNothing() {
        let frame = ShimmerFrame(configuration: configuration, time: 0.5, isActive: false, reduceMotion: false)
        #expect(frame == ShimmerFrame(bandProgress: nil, opacity: 1))
    }

    @Test func activeFrameSweeps() {
        let frame = ShimmerFrame(configuration: configuration, time: 0.5, isActive: true, reduceMotion: false)
        #expect(frame == ShimmerFrame(bandProgress: 0.25, opacity: 1))
    }

    @Test func reduceMotionPulsesInsteadOfSweeping() {
        let frame = ShimmerFrame(configuration: configuration, time: 1, isActive: true, reduceMotion: true)
        #expect(frame.bandProgress == nil)
        #expect(isClose(frame.opacity, 0.5))
    }
}
