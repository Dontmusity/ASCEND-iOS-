import WidgetKit
import SwiftUI

/// 6a mediano: lo de ahora con barra de progreso y lo que sigue, en el color de su área.
/// 6b circular de bloqueo: minutos restantes de lo de ahora.
struct NowWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "ascend.now", provider: AscendProvider()) { entry in
            NowWidgetView(entry: entry)
                .containerBackground(Color.ascendWidgetBackground, for: .widget)
                .widgetURL(AscendLink.today)
        }
        .configurationDisplayName("Ahora")
        .description("Lo que estás haciendo, cuánto falta y lo que sigue.")
        .supportedFamilies([.systemMedium, .accessoryCircular])
    }
}

private struct NowWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: AscendEntry

    var body: some View {
        switch family {
        case .accessoryCircular: circular
        default: medium
        }
    }

    // MARK: Mediano

    private var medium: some View {
        let data = entry.data
        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 7) {
                WidgetMark()
                WidgetKicker(text: data.current == nil ? "Siguiente" : "Ahora")
                Spacer()
                WidgetKicker(text: AscendDateText.shortKicker(entry.date))
            }

            if let current = data.current {
                HStack(alignment: .bottom, spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(current.title)
                            .font(.ascendRounded(19, relativeTo: .headline))
                            .foregroundColor(.ascendTextPrimary)
                            .lineLimit(1)
                        Text([current.subtitle ?? "", "termina \(current.end.label)"]
                                .filter { !$0.isEmpty }.joined(separator: " · "))
                            .font(.caption)
                            .foregroundColor(.ascendTextSecondary)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 4)
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(data.minutesRemaining)")
                            .font(.ascendNumber(26))
                            .monospacedDigit()
                            .foregroundColor(.ascendTextPrimary)
                        Text("min").font(.caption2.weight(.medium)).foregroundColor(.ascendTextSecondary)
                    }
                }
                .padding(.top, 11)
                AscendProgressBar(progress: data.currentProgress,
                                  track: Color.ascendTextPrimary.opacity(0.10), height: 4)
                    .padding(.top, 12)
            } else if let next = data.next {
                Text(next.title)
                    .font(.ascendRounded(19, relativeTo: .headline))
                    .foregroundColor(.ascendTextPrimary)
                    .lineLimit(1)
                    .padding(.top, 11)
                Text("Empieza a las \(next.start.label)")
                    .font(.caption)
                    .foregroundColor(.ascendTextSecondary)
                    .padding(.top, 2)
            } else {
                Text("Tu día está vacío")
                    .font(.ascendRounded(19, relativeTo: .headline))
                    .foregroundColor(.ascendTextPrimary)
                    .padding(.top, 11)
                Text("Agrega tus clases, entrenamientos o actividades y aparecerán aquí.")
                    .font(.caption)
                    .foregroundColor(.ascendTextSecondary)
                    .lineLimit(2)
                    .padding(.top, 2)
            }

            Spacer(minLength: 0)

            if data.current != nil, let next = data.next {
                HStack(spacing: 9) {
                    RoundedRectangle(cornerRadius: 1.5).fill(next.color).frame(width: 3, height: 22)
                    Text("Sigue · \(next.title)")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.ascendTextPrimary.opacity(0.85))
                        .lineLimit(1)
                    Spacer()
                    Text(next.start.label)
                        .font(.ascendRounded(12, .medium, relativeTo: .caption))
                        .foregroundColor(.ascendTextSecondary)
                }
            }
        }
    }

    // MARK: Circular (pantalla de bloqueo)

    private var circular: some View {
        ZStack {
            AccessoryWidgetBackground()
            if entry.data.current != nil {
                VStack(spacing: 0) {
                    Text("\(entry.data.minutesRemaining)")
                        .font(.ascendNumber(15))
                        .monospacedDigit()
                    Text("MIN").font(.system(size: 8, weight: .medium))
                }
            } else if let next = entry.data.next {
                Text(next.start.label).font(.ascendNumber(12)).minimumScaleFactor(0.6)
            } else {
                Image(systemName: "checkmark")
            }
        }
        .accessibilityLabel(entry.data.current.map { "\($0.title), \(entry.data.minutesRemaining) minutos restantes" }
                            ?? "Nada en curso")
    }
}
