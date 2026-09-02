import Foundation
import Combine

#if canImport(FamilyControls)
import FamilyControls
import ManagedSettings
#endif

/// Bloqueo real de apps con las APIs oficiales de Apple (FamilyControls / ManagedSettings).
///
/// IMPORTANTE — configuración externa requerida (no se puede resolver solo con código):
/// 1. Cuenta del Apple Developer Program (de pago).
/// 2. Solicitar y que Apple apruebe el entitlement `com.apple.developer.family-controls`
///    (https://developer.apple.com/contact/request/family-controls-distribution).
/// 3. Activar la capability "Family Controls" en Signing & Capabilities del target.
/// Sin esos tres pasos, `requestAuthorization()` falla en tiempo de ejecución y la app
/// sigue funcionando normal, solo que sin bloqueo del sistema. No se usan APIs privadas.
@MainActor
final class ScreenTimeService: ObservableObject {
    static let shared = ScreenTimeService()

    @Published private(set) var isAuthorized = false
    @Published private(set) var lastError: String?

    private init() {}

    static var availabilityNote: String {
        #if canImport(FamilyControls)
        return "El bloqueo real de apps usa Screen Time de Apple y requiere un permiso especial de Apple (entitlement Family Controls). Mientras tanto, el modo de enfoque funciona como recordatorio."
        #else
        return "El bloqueo de apps no está disponible en esta plataforma."
        #endif
    }

    func requestAuthorization() async {
        #if canImport(FamilyControls)
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            isAuthorized = AuthorizationCenter.shared.authorizationStatus == .approved
            lastError = nil
        } catch {
            isAuthorized = false
            lastError = "No se pudo activar el bloqueo del sistema. Requiere el permiso Family Controls de Apple."
        }
        #else
        lastError = "Screen Time no está disponible en esta plataforma."
        #endif
    }

    #if canImport(FamilyControls)
    private let store = ManagedSettingsStore(named: .init("ascend.focus"))

    /// Aplica el escudo a la selección hecha por el usuario en el picker del sistema.
    func startShielding(selection: FamilyActivitySelection) {
        guard isAuthorized else { return }
        store.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        store.shield.applicationCategories = selection.categoryTokens.isEmpty
            ? nil
            : .specific(selection.categoryTokens)
    }

    /// Siempre reversible: "Desbloquear ahora" nunca deja al usuario atrapado.
    func stopShielding() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
    }
    #else
    func stopShielding() {}
    #endif
}
