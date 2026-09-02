import SwiftUI

@main
struct ASCENDApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            Group {
                if !appState.isLoggedIn {
                    LoginView()
                } else if !appState.isOnboarded {
                    OnboardingView()
                } else {
                    RootView()
                }
            }
            .environmentObject(appState)
        }
    }
}
