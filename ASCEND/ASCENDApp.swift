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
            .task {
                await NotificationService.shared.refreshStatus()
                if appState.isOnboarded {
                    await NotificationService.shared.reschedule(state: appState)
                }
            }
        }
    }
}
