import Foundation
import SkeletonKit

/// Scenes used by CI to capture the README screenshots.
/// Launch with `-screenshot <scene>`; normal launches are unaffected.
enum ScreenshotScene: String {
    /// The profile feed while it loads, with the shimmer frozen mid-sweep.
    case loading
    /// Every appearance preset side by side.
    case styles

    static var current: ScreenshotScene? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "-screenshot"), arguments.indices.contains(index + 1) else {
            return nil
        }
        return ScreenshotScene(rawValue: arguments[index + 1])
    }

    /// Where the shimmer band stays in screenshots: a little left of center, clearly visible.
    static let frozenProgress = 0.42
}

extension SkeletonAppearance {
    /// Freezes the shimmer in screenshot scenes so every capture looks the same.
    func frozen(if isFrozen: Bool) -> SkeletonAppearance {
        isFrozen ? frozen(at: ScreenshotScene.frozenProgress) : self
    }
}
