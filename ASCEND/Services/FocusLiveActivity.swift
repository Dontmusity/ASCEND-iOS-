import Foundation
import ActivityKit

/// Enciende y apaga la Live Activity de la sesión de enfoque (pantalla de bloqueo e isla dinámica).
/// Requiere `NSSupportsLiveActivities = YES` en el Info.plist de la app (ver README → Widgets).
/// Si el usuario las desactivó, no pasa nada: la sesión sigue igual dentro de la app.
@MainActor
enum FocusLiveActivity {
    static func start(minutes: Int, subject: String?, endDate: Date) {
        end()
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let state = FocusActivityAttributes.ContentState(startDate: Date(), endDate: endDate)
        _ = try? Activity.request(
            attributes: FocusActivityAttributes(subject: subject, totalMinutes: minutes),
            content: ActivityContent(state: state, staleDate: endDate))
    }

    static func end() {
        for activity in Activity<FocusActivityAttributes>.activities {
            Task { await activity.end(nil, dismissalPolicy: .immediate) }
        }
    }
}
