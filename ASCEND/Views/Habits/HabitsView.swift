import SwiftUI

struct HabitsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showEditor = false
    @State private var showShare = false

    private var groupedByArea: [(HabitArea, [Habit])] {
        HabitArea.allCases.map { area in
            (area, appState.habits.filter { $0.area == area })
        }.filter { !$0.1.isEmpty }
    }

    private var dayOfMonth: Int { Calendar.current.component(.day, from: Date()) }

    var body: some View {
        let month = MonthProgress(state: appState)
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                    monthCard(month)
                    if !groupedByArea.isEmpty { areaRings }
                    Text("Un mal día no borra tu camino.")
                        .font(.footnote)
                        .foregroundColor(.ascendTextSecondary)
                        .padding(.horizontal, 20)
                        .padding(.top, 10)

                    if appState.habits.isEmpty {
                        AscendEmptyState(title: "Aún no sigues ningún hábito",
                                         message: "Agrega los que tú quieras seguir. ASCEND no te impone ninguno.",
                                         actionTitle: "Crear hábito") { showEditor = true }
                            .padding(.top, 30)
                    }

                    ForEach(groupedByArea, id: \.0) { area, habits in
                        VStack(alignment: .leading, spacing: 10) {
                            AscendAreaKicker(text: area.rawValue, color: area.tint)
                                .padding(.bottom, 2)
                            ForEach(habits) { habit in
                                habitRow(habit, daysInMonth: month.daysInMonth)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 22)
                    }
                }
                .padding(.bottom, 90) // deja libre el FAB
                .readableWidth()
            }
            .background(Color.ascendBackground.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showEditor) {
                HabitEditorSheet { appState.addHabit($0) }
            }
            .sheet(isPresented: $showShare) {
                ShareProgressView()
            }
        }
    }

    // MARK: Encabezado

    private var header: some View {
        HStack(spacing: 4) {
            AscendKicker(text: "Hábitos")
            Spacer()
            StreakBadge()
            Button { showShare = true } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.ascendTextSecondary)
                    .frame(minWidth: 44, minHeight: 44)
            }
            .accessibilityLabel("Compartir mi mes")
            Button { showEditor = true } label: {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.ascendGold)
                    .frame(minWidth: 44, minHeight: 44)
            }
            .accessibilityLabel("Nuevo hábito")
        }
        .padding(.horizontal, 20)
        .padding(.top, 6)
    }

    // MARK: El mes en primer plano

    private func monthCard(_ month: MonthProgress) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(month.activeDays)")
                    .font(.ascendDisplay)
                    .monospacedDigit()
                    .foregroundColor(.ascendOnSurface)
                    .contentTransition(.numericText())
                Text("/\(month.daysInMonth)")
                    .font(.ascendRounded(22, .medium, relativeTo: .title2))
                    .foregroundColor(.ascendOnSurfaceTertiary)
            }
            Text("días con progreso en \(month.monthName)")
                .font(.subheadline.weight(.medium))
                .foregroundColor(.ascendOnSurfaceSecondary)
                .padding(.top, 5)

            AscendHeatmap(levels: month.levels)
                .padding(.top, 18)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Mapa del mes: \(month.activeDays) días con progreso")

            HStack(spacing: 8) {
                Text("Racha \(appState.currentStreak) · Mejor \(appState.bestStreak)")
                    .font(.caption)
                    .foregroundColor(.ascendOnSurfaceSecondary)
                    .contentTransition(.numericText())
                Spacer()
                AscendHeatmapLegend()
            }
            .padding(.top, 14)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .ascendSurfaceCard(cornerRadius: 24)
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    // MARK: Anillos por área

    /// Avance del mes del área: días marcados entre días transcurridos, promediado entre sus hábitos.
    private func monthProgress(of habits: [Habit]) -> Double {
        guard !habits.isEmpty, dayOfMonth > 0 else { return 0 }
        let done = habits.reduce(0) { $0 + min($1.daysDone(), dayOfMonth) }
        return Double(done) / Double(habits.count * dayOfMonth)
    }

    private var areaRings: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: min(groupedByArea.count, 3)),
                  spacing: 10) {
            ForEach(groupedByArea, id: \.0) { area, habits in
                let progress = monthProgress(of: habits)
                VStack(spacing: 6) {
                    AscendRing(progress: progress, color: area.tint, lineWidth: 6) {
                        Text("\(Int((progress * 100).rounded()))%")
                            .font(.ascendNumber(14))
                            .foregroundColor(.ascendTextPrimary)
                    }
                    .frame(width: 54, height: 54)
                    AscendKicker(text: area.rawValue)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 6)
                .frame(maxWidth: .infinity)
                .ascendCard()
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(area.rawValue): \(Int((progress * 100).rounded())) por ciento este mes")
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
    }

    // MARK: Filas

    private func habitRow(_ habit: Habit, daysInMonth: Int) -> some View {
        let done = appState.isHabitDoneToday(habit)
        let count = habit.daysDone()
        return Button {
            appState.toggleHabit(habit)
        } label: {
            HStack(spacing: 13) {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(habit.area.tint.opacity(0.18))
                    .frame(width: 38, height: 38)
                    .overlay(Image(systemName: habit.area.icon)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(habit.area.tint))
                VStack(alignment: .leading, spacing: 6) {
                    Text(habit.name)
                        .font(.body.weight(.semibold))
                        .foregroundColor(.ascendTextPrimary)
                        .multilineTextAlignment(.leading)
                    HStack(spacing: 8) {
                        AscendProgressBar(progress: Double(count) / Double(max(daysInMonth, 1)), height: 4)
                        Text("\(count)/\(daysInMonth)")
                            .font(.ascendRounded(11, .medium, relativeTo: .caption2))
                            .monospacedDigit()
                            .foregroundColor(.ascendTextSecondary)
                    }
                }
                AscendCheck(isOn: done)
            }
            .padding(12)
            .frame(minHeight: 44)
            .areaTint(habit.area.tint, fill: 0.10)
        }
        .buttonStyle(AscendPressStyle())
        .accessibilityLabel("\(habit.name), \(count) días este mes")
        .accessibilityAddTraits(done ? .isSelected : [])
        .contextMenu {
            Button("Eliminar", role: .destructive) { appState.deleteHabit(habit) }
        }
    }
}

struct HabitEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (Habit) -> Void

    @State private var name = ""
    @State private var area: HabitArea = .wellbeing

    var body: some View {
        NavigationStack {
            Form {
                TextField("Ej. Dormir antes de la 1am", text: $name)
                Picker("Área", selection: $area) {
                    ForEach(HabitArea.allCases) { Text($0.rawValue).tag($0) }
                }
            }
            .ascendListStyle()
            .navigationTitle("Nuevo hábito")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        onSave(Habit(name: name, area: area))
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
