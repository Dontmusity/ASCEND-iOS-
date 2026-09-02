import Foundation
import Combine
import SwiftUI

@MainActor
final class AppState: ObservableObject {

    // MARK: Sesión
    @Published var isLoggedIn: Bool = false
    @Published var isOnboarded: Bool = false
    @Published var profile: UserProfile = UserProfile()

    // MARK: Escuela
    @Published var education = UserEducation()
    @Published var classes: [SchoolClass] = []
    @Published var assignments: [Assignment] = []
    @Published var exams: [Exam] = []
    @Published var studySessions: [StudySession] = []

    // MARK: Actividad física
    @Published var activityKind: PhysicalActivityKind = .none
    @Published var workouts: [Workout] = []
    @Published var workoutLogs: [WorkoutLog] = []
    @Published var sports: [Sport] = []

    // MARK: Alimentación
    @Published var meals: [Meal] = []
    @Published var physicalGoal: PhysicalGoal = .notSet

    // MARK: Rutina personalizada
    @Published var customActivities: [CustomActivity] = []
    @Published var customLanes: [CustomLane] = []
    @Published var freeTimeBlocks: [FreeTimeBlock] = []
    @Published var manualEvents: [CalendarEvent] = []

    // MARK: Vida
    @Published var habits: [Habit] = []
    @Published var todos: [TodoItem] = []
    @Published var goals: [Goal] = []
    @Published var reminders: [Reminder] = []
    @Published var tramites: [TramiteGuide] = DemoData.tramites // guías informativas, no datos inventados del usuario
    @Published var resaleItems: [ResaleItem] = []

    // MARK: Dinero
    @Published var expenses: [Expense] = []
    @Published var budget = Budget()
    @Published var expensesHidden: Bool = true
    @Published var expensesPINEnabled: Bool = false
    @Published var expensesPIN: String = ""
    @Published var expensesUnlockedThisSession: Bool = false

    // MARK: Enfoque
    @Published var focusProfiles: [FocusProfile] = []
    @Published var isFocusSessionActive: Bool = false
    @Published var focusBlockMinutes: Int = 20
    @Published var focusSessionEndDate: Date? = nil

    // MARK: Notificaciones
    @Published var notificationPrefs = NotificationPreferences()

    // MARK: Racha
    @Published private(set) var activeDates: Set<Date> = []
    @Published private(set) var bestStreak: Int = 0

    // MARK: Suscripción / referidos
    @Published var proUntil: Date? = nil
    @Published var proPlan: SubscriptionPlan? = nil
    @Published var proWillRenew: Bool = false
    @Published var referralCode: String = ""
    @Published var referralCount: Int = 0
    @Published var redeemedTierCounts: Set<Int> = []

    private var cancellables = Set<AnyCancellable>()

    init() {
        restore()
        // Guarda solo cuando algo cambia de verdad, sin ensuciar cada método con una llamada a save().
        objectWillChange
            .debounce(for: .seconds(0.8), scheduler: RunLoop.main)
            .sink { [weak self] in self?.persist() }
            .store(in: &cancellables)
    }

    // MARK: - Persistencia

    private func snapshot() -> AppSnapshot {
        AppSnapshot(
            profile: profile, education: education, classes: classes, assignments: assignments,
            exams: exams, studySessions: studySessions, activityKind: activityKind,
            workouts: workouts, workoutLogs: workoutLogs, sports: sports, meals: meals,
            physicalGoal: physicalGoal, customActivities: customActivities, customLanes: customLanes,
            freeTimeBlocks: freeTimeBlocks, manualEvents: manualEvents, habits: habits, todos: todos,
            goals: goals, reminders: reminders, tramites: tramites, resaleItems: resaleItems,
            expenses: expenses, budget: budget, expensesHidden: expensesHidden,
            expensesPINEnabled: expensesPINEnabled, expensesPIN: expensesPIN,
            notificationPrefs: notificationPrefs, focusProfiles: focusProfiles,
            streakCount: currentStreak, bestStreak: bestStreak, lastStreakDate: activeDates.max(),
            activeDates: Array(activeDates), proUntil: proUntil, proPlanRaw: proPlan?.rawValue,
            proWillRenew: proWillRenew, referralCode: referralCode, referralCount: referralCount,
            redeemedTierCounts: Array(redeemedTierCounts), isOnboarded: isOnboarded
        )
    }

    private func persist() {
        Persistence.save(snapshot())
    }

    private func restore() {
        guard let s = Persistence.load() else {
            referralCode = Self.makeReferralCode()
            return
        }
        profile = s.profile; education = s.education; classes = s.classes
        assignments = s.assignments; exams = s.exams; studySessions = s.studySessions
        activityKind = s.activityKind; workouts = s.workouts; workoutLogs = s.workoutLogs
        sports = s.sports; meals = s.meals; physicalGoal = s.physicalGoal
        customActivities = s.customActivities; customLanes = s.customLanes
        freeTimeBlocks = s.freeTimeBlocks; manualEvents = s.manualEvents
        habits = s.habits; todos = s.todos; goals = s.goals; reminders = s.reminders
        tramites = s.tramites; resaleItems = s.resaleItems
        expenses = s.expenses; budget = s.budget; expensesHidden = s.expensesHidden
        expensesPINEnabled = s.expensesPINEnabled; expensesPIN = s.expensesPIN
        notificationPrefs = s.notificationPrefs; focusProfiles = s.focusProfiles
        bestStreak = s.bestStreak; activeDates = Set(s.activeDates)
        proUntil = s.proUntil; proWillRenew = s.proWillRenew
        proPlan = s.proPlanRaw.flatMap(SubscriptionPlan.init(rawValue:))
        referralCode = s.referralCode.isEmpty ? Self.makeReferralCode() : s.referralCode
        referralCount = s.referralCount; redeemedTierCounts = Set(s.redeemedTierCounts)
        isOnboarded = s.isOnboarded
        isLoggedIn = s.isOnboarded // si ya completó onboarding antes, la sesión local sigue viva
    }

    private static func makeReferralCode() -> String {
        let suffix = String(UUID().uuidString.prefix(6)).uppercased()
        return "ASCEND-\(suffix)"
    }

    // MARK: - Sesión

    func completeLogin() {
        isLoggedIn = true
    }

    func completeOnboarding() {
        isOnboarded = true
        markActiveToday() // Day 1 arranca aquí, no en 0
    }

    /// Cierra sesión sin borrar la rutina configurada: al volver a entrar sigue todo ahí.
    func logOut() {
        isLoggedIn = false
        expensesUnlockedThisSession = false
        unlockAllNow()
        persist()
    }

    /// Borra de verdad todos los datos locales. No hay backend que llamar (ver README).
    func deleteAccount() {
        Persistence.clear()
        profile = UserProfile(); education = UserEducation(); classes = []; assignments = []
        exams = []; studySessions = []; activityKind = .none; workouts = []; workoutLogs = []
        sports = []; meals = []; physicalGoal = .notSet; customActivities = []; customLanes = []
        freeTimeBlocks = []; manualEvents = []; habits = []; todos = []; goals = []; reminders = []
        resaleItems = []; expenses = []; budget = Budget(); expensesHidden = true
        expensesPINEnabled = false; expensesPIN = ""; notificationPrefs = NotificationPreferences()
        focusProfiles = []; activeDates = []; bestStreak = 0; proUntil = nil; proPlan = nil
        referralCount = 0; redeemedTierCounts = []; referralCode = Self.makeReferralCode()
        isOnboarded = false; isLoggedIn = false
    }

    // MARK: - Contexto del día

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let base: String
        switch hour {
        case 0..<12: base = "Buenos días"
        case 12..<19: base = "Buenas tardes"
        default: base = "Buenas noches"
        }
        return profile.name.isEmpty ? base : "\(base), \(profile.name)"
    }

    /// Todas las actividades de un día, generadas SOLO con lo que el usuario configuró.
    func entries(for weekday: Weekday = .today, lane: CalendarLane = .all) -> [ScheduleEntry] {
        var result: [ScheduleEntry] = []

        if lane == .all || lane == .school {
            for item in classes where item.days.contains(weekday) {
                result.append(ScheduleEntry(
                    id: "class-\(item.id)", title: item.subject,
                    subtitle: [item.room, item.professor].filter { !$0.isEmpty }.joined(separator: " · "),
                    start: item.start, end: item.end, lane: .school,
                    colorHex: "C9A15A", source: .schoolClass(item.id)))
            }
        }

        if lane == .all || lane == .gym {
            for workout in workouts where workout.days.contains(weekday) {
                if let start = workout.start, let end = workout.end {
                    result.append(ScheduleEntry(
                        id: "workout-\(workout.id)", title: workout.name,
                        subtitle: workout.exercises.isEmpty ? nil : "\(workout.exercises.count) ejercicios",
                        start: start, end: end, lane: .gym,
                        colorHex: "A8785A", source: .workout(workout.id)))
                }
            }
            for sport in sports where sport.days.contains(weekday) {
                result.append(ScheduleEntry(
                    id: "sport-\(sport.id)", title: sport.name, subtitle: "Deporte",
                    start: sport.start, end: sport.end, lane: .gym,
                    colorHex: "A8785A", source: .sport(sport.id)))
            }
        }

        if lane == .all || lane == .food {
            for meal in meals {
                result.append(ScheduleEntry(
                    id: "meal-\(meal.id)", title: meal.name, subtitle: nil,
                    start: meal.time, end: meal.time.adding(minutes: 30), lane: .food,
                    colorHex: "8FA173", source: .meal(meal.id)))
            }
        }

        if lane == .all || lane == .hobbies {
            for activity in customActivities where activity.days.contains(weekday) && (lane == .all || activity.laneID == nil) {
                result.append(ScheduleEntry(
                    id: "custom-\(activity.id)", title: activity.name, subtitle: activity.category,
                    start: activity.start, end: activity.end, lane: .hobbies,
                    colorHex: activity.colorHex, source: .custom(activity.id)))
            }
        }

        if lane == .all {
            for event in manualEvents where event.customLaneID == nil {
                result.append(entry(from: event))
            }
        }

        return result.sorted { $0.start < $1.start }
    }

    func entries(inCustomLane lane: CustomLane, weekday: Weekday = .today) -> [ScheduleEntry] {
        var result: [ScheduleEntry] = customActivities
            .filter { $0.laneID == lane.id && $0.days.contains(weekday) }
            .map { activity in
                ScheduleEntry(
                    id: "custom-\(activity.id)", title: activity.name, subtitle: activity.category,
                    start: activity.start, end: activity.end, lane: .hobbies,
                    colorHex: lane.colorHex, source: .custom(activity.id))
            }
        result += manualEvents.filter { $0.customLaneID == lane.id }.map(entry(from:))
        return result.sorted { $0.start < $1.start }
    }

    private func entry(from event: CalendarEvent) -> ScheduleEntry {
        let start = TimeOfDay(Int(event.startHour), Int((event.startHour - Double(Int(event.startHour))) * 60))
        return ScheduleEntry(
            id: "event-\(event.id)", title: event.title, subtitle: event.subtitle,
            start: start, end: start.adding(minutes: Int(event.durationHours * 60)),
            lane: event.lane, colorHex: "E8BC75", source: .manual(event.id))
    }

    /// Actividad en curso ahora mismo (punto 43).
    var currentEntry: ScheduleEntry? {
        entries().first { $0.isActive() }
    }

    var nextEntry: ScheduleEntry? {
        entries().first { $0.start > TimeOfDay.now }
    }

    func minutesRemaining(of entry: ScheduleEntry) -> Int {
        max(0, entry.end.totalMinutes - TimeOfDay.now.totalMinutes)
    }

    /// Huecos libres reales: lo que queda entre actividades, más lo que el usuario marcó a mano.
    /// Solo se usa para sugerir; nunca se rellena automáticamente.
    func freeSlots(for weekday: Weekday = .today) -> [(start: TimeOfDay, end: TimeOfDay)] {
        let dayStart = education.schoolStart ?? TimeOfDay(8)
        let dayEnd = TimeOfDay(22)
        let busy = entries(for: weekday).sorted { $0.start < $1.start }

        var slots: [(TimeOfDay, TimeOfDay)] = []
        var cursor = dayStart
        for entry in busy {
            if entry.start.totalMinutes - cursor.totalMinutes >= 30 {
                slots.append((cursor, entry.start))
            }
            if entry.end > cursor { cursor = entry.end }
        }
        if dayEnd.totalMinutes - cursor.totalMinutes >= 30 {
            slots.append((cursor, dayEnd))
        }
        return slots
    }

    /// Señal de carga del día basada en datos reales del usuario, no en un demo.
    var weekIntensity: WeekIntensity {
        let todayCount = entries().count
        let urgentWork = assignments.filter { !$0.isDone && $0.daysRemaining <= 2 }.count
            + exams.filter { $0.daysRemaining >= 0 && $0.daysRemaining <= 3 }.count
        if todayCount >= 8 || urgentWork >= 3 { return .high }
        if todayCount <= 2 && urgentWork == 0 { return .light }
        return .normal
    }

    var aiDaySummary: String {
        if !isOnboarded || entries().isEmpty {
            return "Todavía no hay nada en tu día. Agrega lo que quieras y ASCEND lo organiza."
        }
        switch weekIntensity {
        case .high:
            return "Hoy se ve cargado. Si puedes, deja algo para mañana — no tienes que con todo hoy."
        case .light:
            return "Tienes un día tranquilo. Buen momento para descansar o adelantar algo sin presión."
        case .normal:
            return "Tienes \(entries().count) actividades hoy. Vas con buen ritmo."
        }
    }

    // MARK: - Escuela

    var subjects: [String] {
        Array(Set(classes.map(\.subject))).sorted()
    }

    func classes(on weekday: Weekday) -> [SchoolClass] {
        classes.filter { $0.days.contains(weekday) }.sorted { $0.start < $1.start }
    }

    func assignments(for subject: String) -> [Assignment] {
        assignments.filter { $0.subject == subject && !$0.isDone }.sorted { $0.dueDate < $1.dueDate }
    }

    func exams(for subject: String) -> [Exam] {
        exams.filter { $0.subject == subject && $0.daysRemaining >= 0 }.sorted { $0.date < $1.date }
    }

    var pendingAssignments: [Assignment] {
        assignments.filter { !$0.isDone }.sorted { $0.dueDate < $1.dueDate }
    }

    var upcomingExams: [Exam] {
        exams.filter { $0.daysRemaining >= 0 }.sorted { $0.date < $1.date }
    }

    func studyMinutesThisWeek(for subject: String) -> Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return studySessions.filter { $0.subject == subject && $0.date >= weekAgo }.reduce(0) { $0 + $1.minutes }
    }

    func nextClass(for subject: String) -> (SchoolClass, Weekday)? {
        var day = Weekday.today
        for offset in 0..<8 {
            let candidates = classes.filter { $0.days.contains(day) && $0.subject == subject }
                .filter { offset > 0 || $0.start > TimeOfDay.now }
                .sorted { $0.start < $1.start }
            if let first = candidates.first { return (first, day) }
            day = day.next
            _ = offset
        }
        return nil
    }

    /// Sugerencia de estudio: la materia con examen o entrega más cercana. Solo sugiere.
    var studySuggestion: (subject: String, reason: String, minutes: Int)? {
        if let exam = upcomingExams.first, exam.daysRemaining <= 7 {
            let days = exam.daysRemaining
            let when = days == 0 ? "hoy" : days == 1 ? "mañana" : "en \(days) días"
            return (exam.subject, "Examen de \(exam.subject) \(when)", 45)
        }
        if let assignment = pendingAssignments.first, assignment.daysRemaining <= 3 {
            let days = assignment.daysRemaining
            let when = days <= 0 ? "hoy" : days == 1 ? "mañana" : "en \(days) días"
            return (assignment.subject, "\(assignment.title) se entrega \(when)", 30)
        }
        return nil
    }

    func addClass(_ item: SchoolClass) { classes.append(item) }
    func updateClass(_ item: SchoolClass) {
        guard let i = classes.firstIndex(where: { $0.id == item.id }) else { return }
        classes[i] = item
    }
    func deleteClass(_ item: SchoolClass) { classes.removeAll { $0.id == item.id } }

    func addAssignment(_ item: Assignment) { assignments.append(item) }
    func toggleAssignment(_ item: Assignment) {
        guard let i = assignments.firstIndex(where: { $0.id == item.id }) else { return }
        assignments[i].isDone.toggle()
        if assignments[i].isDone { markActiveToday() }
    }
    func deleteAssignment(_ item: Assignment) { assignments.removeAll { $0.id == item.id } }

    func addExam(_ item: Exam) { exams.append(item) }
    func deleteExam(_ item: Exam) { exams.removeAll { $0.id == item.id } }

    func logStudySession(subject: String, minutes: Int) {
        studySessions.append(StudySession(subject: subject, minutes: minutes, date: Date()))
        markActiveToday()
    }

    // MARK: - Gimnasio

    func workout(for weekday: Weekday = .today) -> Workout? {
        workouts.first { $0.days.contains(weekday) }
    }

    func addWorkout(_ workout: Workout) { workouts.append(workout) }
    func updateWorkout(_ workout: Workout) {
        guard let i = workouts.firstIndex(where: { $0.id == workout.id }) else { return }
        workouts[i] = workout
    }
    func deleteWorkout(_ workout: Workout) { workouts.removeAll { $0.id == workout.id } }

    /// Última vez que se hizo este ejercicio, para comparar progreso.
    func lastLog(for exerciseName: String) -> WorkoutLog.LoggedExercise? {
        workoutLogs
            .sorted { $0.date > $1.date }
            .compactMap { $0.entries.first { $0.name == exerciseName } }
            .first
    }

    func finishWorkout(_ workout: Workout) {
        let entries = workout.exercises.map {
            WorkoutLog.LoggedExercise(name: $0.name, sets: $0.sets.filter(\.isCompleted))
        }.filter { !$0.sets.isEmpty }
        guard !entries.isEmpty else { return }
        workoutLogs.append(WorkoutLog(workoutName: workout.name, date: Date(), entries: entries))
        markActiveToday()
    }

    func addSport(_ sport: Sport) { sports.append(sport) }
    func deleteSport(_ sport: Sport) { sports.removeAll { $0.id == sport.id } }

    // MARK: - Comidas

    func addMeal(_ meal: Meal) { meals.append(meal); meals.sort { $0.time < $1.time } }
    func updateMeal(_ meal: Meal) {
        guard let i = meals.firstIndex(where: { $0.id == meal.id }) else { return }
        meals[i] = meal
        meals.sort { $0.time < $1.time }
    }
    func deleteMeal(_ meal: Meal) { meals.removeAll { $0.id == meal.id } }

    // MARK: - Actividades y carruseles personalizados

    var canAddCustomLane: Bool { customLanes.count < 3 }

    func addCustomLane(name: String, colorHex: String, icon: String, notificationsEnabled: Bool = false) {
        guard canAddCustomLane else { return }
        customLanes.append(CustomLane(name: name, colorHex: colorHex, icon: icon, notificationsEnabled: notificationsEnabled))
    }

    func renameCustomLane(_ lane: CustomLane, to newName: String) {
        guard let i = customLanes.firstIndex(where: { $0.id == lane.id }) else { return }
        customLanes[i].name = newName
    }

    /// Al eliminar un carrusel las actividades no se borran: vuelven a la vista general.
    func deleteCustomLane(_ lane: CustomLane) {
        customLanes.removeAll { $0.id == lane.id }
        for i in customActivities.indices where customActivities[i].laneID == lane.id {
            customActivities[i].laneID = nil
        }
        for i in manualEvents.indices where manualEvents[i].customLaneID == lane.id {
            manualEvents[i].customLaneID = nil
        }
    }

    func addCustomActivity(_ activity: CustomActivity) { customActivities.append(activity) }
    func updateCustomActivity(_ activity: CustomActivity) {
        guard let i = customActivities.firstIndex(where: { $0.id == activity.id }) else { return }
        customActivities[i] = activity
    }
    func deleteCustomActivity(_ activity: CustomActivity) { customActivities.removeAll { $0.id == activity.id } }

    func addEvent(_ event: CalendarEvent) { manualEvents.append(event) }
    func deleteEvent(id: UUID) { manualEvents.removeAll { $0.id == id } }

    /// Borra cualquier entrada del calendario desde la vista, sin importar de dónde venga.
    func delete(entry: ScheduleEntry) {
        switch entry.source {
        case .schoolClass(let id): classes.removeAll { $0.id == id }
        case .workout(let id): workouts.removeAll { $0.id == id }
        case .sport(let id): sports.removeAll { $0.id == id }
        case .meal(let id): meals.removeAll { $0.id == id }
        case .custom(let id): customActivities.removeAll { $0.id == id }
        case .manual(let id): manualEvents.removeAll { $0.id == id }
        }
    }

    // MARK: - Hábitos y racha

    func addHabit(_ habit: Habit) { habits.append(habit) }
    func deleteHabit(_ habit: Habit) { habits.removeAll { $0.id == habit.id } }

    private var todayKey: Date { Calendar.current.startOfDay(for: Date()) }

    func toggleHabit(_ habit: Habit) {
        guard let i = habits.firstIndex(where: { $0.id == habit.id }) else { return }
        let day = Calendar.current.component(.day, from: Date())
        if habits[i].completedDays.contains(day) {
            habits[i].completedDays.remove(day)
        } else {
            habits[i].completedDays.insert(day)
            markActiveToday()
        }
    }

    func isHabitDoneToday(_ habit: Habit) -> Bool {
        habit.completedDays.contains(Calendar.current.component(.day, from: Date()))
    }

    /// Marca el día como activo. Set de fechas ⇒ abrir la app 20 veces no infla la racha.
    func markActiveToday() {
        guard !activeDates.contains(todayKey) else { return }
        activeDates.insert(todayKey)
        bestStreak = max(bestStreak, currentStreak)
    }

    /// Días consecutivos terminando hoy (o ayer, para no castigar antes de que acabe el día).
    var currentStreak: Int {
        let calendar = Calendar.current
        var count = 0
        var day = todayKey
        if !activeDates.contains(day) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: day),
                  activeDates.contains(yesterday) else { return 0 }
            day = yesterday
        }
        while activeDates.contains(day) {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return count
    }

    var accumulatedThisMonth: Int {
        let calendar = Calendar.current
        let now = Date()
        return activeDates.filter {
            calendar.component(.month, from: $0) == calendar.component(.month, from: now)
                && calendar.component(.year, from: $0) == calendar.component(.year, from: now)
        }.count
    }

    func isActiveDay(_ dayOfMonth: Int) -> Bool {
        let calendar = Calendar.current
        return activeDates.contains {
            calendar.component(.day, from: $0) == dayOfMonth
                && calendar.component(.month, from: $0) == calendar.component(.month, from: Date())
        }
    }

    // MARK: - Vida: to-dos y metas

    func addTodo(_ todo: TodoItem) { todos.append(todo) }
    func toggleTodo(_ todo: TodoItem) {
        guard let i = todos.firstIndex(where: { $0.id == todo.id }) else { return }
        todos[i].isDone.toggle()
        if todos[i].isDone { markActiveToday() }
    }
    func deleteTodo(_ todo: TodoItem) { todos.removeAll { $0.id == todo.id } }
    func postpone(_ todo: TodoItem) {
        guard let i = todos.firstIndex(where: { $0.id == todo.id }) else { return }
        todos.append(todos.remove(at: i)) // posponer sin penalización
    }

    var primaryGoal: Goal? { goals.first { $0.isPrimary } ?? goals.first }

    func addGoal(_ goal: Goal) {
        var goal = goal
        if goals.isEmpty { goal.isPrimary = true }
        goals.append(goal)
    }
    func updateGoal(_ goal: Goal) {
        guard let i = goals.firstIndex(where: { $0.id == goal.id }) else { return }
        goals[i] = goal
    }
    func deleteGoal(_ goal: Goal) { goals.removeAll { $0.id == goal.id } }
    func toggleMilestone(_ milestone: Milestone, in goal: Goal) {
        guard let g = goals.firstIndex(where: { $0.id == goal.id }),
              let m = goals[g].milestones.firstIndex(where: { $0.id == milestone.id }) else { return }
        goals[g].milestones[m].isDone.toggle()
        if goals[g].milestones[m].isDone { markActiveToday() }
    }
    func setPrimaryGoal(_ goal: Goal) {
        for i in goals.indices { goals[i].isPrimary = goals[i].id == goal.id }
    }

    func addTramite(_ guide: TramiteGuide) { tramites.append(guide) }
    func toggleStep(_ stepIndex: Int, in guide: TramiteGuide) {
        guard let i = tramites.firstIndex(where: { $0.id == guide.id }) else { return }
        if tramites[i].completedSteps.contains(stepIndex) {
            tramites[i].completedSteps.remove(stepIndex)
        } else {
            tramites[i].completedSteps.insert(stepIndex)
        }
    }

    func addResaleItem(_ item: ResaleItem) { resaleItems.append(item) }
    func deleteResaleItem(_ item: ResaleItem) { resaleItems.removeAll { $0.id == item.id } }

    func addReminder(_ reminder: Reminder) { reminders.append(reminder) }
    func deleteReminder(_ reminder: Reminder) { reminders.removeAll { $0.id == reminder.id } }

    // MARK: - Dinero (todo derivado del presupuesto actual, nunca cacheado)

    var totalSpentMXN: Double { expenses.reduce(0) { $0 + $1.amountMXN } }
    var monthlyBudgetMXN: Double { budget.monthlyAmount }
    var remainingBudgetMXN: Double { max(budget.monthlyAmount - totalSpentMXN, 0) }
    var budgetUsedRatio: Double {
        guard budget.monthlyAmount > 0 else { return 0 }
        return min(totalSpentMXN / budget.monthlyAmount, 1)
    }
    var antExpensesTotalMXN: Double {
        expenses.filter { $0.category == .fun_ }.reduce(0) { $0 + $1.amountMXN }
    }

    func setMonthlyBudget(_ amount: Double) { budget.monthlyAmount = max(0, amount) }
    func setWeeklyBudget(_ amount: Double?) { budget.weeklyAmount = amount }
    func resetBudget() { budget = Budget() }

    func addExpense(_ expense: Expense) { expenses.append(expense) }
    func updateExpense(_ expense: Expense) {
        guard let i = expenses.firstIndex(where: { $0.id == expense.id }) else { return }
        expenses[i] = expense
    }
    func deleteExpense(_ expense: Expense) { expenses.removeAll { $0.id == expense.id } }
    func deleteAllExpenses() { expenses.removeAll() }

    func exportExpensesCSV() -> String {
        var lines = ["title,amountMXN,category,date"]
        let formatter = ISO8601DateFormatter()
        for expense in expenses {
            let fields = [expense.title, "\(expense.amountMXN)", expense.category.rawValue, formatter.string(from: expense.date)]
            lines.append(fields.map(csvField).joined(separator: ","))
        }
        return lines.joined(separator: "\n")
    }

    /// Escapa comas/comillas y neutraliza fórmulas (=, +, -, @) al exportar.
    private func csvField(_ raw: String) -> String {
        var value = raw
        if let first = value.first, "=+-@".contains(first) { value = "'" + value }
        return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
    }

    func unlockExpenses(withPIN pin: String) -> Bool {
        guard pin == expensesPIN, !expensesPIN.isEmpty else { return false }
        expensesUnlockedThisSession = true
        return true
    }

    // MARK: - Enfoque

    var focusSecondsRemaining: Int {
        guard let end = focusSessionEndDate else { return focusBlockMinutes * 60 }
        return max(0, Int(end.timeIntervalSinceNow.rounded()))
    }

    func startFocusSession(minutes: Int) {
        focusBlockMinutes = minutes
        focusSessionEndDate = Date().addingTimeInterval(TimeInterval(minutes * 60))
        isFocusSessionActive = true
    }

    func finishFocusSession(subject: String? = nil) {
        if isFocusSessionActive, let subject {
            logStudySession(subject: subject, minutes: focusBlockMinutes)
        } else if isFocusSessionActive {
            markActiveToday()
        }
        unlockAllNow()
    }

    func unlockAllNow() {
        isFocusSessionActive = false
        focusSessionEndDate = nil
    }

    func addFocusProfile(_ profile: FocusProfile) { focusProfiles.append(profile) }
    func updateFocusProfile(_ profile: FocusProfile) {
        guard let i = focusProfiles.firstIndex(where: { $0.id == profile.id }) else { return }
        focusProfiles[i] = profile
    }
    func deleteFocusProfile(_ profile: FocusProfile) { focusProfiles.removeAll { $0.id == profile.id } }

    // MARK: - Suscripción

    var subscription: SubscriptionState {
        guard let until = proUntil else { return .free }
        if until <= Date() { return .expired }
        if let plan = proPlan {
            return proWillRenew ? .active(until: until, plan: plan, willRenew: true)
                                : .cancelled(activeUntil: until)
        }
        return .active(until: until, plan: .referral, willRenew: false)
    }

    var isPro: Bool { subscription.isPro }

    var proDaysRemaining: Int {
        guard let until = proUntil, until > Date() else { return 0 }
        return Calendar.current.dateComponents([.day], from: Date(), to: until).day ?? 0
    }

    private func extendPro(days: Int, plan: SubscriptionPlan, willRenew: Bool) {
        let base = max(proUntil ?? Date(), Date())
        proUntil = Calendar.current.date(byAdding: .day, value: days, to: base)
        proPlan = plan
        proWillRenew = willRenew
    }

    var referralTiers: [ReferralTier] { DemoData.referralTiers }

    var nextReferralTier: ReferralTier? { referralTiers.first { $0.count > referralCount } }

    /// Paquetes cerrados no acumulables: solo se otorga al llegar exacto a cada umbral.
    func registerReferral() {
        referralCount += 1
        guard let tier = referralTiers.first(where: { $0.count == referralCount }),
              !redeemedTierCounts.contains(tier.count) else { return }
        redeemedTierCounts.insert(tier.count)
        extendPro(days: tier.rewardDays, plan: proPlan ?? .referral, willRenew: proWillRenew)
    }

    /// Compras: hoy extienden localmente. El cobro real necesita StoreKit + App Store Connect
    /// (ver StoreKitService y el README).
    func activateMonthly() { extendPro(days: 30, plan: .monthly, willRenew: true) }
    func activateAnnual() { extendPro(days: 365, plan: .annual, willRenew: true) }
    func cancelRenewal() { proWillRenew = false }

    // MARK: - Datos de prueba (solo desarrollo, nunca en la experiencia real)

    #if DEBUG
    func loadSampleData() {
        education = UserEducation(level: .university, semester: "5°", career: "Ing. en Sistemas",
                                  schoolStart: TimeOfDay(7), schoolEnd: TimeOfDay(15))
        classes = [
            SchoolClass(subject: "Cálculo Diferencial", days: [.monday, .wednesday, .friday],
                        start: TimeOfDay(7), end: TimeOfDay(8, 30), professor: "Ing. Ramírez", room: "204"),
            SchoolClass(subject: "Programación", days: [.tuesday, .thursday],
                        start: TimeOfDay(11), end: TimeOfDay(13), room: "118")
        ]
        meals = [Meal(name: "Desayuno", time: TimeOfDay(8)),
                 Meal(name: "Comida", time: TimeOfDay(14)),
                 Meal(name: "Cena", time: TimeOfDay(20, 30))]
        budget = Budget(monthlyAmount: 4500)
        markActiveToday()
    }
    #endif
}

enum WeekIntensity {
    case light, normal, high
}
