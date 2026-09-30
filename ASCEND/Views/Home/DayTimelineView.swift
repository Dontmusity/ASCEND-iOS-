import SwiftUI

/// Calendario compacto del día. Se genera solo con lo que el usuario configuró
/// y coloca los eventos solapados en columnas para que ninguno tape a otro.
struct DayTimelineView: View {
    let entries: [ScheduleEntry]
    var onDelete: ((ScheduleEntry) -> Void)? = nil

    /// Más compacto que antes (antes 60pt/hora): caben ~2 horas más sin perder legibilidad.
    private let hourHeight: CGFloat = 44
    private let gutter: CGFloat = 46

    /// La rejilla se ajusta al día real del usuario en vez de pintar siempre 6am–11pm.
    private var startHour: Int { max(0, (entries.map(\.start.hour).min() ?? 7) - 1) }
    private var endHour: Int { min(23, max((entries.map(\.end.hour).max() ?? 21) + 1, startHour + 6)) }
    private var totalHeight: CGFloat { CGFloat(endHour - startHour + 1) * hourHeight }

    /// Agrupa por solape para repartir el ancho entre los que chocan.
    private var layout: [(entry: ScheduleEntry, column: Int, columns: Int)] {
        var groups: [[ScheduleEntry]] = []
        for entry in entries.sorted(by: { $0.start < $1.start }) {
            if let index = groups.firstIndex(where: { group in
                group.contains { $0.start.totalMinutes < entry.end.totalMinutes && entry.start.totalMinutes < $0.end.totalMinutes }
            }) {
                groups[index].append(entry)
            } else {
                groups.append([entry])
            }
        }
        return groups.flatMap { group in
            group.enumerated().map { (entry: $0.element, column: $0.offset, columns: group.count) }
        }
    }

    var body: some View {
        if entries.isEmpty {
            ScrollView {
                AscendEmptyState(title: "Tu día está vacío",
                                 message: "Agrega tus clases, entrenamientos o actividades y aparecerán aquí.")
                    .padding(.top, 40)
            }
        } else {
            GeometryReader { geo in
                ScrollView {
                    ZStack(alignment: .topLeading) {
                        grid
                        ForEach(layout, id: \.entry.id) { item in
                            card(item.entry, column: item.column, of: item.columns,
                                 containerWidth: max(geo.size.width - 40, 120))
                        }
                        nowLine
                    }
                    .frame(height: totalHeight, alignment: .topLeading)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 90) // deja libre el FAB
                }
            }
            .accessibilityElement(children: .contain)
        }
    }

    private var grid: some View {
        VStack(spacing: 0) {
            ForEach(startHour...endHour, id: \.self) { hour in
                HStack(alignment: .top, spacing: 8) {
                    Text(String(format: "%02d:00", hour))
                        .font(.ascendRounded(11, .medium, relativeTo: .caption2))
                        .foregroundColor(.ascendTextSecondary)
                        .minimumScaleFactor(0.7)
                        .frame(width: 38, alignment: .leading)
                    Rectangle().fill(Color.ascendHairline).frame(height: 1).padding(.top, 6)
                }
                .frame(height: hourHeight, alignment: .top)
            }
        }
        .accessibilityHidden(true)
    }

    /// Línea de la hora actual en dorado con punto de 7 pt. Se mueve sola cada minuto.
    private var nowLine: some View {
        TimelineView(.periodic(from: .now, by: 60)) { _ in
            let now = TimeOfDay.now
            if now.hour >= startHour && now.hour <= endHour {
                HStack(spacing: 4) {
                    Text(now.label)
                        .font(.ascendRounded(11, .semibold, relativeTo: .caption2))
                        .monospacedDigit()
                        .foregroundColor(.ascendGold)
                        .frame(width: 38, alignment: .leading)
                    Circle().fill(Color.ascendGold).frame(width: 7, height: 7)
                    Rectangle().fill(Color.ascendGold.opacity(0.55)).frame(height: 1.5)
                }
                // +6 alinea con las líneas de la rejilla; −6.5 centra el HStack sobre ese punto.
                .offset(y: CGFloat(now.totalMinutes - startHour * 60) / 60 * hourHeight + 6 - 6.5)
                .accessibilityHidden(true)
            }
        }
    }

    private func card(_ entry: ScheduleEntry, column: Int, of columns: Int, containerWidth: CGFloat) -> some View {
        let available = containerWidth - gutter
        let width = columns > 1 ? (available / CGFloat(columns)) - 3 : available
        let offsetX = gutter + (CGFloat(column) * (width + 3))
        let top = CGFloat(entry.start.totalMinutes - startHour * 60) / 60 * hourHeight + 6
        let height = max(CGFloat(entry.durationMinutes) / 60 * hourHeight - 2, 26)

        return VStack(alignment: .leading, spacing: 1) {
            Text(entry.title)
                .font(.footnote.weight(.semibold))
                .foregroundColor(.ascendTextPrimary)
                .lineLimit(height > 42 ? 2 : 1)
            if let subtitle = entry.subtitle, !subtitle.isEmpty, height > 42 {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.ascendTextSecondary)
                    .lineLimit(1)
            }
        }
        .padding(.leading, 10)
        .padding(.trailing, 6)
        .padding(.vertical, 5)
        .frame(width: width, height: height, alignment: .topLeading)
        .areaTint(entry.color, fill: 0.14, cornerRadius: 12, bordered: false)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.ascendGold, lineWidth: entry.isActive() ? 1.5 : 0)
        )
        .offset(x: offsetX, y: top)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(entry.subtitle.map { "\(entry.title), \($0)" } ?? entry.title)
        .accessibilityValue(entry.timeLabel)
        .contextMenu {
            if let onDelete {
                Button("Eliminar", role: .destructive) { onDelete(entry) }
            }
        }
    }
}
