import Foundation

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

    static func save(_ snapshot: AppSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    static func load() -> AppSnapshot? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(AppSnapshot.self, from: data)
    }

    /// Borra todo lo local. Lo usa "Cerrar sesión" (parcial) y "Eliminar cuenta" (completo).
    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
