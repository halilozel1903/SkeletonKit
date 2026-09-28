import SwiftUI
import Testing
@testable import SkeletonKit

@Suite("Shimmer configuration")
struct ShimmerConfigurationTests {
    @Test func defaultsAreWithinRange() {
        let configuration = ShimmerConfiguration.default
        #expect(ShimmerConfiguration.durationRange.contains(configuration.duration))
        #expect(ShimmerConfiguration.delayRange.contains(configuration.delay))
        #expect(ShimmerConfiguration.bandWidthRange.contains(configuration.bandWidth))
        #expect(configuration.frozenProgress == nil)
        #expect(configuration.cycle == configuration.duration + configuration.delay)
    }

    @Test func valuesAreClampedOnInit() {
        let configuration = ShimmerConfiguration(
            duration: 0,
            delay: -3,
            bandWidth: 7,
            minimumOpacity: -1,
            highlightOpacity: 2,
            frozenProgress: 1.5
        )
        #expect(configuration.duration == ShimmerConfiguration.durationRange.lowerBound)
        #expect(configuration.delay == 0)
        #expect(configuration.bandWidth == 1)
        #expect(configuration.minimumOpacity == 0)
        #expect(configuration.highlightOpacity == 1)
        #expect(configuration.frozenProgress == 1)
    }

    @Test func valuesAreClampedWhenSet() {
        var configuration = ShimmerConfiguration.default
        configuration.duration = 999
        configuration.delay = 999
        configuration.bandWidth = 0
        configuration.minimumOpacity = 3
        configuration.frozenProgress = -0.5
        #expect(configuration.duration == ShimmerConfiguration.durationRange.upperBound)
        #expect(configuration.delay == ShimmerConfiguration.delayRange.upperBound)
        #expect(configuration.bandWidth == ShimmerConfiguration.bandWidthRange.lowerBound)
        #expect(configuration.minimumOpacity == 1)
        #expect(configuration.frozenProgress == 0)

        configuration.frozenProgress = nil
        #expect(configuration.frozenProgress == nil)
    }

    @Test func nonFiniteValuesFallBackToDefaults() {
        let configuration = ShimmerConfiguration(
            duration: .nan,
            delay: .infinity,
            angle: .nan,
            bandWidth: -.infinity,
            minimumOpacity: .nan,
            frozenProgress: .nan
        )
        #expect(configuration.duration == 1.5)
        #expect(configuration.delay == 0.4)
        #expect(configuration.angle == 20)
        #expect(configuration.bandWidth == 0.45)
        #expect(configuration.minimumOpacity == 0.45)
        #expect(configuration.frozenProgress == nil)
    }

    @Test func anglesAreNormalized() {
        #expect(ShimmerConfiguration(angle: 380).angle == 20)
        #expect(ShimmerConfiguration(angle: -90).angle == 270)
        #expect(ShimmerConfiguration(angle: 360).angle == 0)
        #expect(ShimmerConfiguration(angle: -720).angle == 0)
        #expect(ShimmerConfiguration(angle: 45).angle == 45)
    }

    @Test func speedScalesTheDuration() {
        let configuration = ShimmerConfiguration(duration: 2)
        #expect(configuration.speed(2).duration == 1)
        #expect(configuration.speed(0.5).duration == 4)
        #expect(configuration.speed(1000).duration == ShimmerConfiguration.durationRange.lowerBound)
        #expect(configuration.speed(0) == configuration)
        #expect(configuration.speed(-1) == configuration)
        #expect(configuration.speed(.nan) == configuration)
    }

    @Test func frozenConfigurationIgnoresTime() {
        let frozen = ShimmerConfiguration.default.frozen(at: 0.4)
        #expect(frozen.progress(at: 0) == 0.4)
        #expect(frozen.progress(at: 12_345.678) == 0.4)
        #expect(frozen.pulseOpacity(at: 0) == frozen.pulseOpacity(at: 99))
    }

    @Test func animatedProgressFollowsTheClock() {
        let configuration = ShimmerConfiguration(duration: 2, delay: 1)
        #expect(configuration.progress(at: 0) == 0)
        #expect(configuration.progress(at: 1) == 0.5)
        #expect(configuration.progress(at: 2.5) == 1)       // pausing between sweeps
        #expect(configuration.progress(at: 4) == 0.5)       // next cycle
    }

    @Test func highlightIsSofterInDarkMode() {
        let configuration = ShimmerConfiguration(highlightOpacity: 0.5)
        #expect(configuration.highlightOpacity(isDark: false) == 0.5)
        #expect(configuration.highlightOpacity(isDark: true) < 0.5)
        #expect(configuration.highlightOpacity(isDark: true) > 0)
    }

    @Test func subtlePresetIsSlowerAndSofter() {
        #expect(ShimmerConfiguration.subtle.duration > ShimmerConfiguration.default.duration)
        #expect(ShimmerConfiguration.subtle.minimumOpacity > ShimmerConfiguration.default.minimumOpacity)
    }
}

@Suite("Appearance")
struct SkeletonAppearanceTests {
    @Test func presetsDiffer() {
        #expect(SkeletonAppearance.default != SkeletonAppearance.subtle)
        #expect(SkeletonAppearance.glass.surface == .glass)
        #expect(SkeletonAppearance.default.surface == .solid)
        #expect(SkeletonAppearance.glass.highlight != nil)
    }

    @Test func cornerRadiusIsNeverNegative() {
        #expect(SkeletonAppearance(cornerRadius: -4).cornerRadius == 0)
        #expect(SkeletonAppearance(cornerRadius: .nan).cornerRadius == 8)

        var appearance = SkeletonAppearance.default
        appearance.cornerRadius = -10
        #expect(appearance.cornerRadius == 0)
    }

    @Test func frozenAppearanceFreezesItsShimmer() {
        let frozen = SkeletonAppearance.subtle.frozen(at: 0.3)
        #expect(frozen.shimmer.frozenProgress == 0.3)
        #expect(frozen.shimmer.duration == ShimmerConfiguration.subtle.duration)
        #expect(frozen.fill == SkeletonAppearance.subtle.fill)
    }
}
