import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

/// Snapshot serializable de todo lo que el usuario configuró.
/// Se guarda en UserDefaults como JSON: no hay backend, así que este es el almacenamiento real.
struct AppSnapshot: Codable {
    var profile: UserProfile
    var education: UserEducation
    var classes: [SchoolClass]
    var assignments: [Assignment]
    var exams: [Exam]
    var studySessions: [StudySession]

    var activityKind: PhysicalActivityKind
    var workouts: [Workout]
    var workoutLogs: [WorkoutLog]
    var sports: [Sport]

    var meals: [Meal]
    var physicalGoal: PhysicalGoal

    var customActivities: [CustomActivity]
    var customLanes: [CustomLane]
    var freeTimeBlocks: [FreeTimeBlock]
    var manualEvents: [CalendarEvent]

    var habits: [Habit]
    var todos: [TodoItem]
    var goals: [Goal]
    var reminders: [Reminder]
    var tramites: [TramiteGuide]
    var resaleItems: [ResaleItem]

    var expenses: [Expense]
    var budget: Budget
    var expensesHidden: Bool
    var expensesPINEnabled: Bool
    var expensesPIN: String

    var notificationPrefs: NotificationPreferences
    var focusProfiles: [FocusProfile]

    var streakCount: Int
    var bestStreak: Int
    var lastStreakDate: Date?
    var activeDates: [Date]
    /// Opcional: los snapshots guardados antes de esta versión no traen esta clave.
    var entryCompletions: [String: Bool]?

    var proUntil: Date?
    var proPlanRaw: String?
    var proWillRenew: Bool
    var referralCode: String
    var referralCount: Int
    var redeemedTierCounts: [Int]

    var isOnboarded: Bool

    // Opcionales: snapshots guardados antes de esta versión no traen estas claves.
    var ageConfirmed18Plus: Bool?
    var legalAccepted: Bool?
    var legalAcceptedDate: Date?
}

enum Persistence {
    private static let key = "ascend.snapshot.v1"

    /// App Group compartido con los widgets. Debe coincidir con el de Signing & Capabilities
    /// de los DOS targets (app y ASCENDWidgets). Ver README → Widgets.
    static let appGroupID = "group.com.ascend.app"

    /// Si el App Group no está configurado, iOS devuelve un almacén local: la app sigue
    /// funcionando igual, solo que los widgets no ven los datos.
    private static var store: UserDefaults { UserDefaults(suiteName: appGroupID) ?? .standard }

    static func save(_ snapshot: AppSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        store.set(data, forKey: key)
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }

    static func load() -> AppSnapshot? {
        // Migración: versiones anteriores guardaban en UserDefaults.standard.
        if store.data(forKey: key) == nil, let legacy = UserDefaults.standard.data(forKey: key) {
            store.set(legacy, forKey: key)
            UserDefaults.standard.removeObject(forKey: key)
        }
        guard let data = store.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(AppSnapshot.self, from: data)
    }

    /// Borra todo lo local. Lo usa "Eliminar cuenta".
    static func clear() {
        store.removeObject(forKey: key)
        UserDefaults.standard.removeObject(forKey: key)
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }
}
