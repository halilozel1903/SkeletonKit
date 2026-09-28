import SwiftUI

/// A stack of placeholder rows, for a list or feed that has not loaded yet.
///
/// ```swift
/// if items.isEmpty {
///     SkeletonList(count: 6)                          // avatar + two lines per row
/// }
///
/// SkeletonList(count: 4) { index in                   // your own row layout
///     VStack(alignment: .leading) {
///         SkeletonShape.rectangle(height: 140)
///         SkeletonShape.text(lines: 2, seed: UInt64(index))
///     }
/// }
/// ```
///
/// The whole list is hidden from VoiceOver and announces "Loading" once.
public struct SkeletonList<Row: View>: View {
    private let count: Int
    private let spacing: CGFloat
    private let row: (Int) -> Row

    /// Creates a list of `count` rows built by `row`, which receives the row index.
    public init(count: Int = 5, spacing: CGFloat = 20, @ViewBuilder row: @escaping (Int) -> Row) {
        self.count = max(count, 0)
        self.spacing = max(spacing, 0)
        self.row = row
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            ForEach(0..<count, id: \.self) { index in
                row(index)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(SkeletonAccessibility(isLoading: true))
    }
}

extension SkeletonList where Row == SkeletonRow {
    /// Creates a list of `count` standard rows: an optional avatar and a few text lines.
    /// Each row gets different line widths, the same on every launch.
    public init(count: Int = 5, spacing: CGFloat = 20, avatar: Bool = true, lines: Int = 2) {
        self.init(count: count, spacing: spacing) { index in
            SkeletonRow(avatar: avatar, lines: lines, seed: UInt64(index))
        }
    }
}

/// A standard placeholder row: an avatar circle next to a few text lines.
public struct SkeletonRow: View {
    private let avatar: Bool
    private let avatarDiameter: CGFloat
    private let lines: Int
    private let seed: UInt64

    public init(avatar: Bool = true, avatarDiameter: CGFloat = 44, lines: Int = 2, seed: UInt64 = 0) {
        self.avatar = avatar
        self.avatarDiameter = avatarDiameter
        self.lines = lines
        self.seed = seed
    }

    public var body: some View {
        HStack(alignment: .top, spacing: 14) {
            if avatar {
                SkeletonShape.circle(diameter: avatarDiameter)
            }
            SkeletonShape.text(lines: lines, seed: seed)
                .padding(.top, avatar ? 5 : 0)
        }
    }
}
