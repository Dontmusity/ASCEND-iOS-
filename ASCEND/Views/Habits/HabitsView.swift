import SwiftUI

struct HabitsView: View {
    @EnvironmentObject private var appState: AppState

    private var groupedByArea: [(HabitArea, [Habit])] {
        HabitArea.allCases.map { area in
            (area, appState.habits.filter { $0.area == area })
        }.filter { !$0.1.isEmpty }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    analyticsCard

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
            }
        }
    }

    private var analyticsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 24) {
                statColumn(value: "\(appState.currentStreak)", label: "Racha actual")
                statColumn(value: "\(appState.bestStreak)", label: "Mejor racha")
                statColumn(value: "\(appState.accumulatedThisMonth)/30", label: "Este mes")
            }

            HeatmapView()

            Text("Un mal día no borra tu camino.")
                .font(.footnote)
                .foregroundColor(.ascendTextSecondary)
        }
        .padding(16)
        .background(Color.ascendCream)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 20)
    }

    private func statColumn(value: String, label: String) -> some View {
        VStack {
            Text(value).font(.title3.bold()).foregroundColor(.ascendTextPrimary)
            Text(label).font(.caption2).foregroundColor(.ascendTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func habitRow(_ habit: Habit) -> some View {
        let done = appState.isHabitDoneToday(habit)
        return Button {
            withAnimation { appState.toggleHabit(habit) }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(habit.name).foregroundColor(.ascendTextPrimary)
                    Text(habit.monthProgressText)
                        .font(.caption)
                        .foregroundColor(.ascendTextSecondary)
                }
                Spacer()
                Image(systemName: done ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(done ? .ascendGold : .ascendGray)
                    .font(.title3)
            }
            .padding(14)
            .background(Color.ascendCard)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.ascendGray.opacity(0.15)))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
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
                    .frame(height: 16)
            }
        }
    }
}
