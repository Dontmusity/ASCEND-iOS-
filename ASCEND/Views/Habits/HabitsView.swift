import SwiftUI

struct HabitsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showEditor = false

    private var groupedByArea: [(HabitArea, [Habit])] {
        HabitArea.allCases.map { area in
            (area, appState.habits.filter { $0.area == area })
        }.filter { !$0.1.isEmpty }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    analyticsCard

                    if appState.habits.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Aún no sigues ningún hábito")
                                .font(.subheadline.bold())
                                .foregroundColor(.ascendTextPrimary)
                            Text("Agrega los que tú quieras seguir. ASCEND no te impone ninguno.")
                                .font(.footnote)
                                .foregroundColor(.ascendTextSecondary)
                            Button("Crear hábito") { showEditor = true }
                                .buttonStyle(.borderedProminent)
                                .tint(.ascendGold)
                        }
                        .padding(.horizontal, 20)
                    }

                    ForEach(groupedByArea, id: \.0) { area, habits in
                        VStack(alignment: .leading, spacing: 10) {
                            Label(area.rawValue, systemImage: area.icon)
                                .font(.headline)
                                .foregroundColor(.ascendTextPrimary)
                            ForEach(habits) { habit in
                                habitRow(habit)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.vertical, 16)
                .readableWidth()
            }
            .background(Color.ascendBackground.ignoresSafeArea())
            .navigationTitle("Hábitos")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { StreakBadge() }
                ToolbarItem(placement: .topBarLeading) {
                    Button { showEditor = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Nuevo hábito")
                }
            }
            .sheet(isPresented: $showEditor) {
                HabitEditorSheet { appState.addHabit($0) }
            }
        }
    }

    private var analyticsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 20) {
                statColumn(value: "\(appState.currentStreak)", label: "Racha actual")
                statColumn(value: "\(appState.bestStreak)", label: "Mejor racha")
                statColumn(value: "\(appState.accumulatedThisMonth)", label: "Días este mes")
            }
            HeatmapView()
            Text("Un mal día no borra tu camino.")
                .font(.footnote)
                .foregroundColor(.ascendTextSecondary)
        }
        .padding(16)
        .background(Color.ascendSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 20)
    }

    private func statColumn(value: String, label: String) -> some View {
        VStack {
            Text(value).font(.title3.bold()).foregroundColor(.ascendTextPrimary)
            Text(label).font(.caption2).foregroundColor(.ascendTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    private func habitRow(_ habit: Habit) -> some View {
        let done = appState.isHabitDoneToday(habit)
        return Button {
            withAnimation { appState.toggleHabit(habit) }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(habit.name).foregroundColor(.ascendTextPrimary)
                    Text("\(habit.completedDays.count) días este mes")
                        .font(.caption)
                        .foregroundColor(.ascendTextSecondary)
                }
                Spacer()
                Image(systemName: done ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(done ? .ascendGold : .ascendGray)
                    .font(.title3)
            }
            .padding(14)
            .frame(minHeight: 44)
            .background(Color.ascendCard)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.ascendGray.opacity(0.15)))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(habit.name), \(habit.completedDays.count) días este mes")
        .accessibilityAddTraits(done ? .isSelected : [])
        .contextMenu {
            Button("Eliminar", role: .destructive) { appState.deleteHabit(habit) }
        }
    }
}

private struct HeatmapView: View {
    @EnvironmentObject private var appState: AppState
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 10)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 4) {
            ForEach(1...30, id: \.self) { day in
                RoundedRectangle(cornerRadius: 3)
                    .fill(appState.isActiveDay(day) ? Color.ascendGold : Color.ascendGray.opacity(0.15))
                    .frame(height: 14)
            }
        }
        .accessibilityLabel("Mapa del mes: \(appState.accumulatedThisMonth) días con progreso")
        .accessibilityElement(children: .ignore)
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
