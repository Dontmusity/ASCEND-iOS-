import SwiftUI

// MARK: - Tiempo

enum Weekday: Int, Codable, CaseIterable, Identifiable, Comparable {
    case monday = 1, tuesday, wednesday, thursday, friday, saturday, sunday

    var id: Int { rawValue }

    var short: String {
        switch self {
        case .monday: return "Lun"
        case .tuesday: return "Mar"
        case .wednesday: return "Mié"
        case .thursday: return "Jue"
        case .friday: return "Vie"
        case .saturday: return "Sáb"
        case .sunday: return "Dom"
        }
    }

    var full: String {
        switch self {
        case .monday: return "Lunes"
        case .tuesday: return "Martes"
        case .wednesday: return "Miércoles"
        case .thursday: return "Jueves"
        case .friday: return "Viernes"
        case .saturday: return "Sábado"
        case .sunday: return "Domingo"
        }
    }

    static func < (lhs: Weekday, rhs: Weekday) -> Bool { lhs.rawValue < rhs.rawValue }

    /// Calendar usa 1=domingo; aquí 1=lunes para que la semana empiece como se lee en México.
    /// nonisolated: son cálculos puros de fecha, no tocan estado de la app, y se usan como
    /// valores por defecto de parámetros (Swift no permite ahí un default MainActor-isolated).
    nonisolated static func from(_ date: Date) -> Weekday {
        let systemWeekday = Calendar.current.component(.weekday, from: date)
        let mondayBased = systemWeekday == 1 ? 7 : systemWeekday - 1
        return Weekday(rawValue: mondayBased) ?? .monday
    }

    nonisolated static var today: Weekday { from(Date()) }

    var next: Weekday { Weekday(rawValue: rawValue == 7 ? 1 : rawValue + 1) ?? .monday }
}

struct TimeOfDay: Codable, Hashable, Comparable {
    var hour: Int
    var minute: Int

    init(_ hour: Int, _ minute: Int = 0) {
        self.hour = min(max(hour, 0), 23)
        self.minute = min(max(minute, 0), 59)
    }

    var totalMinutes: Int { hour * 60 + minute }
    var asHours: Double { Double(hour) + Double(minute) / 60 }

    var label: String { String(format: "%02d:%02d", hour, minute) }

    static func < (lhs: TimeOfDay, rhs: TimeOfDay) -> Bool { lhs.totalMinutes < rhs.totalMinutes }

    nonisolated static var now: TimeOfDay {
        let parts = Calendar.current.dateComponents([.hour, .minute], from: Date())
        return TimeOfDay(parts.hour ?? 0, parts.minute ?? 0)
    }

    nonisolated static func from(_ date: Date) -> TimeOfDay {
        let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
        return TimeOfDay(parts.hour ?? 0, parts.minute ?? 0)
    }

    func adding(minutes: Int) -> TimeOfDay {
        let total = max(0, min(totalMinutes + minutes, 23 * 60 + 59))
        return TimeOfDay(total / 60, total % 60)
    }

    /// Fecha real de hoy (o del día indicado) a esta hora, para agendar notificaciones.
    func date(on day: Date = Date()) -> Date? {
        Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: day)
    }
}

// MARK: - Educación

enum EducationLevel: String, Codable, CaseIterable, Identifiable {
    case middleSchool = "Secundaria"
    case highSchool = "Preparatoria"
    case university = "Universidad / Carrera"
    case other = "Otro"
    case none = "No estudio"

    var id: String { rawValue }

    var studies: Bool { self != .none }
    var asksSemester: Bool { self == .highSchool || self == .university }
    var asksGrade: Bool { self == .middleSchool }
    var asksCareer: Bool { self == .university }
    var asksFreeText: Bool { self == .other }
}

struct UserEducation: Codable, Equatable {
    var level: EducationLevel = .none
    var grade: String = ""          // secundaria: 1°, 2°, 3°
    var semester: String = ""       // prepa / universidad
    var career: String = ""         // universidad
    var customStudy: String = ""    // "Otro"
    var schoolStart: TimeOfDay? = nil
    var schoolEnd: TimeOfDay? = nil

    var studies: Bool { level.studies }

    var summary: String {
        switch level {
        case .none: return "No estudia actualmente"
        case .middleSchool: return grade.isEmpty ? "Secundaria" : "Secundaria · \(grade)"
        case .highSchool: return semester.isEmpty ? "Preparatoria" : "Preparatoria · \(semester)"
        case .university:
            let parts = [career, semester].filter { !$0.isEmpty }
            return parts.isEmpty ? "Universidad" : parts.joined(separator: " · ")
        case .other: return customStudy.isEmpty ? "Otro" : customStudy
        }
    }
}

// MARK: - Escuela

struct SchoolClass: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var subject: String
    var days: [Weekday]
    var start: TimeOfDay
    var end: TimeOfDay
    var professor: String = ""
    var room: String = ""
    var reminder: ReminderOffset = .none
    var focusProfileID: UUID? = nil

    var daysLabel: String { days.sorted().map(\.short).joined(separator: ", ") }
    var timeLabel: String { "\(start.label) – \(end.label)" }
}

struct Assignment: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var subject: String
    var dueDate: Date
    /// Reutiliza TodoPriority (Models.swift) en vez de duplicar el mismo enum.
    var priority: TodoPriority = .medium
    var isDone: Bool = false
    var reminder: ReminderOffset = .none

    var daysRemaining: Int {
        Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: Date()), to: Calendar.current.startOfDay(for: dueDate)).day ?? 0
    }
}

struct Exam: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var subject: String
    var date: Date
    var reminder: ReminderOffset = .none

    var daysRemaining: Int {
        Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: Date()), to: Calendar.current.startOfDay(for: date)).day ?? 0
    }
}

struct StudySession: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var subject: String
    var minutes: Int
    var date: Date
}

// MARK: - Gimnasio y deporte

struct ExerciseSet: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var weightKg: Double
    var reps: Int
    var isCompleted: Bool = false

    var label: String {
        weightKg == 0 ? "\(reps) reps" : "\(weightKg.clean) kg × \(reps)"
    }
}

struct Exercise: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var sets: [ExerciseSet] = []
    var restSeconds: Int = 120
}

struct Workout: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String                 // "Pecho + Espalda"
    var days: [Weekday] = []
    var start: TimeOfDay? = nil
    var end: TimeOfDay? = nil
    var exercises: [Exercise] = []
    var reminder: ReminderOffset = .none
    var focusProfileID: UUID? = nil

    var daysLabel: String { days.sorted().map(\.short).joined(separator: ", ") }
}

/// Registro histórico: lo que realmente se levantó, para comparar "última vez" vs "hoy".
struct WorkoutLog: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var workoutName: String
    var date: Date
    var entries: [LoggedExercise]

    struct LoggedExercise: Codable, Equatable {
        var name: String
        var sets: [ExerciseSet]

        var bestSetLabel: String? {
            sets.max(by: { $0.weightKg < $1.weightKg })?.label
        }
    }
}

struct Sport: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var days: [Weekday]
    var start: TimeOfDay
    var end: TimeOfDay
    var reminder: ReminderOffset = .none

    var daysLabel: String { days.sorted().map(\.short).joined(separator: ", ") }
}

enum PhysicalActivityKind: String, Codable, CaseIterable, Identifiable {
    case gym = "Voy al gimnasio"
    case sport = "Practico un deporte"
    case both = "Hago ambos"
    case none = "Actualmente no"

    var id: String { rawValue }
    var includesGym: Bool { self == .gym || self == .both }
    var includesSport: Bool { self == .sport || self == .both }
}

// MARK: - Alimentación

struct Meal: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var time: TimeOfDay
    var reminder: ReminderOffset = .none
}

enum PhysicalGoal: String, Codable, CaseIterable, Identifiable {
    case loseFat = "Bajar peso · perder grasa"
    case definition = "Bajar peso · definición"
    case maintain = "Mantener composición actual"
    case gainMuscle = "Subir peso · masa muscular"
    case bulk = "Subir peso · volumen"
    case notSet = "Sin definir"

    var id: String { rawValue }

    var shortLabel: String {
        switch self {
        case .loseFat: return "Perder grasa"
        case .definition: return "Definición"
        case .maintain: return "Mantener"
        case .gainMuscle: return "Masa muscular"
        case .bulk: return "Volumen"
        case .notSet: return "Sin definir"
        }
    }
}

// MARK: - Actividades personalizadas

struct CustomActivity: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var category: String        // "Trabajo", "Hobby", "Lectura", o una creada por el usuario
    var icon: String = "star"
    var colorHex: String = "9E8AA8"
    var days: [Weekday]
    var start: TimeOfDay
    var end: TimeOfDay
    var reminder: ReminderOffset = .none
    var focusProfileID: UUID? = nil
    /// Si apunta a un CustomLane, esta actividad vive en ese carrusel propio.
    var laneID: UUID? = nil

    var daysLabel: String { days.sorted().map(\.short).joined(separator: ", ") }
}

// MARK: - Tiempo libre

struct FreeTimeBlock: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var days: [Weekday]
    var start: TimeOfDay
    var end: TimeOfDay
}

// MARK: - Metas

struct Milestone: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var isDone: Bool = false
}

struct Goal: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var detail: String = ""
    var milestones: [Milestone] = []
    var targetDate: Date? = nil
    var isPrimary: Bool = false

    var progress: Double {
        guard !milestones.isEmpty else { return 0 }
        return Double(milestones.filter(\.isDone).count) / Double(milestones.count)
    }
}

// MARK: - Enfoque

/// Perfil de bloqueo. El bloqueo real del sistema requiere el entitlement
/// com.apple.developer.family-controls (ver ScreenTimeService).
struct FocusProfile: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var blockedApps: [String] = []
    var isSystemBlockingEnabled: Bool = false
}

// MARK: - Notificaciones

enum ReminderOffset: Codable, Hashable, CaseIterable, Identifiable {
    case none
    case atTime
    case minutes(Int)

    static var allCases: [ReminderOffset] {
        [.none, .atTime, .minutes(5), .minutes(10), .minutes(15), .minutes(30), .minutes(60)]
    }

    var id: String { label }

    var label: String {
        switch self {
        case .none: return "Sin recordatorio"
        case .atTime: return "A la hora"
        case .minutes(let m): return m >= 60 ? "\(m / 60) h antes" : "\(m) min antes"
        }
    }

    var minutesBefore: Int? {
        switch self {
        case .none: return nil
        case .atTime: return 0
        case .minutes(let m): return m
        }
    }
}

struct NotificationPreferences: Codable, Equatable {
    var classes: Bool = true
    var assignments: Bool = true
    var exams: Bool = true
    var workouts: Bool = true
    var meals: Bool = false
    var goals: Bool = true
    var customActivities: Bool = true

    var maxPerDay: Int = 3
    var quietHoursStart: Int = 22
    var quietHoursEnd: Int = 8
}

// MARK: - Dinero

struct Budget: Codable, Equatable {
    var monthlyAmount: Double = 0
    var weeklyAmount: Double? = nil
    var categoryLimits: [String: Double] = [:]

    var isConfigured: Bool { monthlyAmount > 0 }
}

// MARK: - Suscripción

enum SubscriptionPlan: String, Codable {
    case monthly, annual, referral
}

enum SubscriptionState: Equatable {
    case free
    case trial(until: Date)
    case active(until: Date, plan: SubscriptionPlan, willRenew: Bool)
    case cancelled(activeUntil: Date)
    case expired

    var isPro: Bool {
        switch self {
        case .trial(let until): return until > Date()
        case .active(let until, _, _): return until > Date()
        case .cancelled(let until): return until > Date()
        case .free, .expired: return false
        }
    }

    var label: String {
        switch self {
        case .free: return "Plan Gratis"
        case .trial: return "Prueba activa"
        case .active: return "Pro activo"
        case .cancelled: return "Pro (cancelado)"
        case .expired: return "Pro expirado"
        }
    }

    var expirationDate: Date? {
        switch self {
        case .trial(let until): return until
        case .active(let until, _, _): return until
        case .cancelled(let until): return until
        case .free, .expired: return nil
        }
    }
}

// MARK: - Entrada unificada del calendario

/// Todo lo que ocupa un bloque de tiempo en el día se normaliza a esto para pintar el calendario.
/// No se persiste: se genera a partir de clases, workouts, deportes, comidas, actividades y eventos.
struct ScheduleEntry: Identifiable, Hashable {
    enum Source: Hashable {
        case schoolClass(UUID)
        case workout(UUID)
        case sport(UUID)
        case meal(UUID)
        case custom(UUID)
        case manual(UUID)
    }

    var id: String
    var title: String
    var subtitle: String?
    var start: TimeOfDay
    var end: TimeOfDay
    var lane: CalendarLane
    var colorHex: String
    var source: Source

    var color: Color { Color(hex: colorHex) }
    var timeLabel: String { "\(start.label) – \(end.label)" }
    var durationMinutes: Int { max(end.totalMinutes - start.totalMinutes, 15) }

    func isActive(at time: TimeOfDay = .now) -> Bool {
        time >= start && time < end
    }
}

// MARK: - Utilidades

extension Double {
    /// 100.0 → "100", 102.5 → "102.5"
    var clean: String {
        self == rounded() ? String(Int(self)) : String(format: "%.1f", self)
    }
}
