import WidgetKit
import SwiftUI
import AppIntents

/// 6a pequeño: los hábitos de hoy, marcables desde el widget sin abrir la app.
struct HabitsWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "ascend.habits", provider: AscendProvider()) { entry in
            HabitsWidgetView(entry: entry)
                .containerBackground(Color.ascendWidgetBackground, for: .widget)
                .widgetURL(AscendLink.habits)
        }
        .configurationDisplayName("Hábitos de hoy")
        .description("Marca tus hábitos sin abrir la app.")
        .supportedFamilies([.systemSmall])
    }
}

private struct HabitsWidgetView: View {
    let entry: AscendEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            WidgetKicker(text: "Hoy")
                .padding(.bottom, 3)
            if entry.data.habits.isEmpty {
                Text("Agrega los hábitos que quieras seguir desde la app.")
                    .font(.caption)
                    .foregroundColor(.ascendTextSecondary)
            } else {
                ForEach(entry.data.habits.prefix(3)) { habit in
                    Button(intent: ToggleHabitIntent(habitID: habit.id.uuidString)) {
                        HStack(spacing: 9) {
                            ZStack {
                                if habit.isDone {
                                    Circle().fill(Color.ascendGold)
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(.white)
                                } else {
                                    Circle().strokeBorder(Color.ascendGray, lineWidth: 1.9)
                                }
                            }
                            .frame(width: 20, height: 20)
                            Text(habit.name)
                                .font(.caption.weight(.medium))
                                .foregroundColor(habit.isDone ? .ascendTextPrimary : .ascendTextPrimary.opacity(0.85))
                                .lineLimit(1)
                            Spacer(minLength: 0)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(habit.isDone ? "Hecho: \(habit.name)" : "Marcar como hecho: \(habit.name)")
                }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Marca o desmarca un hábito de hoy. Corre en el proceso del widget: lee lo guardado en el
/// App Group, lo cambia con la misma lógica de la app y lo guarda en el acto. La app lo relee
/// al volver a primer plano (ASCENDApp → scenePhase).
struct ToggleHabitIntent: AppIntent {
    static var title: LocalizedStringResource = "Marcar hábito"
    static var isDiscoverable = false

    @Parameter(title: "Hábito")
    var habitID: String

    init() {}

    init(habitID: String) {
        self.habitID = habitID
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        let state = AppState()
        if let habit = state.habits.first(where: { $0.id.uuidString == habitID }) {
            state.toggleHabit(habit)
            state.saveNow()
        }
        return .result()
    }
}
