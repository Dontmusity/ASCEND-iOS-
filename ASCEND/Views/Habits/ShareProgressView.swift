import SwiftUI

/// Tarjeta para compartir como imagen. Solo cifras y el calendario del periodo:
/// nunca horario, gastos ni notas (y se dice arriba, antes de compartir).
struct ShareProgressView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var scope: ShareScope = .month

    enum ShareScope: String, CaseIterable, Hashable {
        case month = "Este mes", week = "Semana", goal = "Una meta"
    }

    var body: some View {
        let card = ShareCard(data: cardData)
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                AscendKicker(text: "Compartir")
                Spacer()
                Button("Cerrar") { dismiss() }
                    .buttonStyle(AscendPillButtonStyle())
            }
            .padding(.top, 16)

            Text("Tu \(cardData.periodName),\nen una tarjeta")
                .font(.ascendRounded(24, relativeTo: .title))
                .foregroundColor(.ascendTextPrimary)
                .padding(.top, 8)
            Text("Solo se comparte lo que ves aquí. Nada de horarios, gastos ni notas.")
                .font(.footnote)
                .foregroundColor(.ascendTextSecondary)
                .padding(.top, 7)

            card.padding(.top, 18)

            HStack(spacing: 8) {
                ForEach(ShareScope.allCases, id: \.self) { option in
                    AscendChip(icon: nil, title: option.rawValue, isActive: scope == option) {
                        scope = option
                    }
                    .disabled(option == .goal && appState.primaryGoal == nil)
                }
            }
            .padding(.top, 12)

            Spacer()

            if let image = render(card) {
                ShareLink(item: image, preview: SharePreview("ASCEND", image: image)) {
                    Label("Compartir", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(AscendPrimaryButtonStyle())
                .padding(.bottom, 20)
            }
        }
        .padding(.horizontal, 20)
        .background(Color.ascendBackground.ignoresSafeArea())
    }

    /// La imagen se pinta con el modo de color actual para que se vea igual que en pantalla.
    @MainActor
    private func render(_ card: ShareCard) -> Image? {
        let renderer = ImageRenderer(content: card.frame(width: 360).environment(\.colorScheme, colorScheme))
        renderer.scale = 3
        return renderer.uiImage.map { Image(uiImage: $0) }
    }

    // MARK: Datos por alcance (todo derivado, sin tocar AppState)

    private var cardData: ShareCard.Stats {
        let calendar = Calendar.current
        switch scope {
        case .month:
            let month = MonthProgress(state: appState)
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: Date())) ?? Date()
            return .init(periodName: month.monthName,
                         kicker: "ASCEND · \(month.monthName)",
                         value: month.activeDays, total: month.daysInMonth,
                         caption: "días con progreso",
                         levels: month.levels,
                         focusedMinutes: focusedMinutes(since: startOfMonth),
                         habits: appState.habits.count,
                         goalSteps: goalSteps)
        case .week:
            let today = calendar.startOfDay(for: Date())
            let days = (0..<7).reversed().compactMap { calendar.date(byAdding: .day, value: -$0, to: today) }
            let levels = days.map { day -> Int in
                guard appState.activeDates.contains(day) else { return 0 }
                return (appState.completionPercent(for: day) ?? 100) >= 50 ? 2 : 1
            }
            return .init(periodName: "semana",
                         kicker: "ASCEND · Esta semana",
                         value: levels.filter { $0 > 0 }.count, total: 7,
                         caption: "días con progreso",
                         levels: levels,
                         focusedMinutes: focusedMinutes(since: days.first ?? today),
                         habits: appState.habits.count,
                         goalSteps: goalSteps)
        case .goal:
            let goal = appState.primaryGoal
            let done = goal?.milestones.filter(\.isDone).count ?? 0
            let total = goal?.milestones.count ?? 0
            return .init(periodName: "meta",
                         kicker: "ASCEND · Meta",
                         value: done, total: total,
                         caption: goal?.title ?? "",
                         levels: (goal?.milestones ?? []).map { $0.isDone ? 2 : 0 },
                         focusedMinutes: nil, habits: nil, goalSteps: nil)
        }
    }

    private var goalSteps: String? {
        guard let goal = appState.primaryGoal, !goal.milestones.isEmpty else { return nil }
        return "\(goal.milestones.filter(\.isDone).count)/\(goal.milestones.count)"
    }

    private func focusedMinutes(since start: Date) -> Int {
        appState.studySessions.filter { $0.date >= start }.reduce(0) { $0 + $1.minutes }
    }
}

/// La tarjeta en sí. Sin EnvironmentObject para que ImageRenderer la pinte sola.
struct ShareCard: View {
    struct Stats {
        var periodName: String
        var kicker: String
        var value: Int
        var total: Int
        var caption: String
        var levels: [Int]
        var focusedMinutes: Int?
        var habits: Int?
        var goalSteps: String?
    }

    let data: Stats

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                AscendMark(strokeColor: .ascendOnSurfaceTertiary, innerColor: .ascendGold)
                    .frame(width: 19, height: 19)
                AscendKicker(text: data.kicker, color: .ascendOnSurfaceTertiary)
            }
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text("\(data.value)")
                    .font(.ascendRounded(56, relativeTo: .largeTitle))
                    .foregroundColor(.ascendOnSurface)
                Text("/\(data.total)")
                    .font(.ascendRounded(22, .medium, relativeTo: .title2))
                    .foregroundColor(.ascendOnSurfaceTertiary)
            }
            .padding(.top, 18)
            Text(data.caption)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.ascendOnSurfaceSecondary)
                .padding(.top, 5)
            if !data.levels.isEmpty {
                AscendHeatmap(levels: data.levels, cellHeight: 14)
                    .padding(.top, 18)
            }
            if data.focusedMinutes != nil || data.habits != nil || data.goalSteps != nil {
                HStack(spacing: 14) {
                    if let minutes = data.focusedMinutes {
                        stat(minutes >= 60 ? "\(minutes / 60)h" : "\(minutes)m", "Enfoque")
                    }
                    if let habits = data.habits {
                        divider
                        stat("\(habits)", "Hábitos")
                    }
                    if let steps = data.goalSteps {
                        divider
                        stat(steps, "Pasos de meta")
                    }
                }
                .padding(.top, 18)
            }
            Text("Plan. Focus. Conquer.")
                .font(.caption)
                .foregroundColor(.ascendOnSurfaceSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 14)
                .overlay(alignment: .top) {
                    Rectangle().fill(Color.ascendOnSurface.opacity(0.08)).frame(height: 1)
                }
                .padding(.top, 18)
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .ascendSurfaceCard(cornerRadius: 24)
        .accessibilityElement(children: .combine)
    }

    private var divider: some View {
        Rectangle().fill(Color.ascendOnSurface.opacity(0.08)).frame(width: 1, height: 26)
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value).font(.ascendNumber(18)).foregroundColor(.ascendOnSurface)
            AscendKicker(text: label, color: .ascendOnSurfaceTertiary)
        }
    }
}
