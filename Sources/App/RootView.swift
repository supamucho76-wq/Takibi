import SwiftUI

struct RootView: View {
    @EnvironmentObject private var appModel: AppModel

    var body: some View {
        Group {
            if !appModel.isReady {
                ZStack {
                    Color.black.ignoresSafeArea()
                    ProgressView().tint(.orange)
                }
            } else if !appModel.state.onboardingCompleted {
                OnboardingView()
            } else {
                HomeView()
            }
        }
    }
}

