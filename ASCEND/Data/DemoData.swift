import Foundation

enum DemoData {
    static let profile = UserProfile(
        name: "Sofía",
        university: "Tec de Monterrey",
        major: "Ingeniería en Sistemas",
        livingSituation: "Vive sola, fuera de casa por primera vez",
        mainGoal: "Mantener el ritmo en la escuela sin descuidar mi bienestar",
        academicLoad: .moderate
    )

    static let events: [CalendarEvent] = [
        CalendarEvent(title: "Cálculo Diferencial", subtitle: "Salón 204", startHour: 7, durationHours: 1.5, lane: .school),
        CalendarEvent(title: "Bloque de estudio", subtitle: "Repaso de Cálculo", startHour: 9, durationHours: 1, lane: .school),
        CalendarEvent(title: "Desayuno", subtitle: "Avena con fruta", startHour: 8, durationHours: 0.5, lane: .food),
        CalendarEvent(title: "Programación Orientada a Objetos", subtitle: "Salón 118", startHour: 11, durationHours: 2, lane: .school),
        CalendarEvent(title: "Comida", subtitle: "Pollo con verduras", startHour: 14, durationHours: 0.75, lane: .food),
        CalendarEvent(title: "Gym: Piernas", subtitle: "Sentadilla, prensa, zancadas", startHour: 17, durationHours: 1.25, lane: .gym),
        CalendarEvent(title: "Fotografía", subtitle: "Editar fotos del finde", startHour: 19, durationHours: 1, lane: .hobbies),
        CalendarEvent(title: "Cena", subtitle: "Quesadillas", startHour: 20.5, durationHours: 0.5, lane: .food),
        CalendarEvent(title: "Tarea de POO", subtitle: "Entregar antes de las 11pm", startHour: 21, durationHours: 1.5, lane: .school),
    ]

    static let habits: [Habit] = [
        Habit(name: "Dormir antes de la 1am", area: .wellbeing, completedDays: Set(1...18)),
        Habit(name: "Repasar apuntes del día", area: .study, completedDays: Set([1,2,3,5,6,8,9,10,12,13,14,16,17])),
        Habit(name: "Registrar gastos del día", area: .money, completedDays: Set([1,2,4,5,7,8,9,11,12,15])),
        Habit(name: "Tender la cama", area: .home, completedDays: Set(1...20)),
        Habit(name: "Tomar agua suficiente", area: .health, completedDays: Set([2,3,4,6,7,9,10,11,13,14,16,17,18])),
    ]

    static let reminders: [Reminder] = [
        Reminder(title: "Pagar renta", icon: "house"),
        Reminder(title: "Pagar luz", icon: "bolt"),
        Reminder(title: "Comprar despensa", icon: "cart"),
    ]

    static let motivationalPhrases: [String] = [
        "Un mal día no borra tu camino.",
        "Vas a tu propio ritmo, y está bien.",
        "Pequeños pasos también cuentan como avance.",
        "Hoy puedes ir más despacio, mañana sigues aquí.",
        "Lo que ya lograste no desaparece.",
        "No se trata de hacer todo, se trata de seguir.",
        "Está bien pausar. Retomas cuando puedas.",
        "Tu esfuerzo de hoy también cuenta, aunque sea poco.",
        "Avanzar despacio sigue siendo avanzar.",
        "Mereces el mismo descanso que le das a los demás."
    ]

    static let todos: [TodoItem] = [
        TodoItem(title: "Inscribir siguiente semestre", area: .school, priority: .high),
        TodoItem(title: "Separar ropa para lavandería", area: .home, priority: .low),
        TodoItem(title: "Revisar presupuesto de la quincena", area: .money, priority: .medium),
        TodoItem(title: "Renovar credencial de transporte", area: .procedures, priority: .medium),
        TodoItem(title: "Llamar a mis papás", area: .personal, priority: .low),
    ]

    static let expenses: [Expense] = {
        let cal = Calendar.current
        func day(_ offset: Int) -> Date { cal.date(byAdding: .day, value: -offset, to: Date()) ?? Date() }
        return [
            Expense(title: "Tacos", amountMXN: 85, category: .food, date: day(0)),
            Expense(title: "Uber", amountMXN: 120, category: .transport, date: day(0)),
            Expense(title: "Fotocopias", amountMXN: 40, category: .school, date: day(1)),
            Expense(title: "Café", amountMXN: 65, category: .fun_, date: day(1)),
            Expense(title: "Despensa", amountMXN: 480, category: .home, date: day(2)),
            Expense(title: "Cine", amountMXN: 150, category: .fun_, date: day(3)),
            Expense(title: "Metro", amountMXN: 30, category: .transport, date: day(3)),
        ]
    }()

    static let monthlyBudgetMXN: Double = 4500

    static let tramites: [TramiteGuide] = [
        TramiteGuide(title: "Solicitar beca", steps: ["Reunir documentos", "Llenar formulario en línea", "Entregar en ventanilla", "Esperar resolución"], completedSteps: [0, 1]),
        TramiteGuide(title: "Credencial de estudiante", steps: ["Tomarse foto oficial", "Pagar cuota", "Recoger credencial"], completedSteps: [0]),
        TramiteGuide(title: "Abrir cuenta bancaria", steps: ["Elegir banco", "Agendar cita", "Llevar INE y comprobante", "Activar app"], completedSteps: []),
        TramiteGuide(title: "Credencial de transporte", steps: ["Llenar solicitud", "Pagar", "Recoger tarjeta"], completedSteps: []),
    ]

    static let resaleItems: [ResaleItem] = [
        ResaleItem(title: "Calculadora científica", priceMXN: 250, seller: "Diego M."),
        ResaleItem(title: "Libro de Cálculo Vectorial", priceMXN: 300, seller: "Ana R."),
        ResaleItem(title: "Bata de laboratorio", priceMXN: 180, seller: "Sofía"),
    ]

    static let blockableApps: [BlockableApp] = [
        BlockableApp(name: "Instagram", icon: "camera.circle"),
        BlockableApp(name: "TikTok", icon: "play.circle"),
        BlockableApp(name: "X", icon: "at.circle"),
        BlockableApp(name: "YouTube", icon: "tv.circle"),
    ]

    static let vitalApps: [String] = ["Teléfono", "Mensajes", "WhatsApp", "Cámara", "Mapas"]

    static let referralTiers: [ReferralTier] = [
        ReferralTier(count: 1, rewardDays: 7, label: "1 semana Pro"),
        ReferralTier(count: 10, rewardDays: 150, label: "5 meses Pro"),
        ReferralTier(count: 20, rewardDays: 365, label: "1 año Pro"),
    ]
}
