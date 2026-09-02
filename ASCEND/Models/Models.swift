import SwiftUI

enum AcademicLoad: String, Codable, CaseIterable, Identifiable {
    case light = "Ligera"
    case moderate = "Moderada"
    case heavy = "Intensa"
    var id: String { rawValue }
}

struct UserProfile: Codable {
    var name: String = ""
    var university: String = ""
    var major: String = ""
    var livingSituation: String = ""
    var mainGoal: String = ""
    var academicLoad: AcademicLoad = .moderate
}

enum CalendarLane: String, Codable, CaseIterable, Identifiable {
    case all = "Todo"
    case school = "Escuela"
    case gym = "Gimnasio"
    case food = "Comida"
    case hobbies = "Hobbies"

    var id: String { rawValue }

    var accentColor: Color {
        switch self {
        case .all: return .ascendGold
        case .school: return Color(hex: "C9A15A")
        case .gym: return Color(hex: "A8785A")
        case .food: return Color(hex: "8FA173")
        case .hobbies: return Color(hex: "9E8AA8")
        }
    }

    var icon: String {
        switch self {
        case .all: return "square.stack.3d.up"
        case .school: return "book.closed"
        case .gym: return "figure.strengthtraining.traditional"
        case .food: return "fork.knife"
        case .hobbies: return "paintpalette"
        }
    }
}

/// Up to 3 user-created carousels (see doc Prompt 2, item 5).
struct CustomLane: Identifiable, Codable {
    let id: UUID
    var name: String
    var colorHex: String
    var icon: String
    var notificationsEnabled: Bool
    var notifyHour: Int

    init(id: UUID = UUID(), name: String, colorHex: String = "E8BC75", icon: String = "star", notificationsEnabled: Bool = false, notifyHour: Int = 9) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.icon = icon
        self.notificationsEnabled = notificationsEnabled
        self.notifyHour = notifyHour
    }

    var accentColor: Color { Color(hex: colorHex) }
}

struct CalendarEvent: Identifiable, Codable {
    let id: UUID
    var title: String
    var subtitle: String?
    var startHour: Double
    var durationHours: Double
    var lane: CalendarLane
    var customLaneID: UUID?

    init(id: UUID = UUID(), title: String, subtitle: String? = nil, startHour: Double, durationHours: Double, lane: CalendarLane, customLaneID: UUID? = nil) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.startHour = startHour
        self.durationHours = durationHours
        self.lane = lane
        self.customLaneID = customLaneID
    }
}

enum HabitArea: String, Codable, CaseIterable, Identifiable {
    case study = "Estudio"
    case health = "Salud"
    case money = "Dinero"
    case home = "Casa"
    case wellbeing = "Bienestar"
    var id: String { rawValue }

    var icon: String {
        switch self {
        case .study: return "book"
        case .health: return "heart"
        case .money: return "banknote"
        case .home: return "house"
        case .wellbeing: return "leaf"
        }
    }
}

struct Habit: Identifiable, Codable {
    let id: UUID
    var name: String
    var area: HabitArea
    var completedDays: Set<Int> // day-of-year markers, simplified demo model

    init(id: UUID = UUID(), name: String, area: HabitArea, completedDays: Set<Int> = []) {
        self.id = id
        self.name = name
        self.area = area
        self.completedDays = completedDays
    }

    var monthProgressText: String {
        "\(completedDays.count) de 30 días este mes"
    }
}

struct Reminder: Identifiable, Codable {
    let id: UUID
    var title: String
    var icon: String

    init(id: UUID = UUID(), title: String, icon: String) {
        self.id = id
        self.title = title
        self.icon = icon
    }
}

// MARK: - Vida (VIVIR)

enum LifeArea: String, Codable, CaseIterable, Identifiable {
    case school = "Escuela"
    case home = "Casa"
    case money = "Dinero"
    case procedures = "Trámites"
    case personal = "Personal"
    var id: String { rawValue }
}

enum TodoPriority: String, Codable, CaseIterable, Identifiable {
    case low = "Baja"
    case medium = "Media"
    case high = "Alta"
    var id: String { rawValue }
}

struct TodoItem: Identifiable, Codable {
    let id: UUID
    var title: String
    var area: LifeArea
    var priority: TodoPriority
    var isDone: Bool = false

    init(id: UUID = UUID(), title: String, area: LifeArea, priority: TodoPriority, isDone: Bool = false) {
        self.id = id
        self.title = title
        self.area = area
        self.priority = priority
        self.isDone = isDone
    }
}

enum ExpenseCategory: String, Codable, CaseIterable, Identifiable {
    case food = "Comida"
    case transport = "Transporte"
    case school = "Escuela"
    case fun_ = "Antojos"
    case home = "Casa"
    case other = "Otros"
    var id: String { rawValue }
}

struct Expense: Identifiable, Codable {
    let id: UUID
    var title: String
    var amountMXN: Double
    var category: ExpenseCategory
    var date: Date

    init(id: UUID = UUID(), title: String, amountMXN: Double, category: ExpenseCategory, date: Date) {
        self.id = id
        self.title = title
        self.amountMXN = amountMXN
        self.category = category
        self.date = date
    }
}

struct TramiteGuide: Identifiable, Codable {
    let id: UUID
    var title: String
    var steps: [String]
    var completedSteps: Set<Int>

    init(id: UUID = UUID(), title: String, steps: [String], completedSteps: Set<Int> = []) {
        self.id = id
        self.title = title
        self.steps = steps
        self.completedSteps = completedSteps
    }

    var progressText: String { "\(completedSteps.count) de \(steps.count) pasos" }
}

struct ResaleItem: Identifiable, Codable {
    let id: UUID
    var title: String
    var priceMXN: Double
    var seller: String

    init(id: UUID = UUID(), title: String, priceMXN: Double, seller: String) {
        self.id = id
        self.title = title
        self.priceMXN = priceMXN
        self.seller = seller
    }
}

// MARK: - Enfoque

struct BlockableApp: Identifiable, Codable {
    let id: UUID
    var name: String
    var icon: String
    var isBlocked: Bool

    init(id: UUID = UUID(), name: String, icon: String, isBlocked: Bool = false) {
        self.id = id
        self.name = name
        self.icon = icon
        self.isBlocked = isBlocked
    }
}

// MARK: - Suscripción / Referidos

struct ReferralTier {
    let count: Int
    let rewardDays: Int
    let label: String
}
