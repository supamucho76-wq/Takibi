import SwiftUI

@main
struct TakibiApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appModel)
                .preferredColorScheme(.dark)
        }
        .onChange(of: scenePhase) { _, newPhase in
            appModel.handleScenePhase(newPhase)
        }
    }
}

