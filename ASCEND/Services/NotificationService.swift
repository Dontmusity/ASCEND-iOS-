import Foundation
import UserNotifications

/// Notificaciones locales reales (UNUserNotificationCenter). No requiere backend ni
/// configuración externa: funciona en simulador y dispositivo.
@MainActor
final class NotificationService: ObservableObject {
    static let shared = NotificationService()

    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private let center = UNUserNotificationCenter.current()

    private init() {}

    func refreshStatus() async {
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    /// Se llama SOLO después de explicarle al usuario para qué sirven (punto 26).
    @discardableResult
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            await refreshStatus()
            return granted
        } catch {
            await refreshStatus()
            return false
        }
    }

    // MARK: - Reprogramación completa

    /// Borra lo pendiente y reprograma todo según la rutina y las preferencias actuales.
    /// Respeta horario silencioso y el máximo de notificaciones por día.
    func reschedule(state: AppState) async {
        center.removeAllPendingNotificationRequests()
        guard authorizationStatus == .authorized || authorizationStatus == .provisional else { return }

        let prefs = state.notificationPrefs
        var scheduledPerDay: [Int: Int] = [:]

        func canSchedule(weekday: Weekday, hour: Int) -> Bool {
            if isQuiet(hour: hour, prefs: prefs) { return false }
            let count = scheduledPerDay[weekday.rawValue] ?? 0
            guard count < prefs.maxPerDay else { return false }
            scheduledPerDay[weekday.rawValue] = count + 1
            return true
        }

        if prefs.classes {
            for item in state.classes {
                guard let offset = item.reminder.minutesBefore else { continue }
                let fire = item.start.adding(minutes: -offset)
                for day in item.days where canSchedule(weekday: day, hour: fire.hour) {
                    await schedule(
                        id: "class-\(item.id)-\(day.rawValue)",
                        title: item.subject,
                        body: item.room.isEmpty ? "Tu clase está por empezar." : "Salón \(item.room).",
                        weekday: day, time: fire)
                }
            }
        }

        if prefs.workouts {
            for workout in state.workouts {
                guard let start = workout.start, let offset = workout.reminder.minutesBefore else { continue }
                let fire = start.adding(minutes: -offset)
                for day in workout.days where canSchedule(weekday: day, hour: fire.hour) {
                    await schedule(
                        id: "workout-\(workout.id)-\(day.rawValue)",
                        title: workout.name, body: "Tu entrenamiento está por empezar.",
                        weekday: day, time: fire)
                }
            }
            for sport in state.sports {
                guard let offset = sport.reminder.minutesBefore else { continue }
                let fire = sport.start.adding(minutes: -offset)
                for day in sport.days where canSchedule(weekday: day, hour: fire.hour) {
                    await schedule(
                        id: "sport-\(sport.id)-\(day.rawValue)",
                        title: sport.name, body: "Tu entrenamiento está por empezar.",
                        weekday: day, time: fire)
                }
            }
        }

        if prefs.meals {
            for meal in state.meals {
                guard let offset = meal.reminder.minutesBefore else { continue }
                let fire = meal.time.adding(minutes: -offset)
                for day in Weekday.allCases where canSchedule(weekday: day, hour: fire.hour) {
                    await schedule(
                        id: "meal-\(meal.id)-\(day.rawValue)",
                        title: meal.name, body: "Un recordatorio amable, sin presión.",
                        weekday: day, time: fire)
                }
            }
        }

        if prefs.customActivities {
            for activity in state.customActivities {
                guard let offset = activity.reminder.minutesBefore else { continue }
                let fire = activity.start.adding(minutes: -offset)
                for day in activity.days where canSchedule(weekday: day, hour: fire.hour) {
                    await schedule(
                        id: "custom-\(activity.id)-\(day.rawValue)",
                        title: activity.name, body: activity.category,
                        weekday: day, time: fire)
                }
            }
        }

        if prefs.assignments {
            for item in state.assignments where !item.isDone {
                guard let offset = item.reminder.minutesBefore,
                      let fireDate = Calendar.current.date(byAdding: .minute, value: -offset, to: item.dueDate),
                      fireDate > Date(),
                      !isQuiet(hour: Calendar.current.component(.hour, from: fireDate), prefs: prefs)
                else { continue }
                await schedule(id: "assignment-\(item.id)", title: item.title,
                               body: "Entrega de \(item.subject).", date: fireDate)
            }
        }

        if prefs.exams {
            for exam in state.exams where exam.daysRemaining >= 0 {
                guard let offset = exam.reminder.minutesBefore,
                      let fireDate = Calendar.current.date(byAdding: .minute, value: -offset, to: exam.date),
                      fireDate > Date(),
                      !isQuiet(hour: Calendar.current.component(.hour, from: fireDate), prefs: prefs)
                else { continue }
                await schedule(id: "exam-\(exam.id)", title: "Examen: \(exam.subject)",
                               body: exam.title, date: fireDate)
            }
        }
    }

    /// Nunca de madrugada: respeta el horario silencioso configurado en Ajustes.
    private func isQuiet(hour: Int, prefs: NotificationPreferences) -> Bool {
        if prefs.quietHoursStart > prefs.quietHoursEnd {
            return hour >= prefs.quietHoursStart || hour < prefs.quietHoursEnd
        }
        return hour >= prefs.quietHoursStart && hour < prefs.quietHoursEnd
    }

    private func schedule(id: String, title: String, body: String, weekday: Weekday, time: TimeOfDay) async {
        var components = DateComponents()
        // Calendar usa 1=domingo; Weekday usa 1=lunes.
        components.weekday = weekday == .sunday ? 1 : weekday.rawValue + 1
        components.hour = time.hour
        components.minute = time.minute
        await add(id: id, title: title, body: body,
                  trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: true))
    }

    private func schedule(id: String, title: String, body: String, date: Date) async {
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        await add(id: id, title: title, body: body,
                  trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false))
    }

    private func add(id: String, title: String, body: String, trigger: UNNotificationTrigger) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        try? await center.add(request)
    }

    func cancelAll() {
        center.removeAllPendingNotificationRequests()
    }
}
