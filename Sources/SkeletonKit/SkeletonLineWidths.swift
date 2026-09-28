/// Widths for placeholder text lines that look random but are the same on every launch.
///
/// Real paragraphs have ragged lines and a short last line; identical bars look fake.
/// The widths come from a seeded generator, so a row keeps its shape across redraws,
/// launches and devices, and snapshot tests stay stable.
///
/// ```swift
/// SkeletonLineWidths.widths(count: 3, seed: 7)                        // e.g. [0.93, 0.81, 0.52]
/// SkeletonLineWidths.widths(count: 2, seed: SkeletonLineWidths.seed("post-42"))
/// ```
public enum SkeletonLineWidths {
    /// The default width range of every line but the last, as a fraction of the available width.
    public static let defaultRange: ClosedRange<Double> = 0.72...1
    /// The default width range of the last line of a paragraph.
    public static let defaultLastLineRange: ClosedRange<Double> = 0.36...0.64

    /// Returns `count` widths between `0` and `1`, one per line.
    ///
    /// - Parameters:
    ///   - count: The number of lines. Zero or negative gives an empty array.
    ///   - seed: The same seed always gives the same widths.
    ///   - range: The width range of full lines, clamped to `0...1`.
    ///   - lastLineRange: The width range of the last line when there are two or more lines,
    ///     clamped to `0...1`. A single line uses `range`.
    public static func widths(
        count: Int,
        seed: UInt64,
        range: ClosedRange<Double> = SkeletonLineWidths.defaultRange,
        lastLineRange: ClosedRange<Double> = SkeletonLineWidths.defaultLastLineRange
    ) -> [Double] {
        guard count > 0 else { return [] }
        let range = unitClamped(range)
        let lastLineRange = unitClamped(lastLineRange)
        var generator = SplitMix64(seed: seed)

        return (0..<count).map { index in
            let bounds = (count > 1 && index == count - 1) ? lastLineRange : range
            let unit = generator.nextUnit()
            return bounds.lowerBound + (bounds.upperBound - bounds.lowerBound) * unit
        }
    }

    /// A stable seed for a string, such as an item identifier.
    ///
    /// Unlike `hashValue`, which changes on every launch, this is the 64-bit FNV-1a hash of the
    /// string's UTF-8 bytes.
    public static func seed(_ string: String) -> UInt64 {
        var hash: UInt64 = 0xcbf2_9ce4_8422_2325
        for byte in string.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x0000_0100_0000_01b3
        }
        return hash
    }

    static func unitClamped(_ range: ClosedRange<Double>) -> ClosedRange<Double> {
        let lower = min(max(range.lowerBound, 0), 1)
        let upper = min(max(range.upperBound, 0), 1)
        return lower...max(lower, upper)
    }
}

/// SplitMix64: a tiny, fast, well-distributed generator with a 64-bit seed.
struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9e37_79b9_7f4a_7c15
        var z = state
        z = (z ^ (z >> 30)) &* 0xbf58_476d_1ce4_e5b9
        z = (z ^ (z >> 27)) &* 0x94d0_49bb_1331_11eb
        return z ^ (z >> 31)
    }

    /// A value in `0..<1` built from the top 53 bits.
    mutating func nextUnit() -> Double {
        Double(next() >> 11) * 0x1.0p-53
    }
}
