import SwiftUI

@main
struct SkeletonKitDemoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(scene: ScreenshotScene.current)
        }
    }
}
