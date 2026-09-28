import Testing
@testable import SkeletonKit

@Suite("Line widths")
struct SkeletonLineWidthsTests {
    @Test func sameSeedGivesSameWidths() {
        #expect(SkeletonLineWidths.widths(count: 5, seed: 42) == SkeletonLineWidths.widths(count: 5, seed: 42))
    }

    @Test func differentSeedsGiveDifferentParagraphs() {
        let paragraphs = Set((0..<20).map { SkeletonLineWidths.widths(count: 3, seed: UInt64($0)) })
        #expect(paragraphs.count == 20)
    }

    @Test func linesAreRaggedNotIdentical() {
        let widths = SkeletonLineWidths.widths(count: 6, seed: 3)
        #expect(Set(widths).count > 1)
    }

    @Test func widthsStayInTheirRanges() {
        for seed in 0..<200 as Range<UInt64> {
            let widths = SkeletonLineWidths.widths(count: 4, seed: seed)
            #expect(widths.count == 4)
            for width in widths.dropLast() {
                #expect(SkeletonLineWidths.defaultRange.contains(width))
            }
            #expect(SkeletonLineWidths.defaultLastLineRange.contains(widths[3]))
        }
    }

    @Test func lastLineIsShorter() {
        for seed in 0..<50 as Range<UInt64> {
            let widths = SkeletonLineWidths.widths(count: 3, seed: seed)
            #expect(widths[2] < widths[0])
            #expect(widths[2] < widths[1])
        }
    }

    @Test func singleLineUsesTheFullRange() {
        let width = SkeletonLineWidths.widths(count: 1, seed: 9)
        #expect(width.count == 1)
        #expect(SkeletonLineWidths.defaultRange.contains(width[0]))
    }

    @Test func nonPositiveCountsAreEmpty() {
        #expect(SkeletonLineWidths.widths(count: 0, seed: 1).isEmpty)
        #expect(SkeletonLineWidths.widths(count: -4, seed: 1).isEmpty)
    }

    @Test func rangesAreClampedToUnitInterval() {
        let widths = SkeletonLineWidths.widths(count: 8, seed: 11, range: -2...5, lastLineRange: 1.5...9)
        for width in widths.dropLast() {
            #expect(width >= 0 && width <= 1)
        }
        #expect(widths.last == 1)
    }

    @Test func customRangesAreRespected() {
        let widths = SkeletonLineWidths.widths(count: 3, seed: 5, range: 0.5...0.5, lastLineRange: 0.2...0.2)
        #expect(widths == [0.5, 0.5, 0.2])
    }

    @Test func stringSeedsAreStableFNV1a() {
        #expect(SkeletonLineWidths.seed("") == 0xcbf2_9ce4_8422_2325)
        #expect(SkeletonLineWidths.seed("a") == 0xaf63_dc4c_8601_ec8c)
        #expect(SkeletonLineWidths.seed("post-1") == SkeletonLineWidths.seed("post-1"))
        #expect(SkeletonLineWidths.seed("post-1") != SkeletonLineWidths.seed("post-2"))
    }

    @Test func generatorMatchesReferenceSplitMix64() {
        var generator = SplitMix64(seed: 0)
        #expect(generator.next() == 0xe220_a839_7b1d_cdaf)
        for _ in 0..<100 {
            let unit = generator.nextUnit()
            #expect(unit >= 0 && unit < 1)
        }
    }
}

@Suite("Loading announcement")
struct AnnouncementThrottleTests {
    @Test func firstAnnouncementIsAllowed() {
        var throttle = AnnouncementThrottle(interval: 2)
        #expect(throttle.shouldAnnounce(at: 100))
        #expect(throttle.lastAnnouncement == 100)
    }

    @Test func manySkeletonsAnnounceOnce() {
        var throttle = AnnouncementThrottle(interval: 2)
        let results = (0..<10).map { throttle.shouldAnnounce(at: 100 + Double($0) * 0.01) }
        #expect(results.filter { $0 }.count == 1)
    }

    @Test func laterLoadingAnnouncesAgain() {
        var throttle = AnnouncementThrottle(interval: 2)
        #expect(throttle.shouldAnnounce(at: 10))
        #expect(!throttle.shouldAnnounce(at: 11.9))
        #expect(throttle.shouldAnnounce(at: 12))
    }

    @Test func clockGoingBackwardsAllowsAnnouncement() {
        var throttle = AnnouncementThrottle(interval: 2)
        #expect(throttle.shouldAnnounce(at: 50))
        #expect(throttle.shouldAnnounce(at: 10))
    }
}
