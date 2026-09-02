import SwiftUI

/// Calendario compacto del día. Se genera solo con lo que el usuario configuró
/// y coloca los eventos solapados en columnas para que ninguno tape a otro.
struct DayTimelineView: View {
    let entries: [ScheduleEntry]
    var onDelete: ((ScheduleEntry) -> Void)? = nil

    /// Más compacto que antes (antes 60pt/hora): caben ~2 horas más sin perder legibilidad.
    private let hourHeight: CGFloat = 44
    private let gutter: CGFloat = 34

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
        GeometryReader { geo in
            ScrollView {
                ZStack(alignment: .topLeading) {
                    grid
                    ForEach(layout, id: \.entry.id) { item in
                        card(item.entry, column: item.column, of: item.columns,
                             containerWidth: max(geo.size.width - 32, 120))
                    }
                }
                .frame(height: totalHeight, alignment: .topLeading)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .overlay(alignment: .center) {
                if entries.isEmpty { emptyState }
            }
        }
        .accessibilityElement(children: .contain)
    }

    private var grid: some View {
        VStack(spacing: 0) {
            ForEach(startHour...endHour, id: \.self) { hour in
                HStack(alignment: .top, spacing: 6) {
                    Text(String(format: "%02d:00", hour))
                        .font(.caption2)
                        .foregroundColor(.ascendTextSecondary)
                        .minimumScaleFactor(0.7)
                        .frame(width: 28, alignment: .trailing)
                    VStack { Divider() }
                }
                .frame(height: hourHeight, alignment: .top)
            }
        }
        .accessibilityHidden(true)
    }

    private func card(_ entry: ScheduleEntry, column: Int, of columns: Int, containerWidth: CGFloat) -> some View {
        let available = containerWidth - gutter
        let width = columns > 1 ? (available / CGFloat(columns)) - 3 : available
        let offsetX = gutter + (CGFloat(column) * (width + 3))
        let top = CGFloat(entry.start.totalMinutes - startHour * 60) / 60 * hourHeight
        let height = max(CGFloat(entry.durationMinutes) / 60 * hourHeight - 2, 26)

        return VStack(alignment: .leading, spacing: 1) {
            Text(entry.title)
                .font(.caption.bold())
                .foregroundColor(.ascendTextPrimary)
                .lineLimit(height > 42 ? 2 : 1)
            if let subtitle = entry.subtitle, !subtitle.isEmpty, height > 42 {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.ascendTextSecondary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .frame(width: width, height: height, alignment: .topLeading)
        .background(entry.color.opacity(0.18))
        .overlay(
            RoundedRectangle(cornerRadius: 7)
                .stroke(entry.color.opacity(entry.isActive() ? 0.9 : 0.45), lineWidth: entry.isActive() ? 2 : 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 7))
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

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "calendar")
                .font(.title2)
                .foregroundColor(.ascendGray)
            Text("Tu día está vacío")
                .font(.subheadline.bold())
                .foregroundColor(.ascendTextPrimary)
            Text("Agrega tus clases, entrenamientos o actividades y aparecerán aquí.")
                .font(.footnote)
                .foregroundColor(.ascendTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}
