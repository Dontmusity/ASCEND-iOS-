import WidgetKit
import SwiftUI
import ActivityKit

/// 6b circular de bloqueo: atajo directo a Enfoque.
struct FocusShortcutWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "ascend.focus-shortcut", provider: AscendProvider()) { _ in
            ZStack {
                AccessoryWidgetBackground()
                AscendMark(strokeColor: .primary.opacity(0.6), innerColor: .ascendGold)
                    .padding(13)
            }
            .containerBackground(.clear, for: .widget)
            .widgetURL(AscendLink.focus)
            .accessibilityLabel("Abrir Enfoque")
        }
        .configurationDisplayName("Enfoque")
        .description("Empieza una sesión de enfoque en un toque.")
        .supportedFamilies([.accessoryCircular])
    }
}

/// 6b Live Activity en bloqueo y 6c isla dinámica de la sesión de enfoque.
/// "Desbloquear" siempre está a la mano: abre la app y cierra la sesión sin preguntar.
struct FocusLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusActivityAttributes.self) { context in
            lockScreen(context)
                .activityBackgroundTint(Color.ascendCard.opacity(0.92))
                .activitySystemActionForegroundColor(.ascendGold)
        } dynamicIsland: { context in
            let range = context.state.startDate...context.state.endDate
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(Color.ascendCream)
                        .frame(width: 30, height: 30)
                        .overlay(AscendMark(strokeColor: .ascendGray, innerColor: .ascendGold).padding(6))
                }
                DynamicIslandExpandedRegion(.trailing) {
                    ring(range).frame(width: 40, height: 40)
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(kicker(context.attributes).uppercased())
                            .font(.system(size: 9.5, weight: .semibold))
                            .tracking(1.6)
                            .foregroundColor(.white.opacity(0.5))
                            .lineLimit(1)
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(timerInterval: range, countsDown: true)
                                .font(.ascendRounded(34, relativeTo: .title))
                                .monospacedDigit()
                                .foregroundColor(.white)
                            Text("de \(context.attributes.totalMinutes) min")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    // TODO(diseño): botón "Pausar". AppState todavía no tiene pausa de sesión,
                    // solo empezar y desbloquear; se agrega cuando exista esa lógica.
                    Link(destination: AscendLink.unlockFocus) {
                        Text("Desbloquear")
                            .font(.footnote.weight(.semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, minHeight: 40)
                            .background(Capsule().fill(Color.white.opacity(0.14)))
                    }
                    .padding(.top, 6)
                }
            } compactLeading: {
                ring(range).frame(width: 22, height: 22)
            } compactTrailing: {
                Text(timerInterval: range, countsDown: true)
                    .font(.ascendRounded(15, relativeTo: .subheadline))
                    .monospacedDigit()
                    .foregroundColor(.ascendGold)
                    .frame(maxWidth: 52)
            } minimal: {
                ring(range).frame(width: 20, height: 20)
            }
            .widgetURL(AscendLink.focus)
            .keylineTint(.ascendGold)
        }
    }

    private func kicker(_ attributes: FocusActivityAttributes) -> String {
        attributes.subject.map { "Enfoque · \($0)" } ?? "Enfoque"
    }

    /// Anillo que avanza solo con el reloj del sistema, sin actualizaciones de la app.
    private func ring(_ range: ClosedRange<Date>) -> some View {
        ProgressView(timerInterval: range, countsDown: false) {
            EmptyView()
        } currentValueLabel: {
            EmptyView()
        }
        .progressViewStyle(.circular)
        .tint(.ascendGold)
    }

    private func lockScreen(_ context: ActivityViewContext<FocusActivityAttributes>) -> some View {
        let range = context.state.startDate...context.state.endDate
        return HStack(spacing: 12) {
            ring(range).frame(width: 44, height: 44)
            VStack(alignment: .leading, spacing: 6) {
                Text("SESIÓN DE ENFOQUE")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1.6)
                    .foregroundColor(.ascendTextSecondary)
                HStack(spacing: 4) {
                    Text(timerInterval: range, countsDown: true)
                        .monospacedDigit()
                    if let subject = context.attributes.subject {
                        Text("· \(subject)").lineLimit(1)
                    }
                }
                .font(.ascendRounded(16, relativeTo: .headline))
                .foregroundColor(.ascendTextPrimary)
            }
            Spacer(minLength: 8)
            Link(destination: AscendLink.unlockFocus) {
                Text("Desbloquear")
                    .font(.footnote.weight(.medium))
                    .foregroundColor(.ascendTextPrimary)
                    .padding(.horizontal, 13)
                    .padding(.vertical, 7)
                    .overlay(Capsule().stroke(Color.ascendLine.opacity(0.4), lineWidth: 1))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}
