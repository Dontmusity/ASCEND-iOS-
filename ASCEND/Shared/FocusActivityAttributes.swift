import Foundation
#if canImport(ActivityKit)
import ActivityKit

/// Live Activity de la sesión de enfoque. Va en los DOS targets (app y ASCENDWidgets).
struct FocusActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var startDate: Date
        var endDate: Date
    }

    var subject: String?
    var totalMinutes: Int
}
#endif

/// Enlaces que abren los widgets y la Live Activity. Los maneja RootView con `.onOpenURL`.
enum AscendLink {
    static let today = URL(string: "ascend://today")!
    static let habits = URL(string: "ascend://habits")!
    static let focus = URL(string: "ascend://focus")!
    static let unlockFocus = URL(string: "ascend://focus/unlock")!
}
