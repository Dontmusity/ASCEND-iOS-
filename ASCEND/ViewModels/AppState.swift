import Foundation
import Combine
import SwiftUI

@MainActor
final class AppState: ObservableObject {
    // MARK: Sesión
    @Published var isLoggedIn: Bool = false
    @Published var isOnboarded: Bool = false
    @Published var profile: UserProfile = UserProfile()

    // MARK: Calendario / carruseles
    @Published var events: [CalendarEvent] = DemoData.events
    @Published var reminders: [Reminder] = DemoData.reminders
    @Published var customLanes: [CustomLane] = []

    // MARK: Hábitos
    @Published var habits: [Habit] = DemoData.habits

    // MARK: Enfoque
    @Published var blockableApps: [BlockableApp] = DemoData.blockableApps
    @Published var isFocusSessionActive: Bool = false
    @Published var focusBlockMinutes: Int = 20
    @Published var focusSessionEndDate: Date? = nil
    @Published var focusMinutesToday: Int = 45
    @Published var phoneUsageMinutesToday: Int = 132 // dato demo, solo tiempo, nunca contenido

    // MARK: Vida
    @Published var todos: [TodoItem] = DemoData.todos
    @Published var expenses: [Expense] = DemoData.expenses
    @Published var tramites: [TramiteGuide] = DemoData.tramites
    @Published var resaleItems: [ResaleItem] = DemoData.resaleItems

    // MARK: Privacidad de gastos
    @Published var expensesHidden: Bool = true
    @Published var expensesPINEnabled: Bool = false
    @Published var expensesPIN: String = "1234"
    @Published var expensesUnlockedThisSession: Bool = false

    // MARK: Notificaciones
    @Published var notificationsPerDay: Int = 3
    @Published var quietHoursStart: Int = 22
    @Published var quietHoursEnd: Int = 8

    // MARK: Plan / referidos
    @Published var referralCode: String = "ASCEND-SOF214"
    @Published var referralCount: Int = 0
    @Published var redeemedTierCounts: Set<Int> = []
    @Published var proDaysRemaining: Int = 0

    /// Modelo demo simplificado: los hábitos se rastrean en días 1-30 (no calendario real),
    /// así que "hoy" se ancla al día del mes, no al día-del-año (ver DemoData.habits).
    private var today: Int { Calendar.current.component(.day, from: Date()) }

    // MARK: - Derivados generales

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let base: String
        switch hour {
        case 0..<12: base = "Buenos días"
        case 12..<19: base = "Buenas tardes"
        default: base = "Buenas noches"
        }
        let name = profile.name.isEmpty ? "" : ", \(profile.name)"
        return "\(base)\(name)"
    }

    /// Señal de intensidad de la semana: la usan Home y Ascender para bajar el ritmo, no solo pedir más.
    var weekIntensity: WeekIntensity {
        // El modelo actual solo guarda el calendario de "hoy" (CalendarEvent no tiene fecha),
        // así que el conteo de eventos de hoy es la mejor señal disponible como proxy de la semana.
        let todayEventCount = events.count
        let studyHabitsMissed = habits.filter { $0.area == .study && !isHabitDoneToday($0) }.count
        if todayEventCount >= 8 || studyHabitsMissed >= 2 {
            return .high
        } else if todayEventCount <= 3 {
            return .light
        }
        return .normal
    }

    /// Simula la lógica de Ascender con reglas contextuales basadas en el estado real de la app.
    var aiDaySummary: String {
        switch weekIntensity {
        case .high:
            return "Esta semana se ve intensa. Si puedes, deja algo para mañana — no tienes que con todo hoy."
        case .light:
            return "Hoy tienes el calendario más libre. Buen momento para descansar o adelantar algo sin presión."
        case .normal:
            return "Tienes \(events.count) actividades hoy. Vas con buen ritmo."
        }
    }

    // MARK: - Sesión

    func completeLogin() {
        isLoggedIn = true
    }

    func completeOnboarding(profile: UserProfile) {
        self.profile = profile
        isOnboarded = true
    }

    // MARK: - Hábitos / racha resiliente

    func toggleHabit(_ habit: Habit) {
        guard let index = habits.firstIndex(where: { $0.id == habit.id }) else { return }
        if habits[index].completedDays.contains(today) {
            habits[index].completedDays.remove(today)
        } else {
            habits[index].completedDays.insert(today)
        }
    }

    func isHabitDoneToday(_ habit: Habit) -> Bool {
        habit.completedDays.contains(today)
    }

    /// Unión de días con al menos un hábito cumplido — la racha nunca se borra por fallar un día,
    /// solo se muestra el progreso acumulado.
    private var activeDays: Set<Int> {
        habits.reduce(into: Set<Int>()) { $0.formUnion($1.completedDays) }
    }

    var accumulatedThisMonth: Int {
        // aproximación: días del 1 al 30 del "mes actual" en el modelo demo (day-of-year simplificado)
        activeDays.filter { $0 <= 30 }.count
    }

    func isActiveDay(_ dayOfMonth: Int) -> Bool {
        activeDays.contains(dayOfMonth)
    }

    var bestStreak: Int {
        let sorted = activeDays.sorted()
        guard !sorted.isEmpty else { return 0 }
        var best = 1
        var current = 1
        for i in 1..<sorted.count {
            if sorted[i] == sorted[i - 1] + 1 {
                current += 1
                best = max(best, current)
            } else {
                current = 1
            }
        }
        return best
    }

    var currentStreak: Int { consecutiveEndingToday() }

    private func consecutiveEndingToday() -> Int {
        var count = 0
        var day = today
        while activeDays.contains(day) {
            count += 1
            day -= 1
        }
        return count
    }

    // MARK: - Carruseles personalizados (máximo 3)

    var canAddCustomLane: Bool { customLanes.count < 3 }

    func addCustomLane(name: String, colorHex: String, icon: String, notificationsEnabled: Bool = false) {
        guard canAddCustomLane else { return }
        customLanes.append(CustomLane(name: name, colorHex: colorHex, icon: icon, notificationsEnabled: notificationsEnabled))
    }

    func renameCustomLane(_ lane: CustomLane, to newName: String) {
        guard let index = customLanes.firstIndex(where: { $0.id == lane.id }) else { return }
        customLanes[index].name = newName
    }

    /// Al eliminar un carrusel, sus eventos no se borran: pasan a mostrarse solo en "Todo".
    func deleteCustomLane(_ lane: CustomLane) {
        customLanes.removeAll { $0.id == lane.id }
        for index in events.indices where events[index].customLaneID == lane.id {
            events[index].customLaneID = nil
        }
    }

    func events(inCustomLane lane: CustomLane) -> [CalendarEvent] {
        events.filter { $0.customLaneID == lane.id }
    }

    func addEvent(_ event: CalendarEvent) {
        events.append(event)
    }

    // MARK: - Enfoque

    var vitalApps: [String] { DemoData.vitalApps }

    /// Segundos restantes calculados por reloj de pared (no por conteo local), así la sesión
    /// sigue viva aunque el usuario cambie de tab o la app pase a segundo plano.
    var focusSecondsRemaining: Int {
        guard let end = focusSessionEndDate else { return focusBlockMinutes * 60 }
        return max(0, Int(end.timeIntervalSinceNow.rounded()))
    }

    func startFocusSession(minutes: Int) {
        focusBlockMinutes = minutes
        focusSessionEndDate = Date().addingTimeInterval(TimeInterval(minutes * 60))
        isFocusSessionActive = true
    }

    func toggleBlock(_ app: BlockableApp) {
        guard let index = blockableApps.firstIndex(where: { $0.id == app.id }) else { return }
        blockableApps[index].isBlocked.toggle()
    }

    func unlockAllNow() {
        isFocusSessionActive = false
        focusSessionEndDate = nil
        for index in blockableApps.indices { blockableApps[index].isBlocked = false }
    }

    // MARK: - Vida: to-dos

    func toggleTodo(_ todo: TodoItem) {
        guard let index = todos.firstIndex(where: { $0.id == todo.id }) else { return }
        todos[index].isDone.toggle()
    }

    func postpone(_ todo: TodoItem) {
        // posponer sin penalización: solo se mueve al final de la lista
        guard let index = todos.firstIndex(where: { $0.id == todo.id }) else { return }
        let item = todos.remove(at: index)
        todos.append(item)
    }

    // MARK: - Vida: gastos privados

    var totalSpentMXN: Double { expenses.reduce(0) { $0 + $1.amountMXN } }
    var monthlyBudgetMXN: Double { DemoData.monthlyBudgetMXN }

    var antExpensesTotalMXN: Double {
        expenses.filter { $0.category == .fun_ }.reduce(0) { $0 + $1.amountMXN }
    }

    func deleteExpense(_ expense: Expense) {
        expenses.removeAll { $0.id == expense.id }
    }

    func addExpense(_ expense: Expense) {
        expenses.append(expense)
    }

    func deleteAllExpenses() {
        expenses.removeAll()
    }

    func exportExpensesCSV() -> String {
        var lines = ["title,amountMXN,category,date"]
        let formatter = ISO8601DateFormatter()
        for expense in expenses {
            let fields = [expense.title, "\(expense.amountMXN)", expense.category.rawValue, formatter.string(from: expense.date)]
            lines.append(fields.map(csvField).joined(separator: ","))
        }
        return lines.joined(separator: "\n")
    }

    /// Escapa comas/comillas y neutraliza fórmulas (=, +, -, @) para que el CSV no se rompa
    /// ni se ejecute como fórmula al abrirse en Excel/Sheets.
    private func csvField(_ raw: String) -> String {
        var value = raw
        if let first = value.first, "=+-@".contains(first) {
            value = "'" + value
        }
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }

    func unlockExpenses(withPIN pin: String) -> Bool {
        if pin == expensesPIN {
            expensesUnlockedThisSession = true
            return true
        }
        return false
    }

    // MARK: - Trámites

    func toggleStep(_ stepIndex: Int, in guide: TramiteGuide) {
        guard let index = tramites.firstIndex(where: { $0.id == guide.id }) else { return }
        if tramites[index].completedSteps.contains(stepIndex) {
            tramites[index].completedSteps.remove(stepIndex)
        } else {
            tramites[index].completedSteps.insert(stepIndex)
        }
    }

    // MARK: - Plan / referidos

    var isPro: Bool { proDaysRemaining > 0 }

    var referralTiers: [ReferralTier] { DemoData.referralTiers }

    var nextReferralTier: ReferralTier? {
        referralTiers.first { $0.count > referralCount }
    }

    /// Recompensas por paquetes cerrados, no acumulables ni proporcionales: solo se otorgan
    /// al llegar exactamente a un umbral (1 → 1 semana, 10 → 5 meses, 20 → 1 año).
    func simulateNewReferral() {
        referralCount += 1
        if let tier = referralTiers.first(where: { $0.count == referralCount }), !redeemedTierCounts.contains(tier.count) {
            redeemedTierCounts.insert(tier.count)
            proDaysRemaining += tier.rewardDays
        }
    }

    func buyMonthly() {
        proDaysRemaining += 30
    }

    func buyAnnual() {
        proDaysRemaining += 365
    }
}

enum WeekIntensity {
    case light, normal, high
}
