import WidgetKit
import SwiftUI

/// Lo que pintan los widgets, calculado con la misma lógica que la app (AppState + MonthProgress)
/// a partir de lo guardado en el App Group. Nada de datos inventados: si no hay rutina, se ve vacío.
struct AscendWidgetData {
    struct HabitItem: Identifiable {
        let id: UUID
        let name: String
        let isDone: Bool
    }

    var current: ScheduleEntry?
    var next: ScheduleEntry?
    var minutesRemaining: Int
    var currentProgress: Double
    var monthName: String
    var activeDays: Int
    var daysInMonth: Int
    var levels: [Int]
    var habits: [HabitItem]

    /// Calcula "ahora" y "sigue" para un momento dado, así la línea de tiempo puede ir hacia adelante.
    @MainActor
    static func make(from state: AppState, at date: Date) -> AscendWidgetData {
        let time = TimeOfDay.from(date)
        let todayEntries = state.entries(for: Weekday.from(date))
        let current = todayEntries.first { $0.isActive(at: time) }
        let next = todayEntries.first { $0.start > time }
        let total = current.map { max($0.end.totalMinutes - $0.start.totalMinutes, 1) } ?? 1
        let remaining = current.map { max(0, $0.end.totalMinutes - time.totalMinutes) } ?? 0
        let month = MonthProgress(state: state, now: date)

        return AscendWidgetData(
            current: current,
            next: next,
            minutesRemaining: remaining,
            currentProgress: current == nil ? 0 : Double(total - remaining) / Double(total),
            monthName: month.monthName,
            activeDays: month.activeDays,
            daysInMonth: month.daysInMonth,
            levels: month.levels,
            habits: state.habits.map { HabitItem(id: $0.id, name: $0.name, isDone: state.isHabitDoneToday($0)) })
    }

    static let empty = AscendWidgetData(
        current: nil, next: nil, minutesRemaining: 0, currentProgress: 0,
        monthName: "", activeDays: 0, daysInMonth: 30, levels: Array(repeating: 0, count: 30), habits: [])
}

struct AscendEntry: TimelineEntry {
    let date: Date
    let data: AscendWidgetData
}

/// Un solo proveedor para todos los widgets: una entrada cada 15 minutos durante 3 horas,
/// para que "ahora", los minutos y "sigue" avancen sin abrir la app.
struct AscendProvider: TimelineProvider {
    func placeholder(in context: Context) -> AscendEntry {
        AscendEntry(date: Date(), data: .empty)
    }

    func getSnapshot(in context: Context, completion: @escaping (AscendEntry) -> Void) {
        Task { @MainActor in
            completion(AscendEntry(date: Date(), data: .make(from: AppState(), at: Date())))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<AscendEntry>) -> Void) {
        Task { @MainActor in
            let state = AppState()
            let now = Date()
            let entries = (0..<12).map { step -> AscendEntry in
                let date = now.addingTimeInterval(TimeInterval(step * 15 * 60))
                return AscendEntry(date: date, data: .make(from: state, at: date))
            }
            completion(Timeline(entries: entries, policy: .atEnd))
        }
    }
}

// MARK: - Piezas compartidas por los widgets

struct WidgetKicker: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 9.5, weight: .semibold))
            .tracking(1.6)
            .foregroundColor(.ascendGray)
            .lineLimit(1)
    }
}

/// Marca de ASCEND en pequeño para encabezados de widget.
struct WidgetMark: View {
    var size: CGFloat = 14

    var body: some View {
        AscendMark(strokeColor: .ascendGray, innerColor: .ascendGold)
            .frame(width: size, height: size)
    }
}
