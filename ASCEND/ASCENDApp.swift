import SwiftUI

@main
struct ASCENDApp: App {
    @StateObject private var appState = AppState()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            Group {
                if !appState.isLoggedIn {
                    LoginView()
                } else if !appState.isOnboarded {
                    OnboardingView()
                } else if !appState.legalAccepted {
                    // Cuentas creadas antes de agregar el consentimiento legal: se les pide una sola vez.
                    LegalConsentGateView()
                } else {
                    RootView()
                }
            }
            .environmentObject(appState)
            .onChange(of: scenePhase) { _, phase in
                switch phase {
                case .active: appState.reloadFromDisk()   // lo que se marcó desde un widget
                case .background: appState.saveNow()      // que el widget vea lo último
                default: break
                }
            }
            .task {
                await NotificationService.shared.refreshStatus()
                if appState.isOnboarded {
                    await NotificationService.shared.reschedule(state: appState)
                }
            }
        }
    }
}
