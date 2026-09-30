import Foundation

/// Datos del mes derivados de AppState, solo lectura. Los usan Hábitos, la tarjeta para
/// compartir y los widgets, para que las tres muestren exactamente la misma cifra.
struct MonthProgress {
    let monthName: String   // "septiembre"
    let daysInMonth: Int
    let activeDays: Int
    /// Un nivel por día del mes: 0 sin progreso, 1 progreso parcial, 2 día completo.
    let levels: [Int]

    var ratio: Double { daysInMonth > 0 ? Double(activeDays) / Double(daysInMonth) : 0 }

    @MainActor
    init(state: AppState, now: Date = Date()) {
        let calendar = Calendar.current
        let today = calendar.component(.day, from: now)
        let comps = calendar.dateComponents([.year, .month], from: now)
        daysInMonth = calendar.range(of: .day, in: .month, for: now)?.count ?? 30
        activeDays = state.accumulatedThisMonth
        monthName = Self.monthFormatter.string(from: now)

        levels = (1...daysInMonth).map { day in
            guard day <= today, state.isActiveDay(day) else { return 0 }
            var dayComps = comps
            dayComps.day = day
            guard let date = calendar.date(from: dayComps) else { return 1 }
            // Día activo: completo si cumplió al menos la mitad de lo agendado (o no tenía nada agendado).
            let percent = state.completionPercent(for: date)
            return (percent ?? 100) >= 50 ? 2 : 1
        }
    }

    private static let monthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_MX")
        f.dateFormat = "LLLL"
        return f
    }()
}
