import Accessibility
import Foundation
import SwiftUI

/// Decides whether a "Loading" announcement should be spoken.
///
/// A screen often shows many skeletons at once; VoiceOver should hear "Loading" once,
/// not once per row. Announcements within ``interval`` of the previous one are dropped.
struct AnnouncementThrottle: Sendable {
    /// The quiet period after an announcement, in seconds.
    var interval: TimeInterval
    private(set) var lastAnnouncement: TimeInterval?

    init(interval: TimeInterval = 2) {
        self.interval = interval
    }

    /// Records and allows an announcement at `time`, unless one was allowed less than
    /// ``interval`` seconds before. A clock that went backwards always allows it.
    mutating func shouldAnnounce(at time: TimeInterval) -> Bool {
        if let lastAnnouncement, time >= lastAnnouncement, time - lastAnnouncement < interval {
            return false
        }
        lastAnnouncement = time
        return true
    }
}

@MainActor
enum SkeletonAnnouncer {
    static var throttle = AnnouncementThrottle()

    static func announceLoading() {
        guard throttle.shouldAnnounce(at: ProcessInfo.processInfo.systemUptime) else { return }
        AccessibilityNotification.Announcement("Loading").post()
    }
}

/// Hides placeholder content from assistive technologies and announces "Loading" once.
struct SkeletonAccessibility: ViewModifier {
    let isLoading: Bool

    func body(content: Content) -> some View {
        content
            .accessibilityHidden(isLoading)
            .onAppear {
                if isLoading { SkeletonAnnouncer.announceLoading() }
            }
            .onChange(of: isLoading) { _, loading in
                if loading { SkeletonAnnouncer.announceLoading() }
            }
    }
}
