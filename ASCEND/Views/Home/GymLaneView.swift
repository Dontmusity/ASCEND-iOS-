import SwiftUI

/// Gym: entrenamiento del día con sets, pesos, historial y rest timer.
struct GymLaneView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showWorkoutEditor = false
    @State private var showSportEditor = false

    private var todayWorkout: Workout? { appState.workout(for: .today) }
    private var todaySports: [Sport] { appState.sports.filter { $0.days.contains(.today) } }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            LaneHeader(title: "Gimnasio", icon: "figure.strengthtraining.traditional", color: Color(hex: "A8785A")) {
                Menu {
                    Button("Nuevo día de entrenamiento") { showWorkoutEditor = true }
                    Button("Agregar deporte") { showSportEditor = true }
                } label: {
                    Image(systemName: "plus.circle").foregroundColor(.ascendGold)
                }
                .frame(minWidth: 44, minHeight: 44)
                .accessibilityLabel("Agregar en Gimnasio")
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if let workout = todayWorkout {
                        NavigationLink {
                            WorkoutTrackerView(workoutID: workout.id)
                        } label: {
                            todayCard(workout)
                        }
                        .buttonStyle(.plain)
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("HOY").font(.caption.bold()).foregroundColor(.ascendTextSecondary)
                            EmptyHint(text: appState.workouts.isEmpty
                                      ? "Aún no tienes entrenamientos. Crea uno con el +."
                                      : "Hoy es día de descanso.")
                        }
                    }

                    if !todaySports.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("DEPORTE HOY").font(.caption.bold()).foregroundColor(.ascendTextSecondary)
                            ForEach(todaySports) { sport in
                                HStack {
                                    Text(sport.name).foregroundColor(.ascendTextPrimary)
                                    Spacer()
                                    Text("\(sport.start.label)–\(sport.end.label)")
                                        .font(.caption).foregroundColor(.ascendTextSecondary)
                                }
                                .padding(12)
                                .background(Color.ascendCard)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }

                    if !appState.workouts.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("MI SEMANA").font(.caption.bold()).foregroundColor(.ascendTextSecondary)
                            ForEach(appState.workouts) { workout in
                                NavigationLink {
                                    WorkoutTrackerView(workoutID: workout.id)
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(workout.name).font(.subheadline.bold()).foregroundColor(.ascendTextPrimary)
                                            Text("\(workout.daysLabel) · \(workout.exercises.count) ejercicios")
                                                .font(.caption).foregroundColor(.ascendTextSecondary)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right").font(.caption).foregroundColor(.ascendGray)
                                    }
                                    .padding(12)
                                    .background(Color.ascendCard)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.ascendGray.opacity(0.15)))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .sheet(isPresented: $showWorkoutEditor) {
            WorkoutScheduleSheet { appState.addWorkout($0) }
        }
        .sheet(isPresented: $showSportEditor) {
            SportEditorSheet { appState.addSport($0) }
        }
    }

    private func todayCard(_ workout: Workout) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ENTRENAMIENTO DE HOY").font(.caption.bold()).foregroundColor(.ascendTextSecondary)
            Text(workout.name.uppercased())
                .font(.title3.bold())
                .foregroundColor(.ascendTextPrimary)

            if workout.exercises.isEmpty {
                Text("Toca para agregar ejercicios.")
                    .font(.footnote).foregroundColor(.ascendTextSecondary)
            } else {
                ForEach(workout.exercises.prefix(4)) { exercise in
                    HStack {
                        Text(exercise.name).font(.subheadline).foregroundColor(.ascendTextPrimary)
                        Spacer()
                        Text(exercise.sets.isEmpty ? "—" : "\(exercise.sets.count) sets")
                            .font(.caption).foregroundColor(.ascendTextSecondary)
                    }
                }
                if workout.exercises.count > 4 {
                    Text("+\(workout.exercises.count - 4) más")
                        .font(.caption).foregroundColor(.ascendTextSecondary)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.ascendSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

/// Tracker real: sets, reps, peso, historial y descanso.
struct WorkoutTrackerView: View {
    @EnvironmentObject private var appState: AppState
    let workoutID: UUID

    @State private var showExerciseEditor = false
    @State private var restRemaining: Int? = nil
    @State private var restTimer: Timer? = nil
    @State private var restPaused = false

    private var workout: Workout? { appState.workouts.first { $0.id == workoutID } }

    var body: some View {
        List {
            if let workout {
                ForEach(workout.exercises) { exercise in
                    Section {
                        ForEach(Array(exercise.sets.enumerated()), id: \.element.id) { index, set in
                            setRow(exercise: exercise, index: index, set: set)
                        }
                        Button {
                            addSet(to: exercise)
                        } label: {
                            Label("Agregar serie", systemImage: "plus")
                                .font(.footnote)
                        }
                    } header: {
                        HStack {
                            Text(exercise.name)
                            Spacer()
                            if let last = appState.lastLog(for: exercise.name), let best = last.bestSetLabel {
                                Text("Última: \(best)")
                                    .font(.caption2)
                                    .textCase(nil)
                                    .foregroundColor(.ascendTextSecondary)
                            }
                        }
                    }
                }

                Section {
                    Button {
                        showExerciseEditor = true
                    } label: {
                        Label("Agregar ejercicio", systemImage: "plus.circle")
                    }
                    Button {
                        appState.finishWorkout(workout)
                    } label: {
                        Label("Terminar entrenamiento", systemImage: "checkmark.circle")
                    }
                    .disabled(workout.exercises.allSatisfy { $0.sets.allSatisfy { !$0.isCompleted } })
                }
            }
        }
        .ascendListStyle()
        .navigationTitle(workout?.name ?? "Entrenamiento")
        .safeAreaInset(edge: .bottom) {
            if let restRemaining { restBar(restRemaining) }
        }
        .sheet(isPresented: $showExerciseEditor) {
            ExerciseEditorSheet { exercise in
                guard var workout else { return }
                workout.exercises.append(exercise)
                appState.updateWorkout(workout)
            }
        }
        .onDisappear { restTimer?.invalidate() }
    }

    private func setRow(exercise: Exercise, index: Int, set: ExerciseSet) -> some View {
        HStack(spacing: 10) {
            Text("\(index + 1)")
                .font(.caption.bold())
                .frame(width: 22, height: 22)
                .background(Color.ascendSurface)
                .clipShape(Circle())

            TextField("kg", value: binding(for: exercise, index: index).weightKg, format: .number)
                .keyboardType(.decimalPad)
                .frame(width: 62)
                .textFieldStyle(.roundedBorder)
            Text("kg").font(.caption).foregroundColor(.ascendTextSecondary)

            TextField("reps", value: binding(for: exercise, index: index).reps, format: .number)
                .keyboardType(.numberPad)
                .frame(width: 52)
                .textFieldStyle(.roundedBorder)
            Text("reps").font(.caption).foregroundColor(.ascendTextSecondary)

            Spacer()

            Button {
                toggleCompleted(exercise: exercise, index: index, restSeconds: exercise.restSeconds)
            } label: {
                Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(set.isCompleted ? .ascendGold : .ascendGray)
            }
            .buttonStyle(.plain)
            .frame(minWidth: 44, minHeight: 44)
            .accessibilityLabel(set.isCompleted ? "Serie \(index + 1) completada" : "Marcar serie \(index + 1)")
        }
    }

    private func binding(for exercise: Exercise, index: Int) -> Binding<ExerciseSet> {
        Binding(
            get: {
                guard let w = workout, let e = w.exercises.first(where: { $0.id == exercise.id }),
                      index < e.sets.count else { return ExerciseSet(weightKg: 0, reps: 0) }
                return e.sets[index]
            },
            set: { newValue in
                guard var w = workout,
                      let ei = w.exercises.firstIndex(where: { $0.id == exercise.id }),
                      index < w.exercises[ei].sets.count else { return }
                w.exercises[ei].sets[index] = newValue
                appState.updateWorkout(w)
            }
        )
    }

    private func addSet(to exercise: Exercise) {
        guard var w = workout, let ei = w.exercises.firstIndex(where: { $0.id == exercise.id }) else { return }
        let previous = w.exercises[ei].sets.last
        w.exercises[ei].sets.append(ExerciseSet(weightKg: previous?.weightKg ?? 0, reps: previous?.reps ?? 8))
        appState.updateWorkout(w)
    }

    private func toggleCompleted(exercise: Exercise, index: Int, restSeconds: Int) {
        guard var w = workout, let ei = w.exercises.firstIndex(where: { $0.id == exercise.id }),
              index < w.exercises[ei].sets.count else { return }
        w.exercises[ei].sets[index].isCompleted.toggle()
        let justCompleted = w.exercises[ei].sets[index].isCompleted
        appState.updateWorkout(w)
        if justCompleted { startRest(seconds: restSeconds) }
    }

    // MARK: Rest timer

    private func startRest(seconds: Int) {
        restTimer?.invalidate()
        restRemaining = seconds
        restPaused = false
        restTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor in
                guard !restPaused, let current = restRemaining else { return }
                if current <= 1 {
                    stopRest()
                } else {
                    restRemaining = current - 1
                }
            }
        }
    }

    private func stopRest() {
        restTimer?.invalidate()
        restTimer = nil
        restRemaining = nil
    }

    private func restBar(_ seconds: Int) -> some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text("DESCANSO").font(.caption2.bold()).foregroundColor(.ascendTextSecondary)
                Text(String(format: "%02d:%02d", seconds / 60, seconds % 60))
                    .font(.system(.title3, design: .rounded).bold())
                    .foregroundColor(.ascendTextPrimary)
            }
            Spacer()
            Button(restPaused ? "Seguir" : "Pausa") { restPaused.toggle() }
                .buttonStyle(.bordered)
                .controlSize(.small)
            Button("+30s") { restRemaining = seconds + 30 }
                .buttonStyle(.bordered)
                .controlSize(.small)
            Button("Saltar") { stopRest() }
                .buttonStyle(.borderedProminent)
                .tint(.ascendGold)
                .controlSize(.small)
        }
        .padding(14)
        .background(.ultraThinMaterial)
    }
}

struct ExerciseEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (Exercise) -> Void

    @State private var name = ""
    @State private var setCount = 3
    @State private var reps = 8
    @State private var weight: Double = 0
    @State private var restSeconds = 120

    var body: some View {
        NavigationStack {
            Form {
                Section("Ejercicio") {
                    TextField("Ej. Press de banca", text: $name)
                }
                Section("Series iniciales") {
                    Stepper("\(setCount) series", value: $setCount, in: 1...10)
                    Stepper("\(reps) reps", value: $reps, in: 1...30)
                    HStack {
                        Text("Peso")
                        Spacer()
                        TextField("kg", value: $weight, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                }
                Section("Descanso") {
                    Stepper("\(restSeconds / 60):\(String(format: "%02d", restSeconds % 60)) min",
                            value: $restSeconds, in: 30...300, step: 15)
                }
            }
            .ascendListStyle()
            .navigationTitle("Nuevo ejercicio")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        let sets = (0..<setCount).map { _ in ExerciseSet(weightKg: weight, reps: reps) }
                        onSave(Exercise(name: name, sets: sets, restSeconds: restSeconds))
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
