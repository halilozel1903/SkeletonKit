import SwiftUI

enum DemoTab: Hashable {
    case profile
    case styles
}

struct ContentView: View {
    let scene: ScreenshotScene?

    @State private var tab: DemoTab

    init(scene: ScreenshotScene? = nil) {
        self.scene = scene
        _tab = State(initialValue: scene == .styles ? .styles : .profile)
    }

    var body: some View {
        TabView(selection: $tab) {
            ProfileFeedView(staysLoading: scene == .loading, isFrozen: scene != nil)
                .tabItem { Label("Profile", systemImage: "person.crop.circle") }
                .tag(DemoTab.profile)

            StylesView(isFrozen: scene != nil)
                .tabItem { Label("Styles", systemImage: "square.grid.2x2") }
                .tag(DemoTab.styles)
        }
    }
}

#Preview {
    ContentView()
}
