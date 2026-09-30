import WidgetKit
import SwiftUI

/// 6a pequeño: el mes con su calendario. 6b circular de bloqueo: anillo del mes.
struct MonthWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "ascend.month", provider: AscendProvider()) { entry in
            MonthWidgetView(entry: entry)
                .containerBackground(Color.ascendWidgetBackground, for: .widget)
                .widgetURL(AscendLink.habits)
        }
        .configurationDisplayName("Tu mes")
        .description("Días con progreso este mes. Un mal día no borra tu camino.")
        .supportedFamilies([.systemSmall, .accessoryCircular])
    }
}

private struct MonthWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: AscendEntry

    var body: some View {
        let data = entry.data
        switch family {
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                AscendRing(progress: Double(data.activeDays) / Double(max(data.daysInMonth, 1)),
                           track: .primary.opacity(0.18), lineWidth: 4) {
                    Text("\(data.activeDays)").font(.ascendNumber(14))
                }
            }
            .accessibilityLabel("\(data.activeDays) de \(data.daysInMonth) días con progreso")
        default:
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 6) {
                    WidgetMark(size: 13)
                    WidgetKicker(text: data.monthName)
                }
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text("\(data.activeDays)")
                        .font(.ascendNumber(34))
                        .foregroundColor(.ascendTextPrimary)
                    Text("/\(data.daysInMonth)")
                        .font(.ascendRounded(15, .medium, relativeTo: .subheadline))
                        .foregroundColor(.ascendOnSurfaceTertiary)
                }
                .padding(.top, 12)
                Text("días con progreso")
                    .font(.caption2)
                    .foregroundColor(.ascendTextSecondary)
                    .padding(.top, 3)
                Spacer(minLength: 8)
                AscendHeatmap(levels: data.levels, cellHeight: 8, spacing: 3,
                              emptyColor: Color.ascendTextPrimary.opacity(0.10))
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(data.activeDays) de \(data.daysInMonth) días con progreso en \(data.monthName)")
        }
    }
}
