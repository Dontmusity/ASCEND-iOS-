import SwiftUI

@main
struct ASCENDApp: App {
    @StateObject private var appState = AppState()
    @Environment(\.scenePhase) private var scenePhase
    /// Preferencia de apariencia de este dispositivo: "system", "light" o "dark".
    @AppStorage("ascend.appearance") private var appearance = "system"

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
            .preferredColorScheme(appearance == "dark" ? .dark : appearance == "light" ? .light : nil)
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
