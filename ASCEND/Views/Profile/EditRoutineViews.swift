import SwiftUI

/// Punto 47: nada de lo configurado en el onboarding queda bloqueado.

struct EditScheduleView: View {
    @EnvironmentObject private var appState: AppState
    @State private var editingClass: SchoolClass? = nil
    @State private var showNewClass = false

    var body: some View {
        List {
            Section("Nivel académico") {
                Picker("Estudias", selection: $appState.education.level) {
                    ForEach(EducationLevel.allCases) { Text($0.rawValue).tag($0) }
                }
                if appState.education.level.asksGrade {
                    TextField("Grado", text: $appState.education.grade)
                }
                if appState.education.level.asksSemester {
                    TextField("Semestre", text: $appState.education.semester)
                }
                if appState.education.level.asksCareer {
                    TextField("Carrera", text: $appState.education.career)
                }
                if appState.education.level.asksFreeText {
                    TextField("¿Qué estudias?", text: $appState.education.customStudy)
                }
            }

            if appState.education.studies {
                Section("Horario general") {
                    TimeOfDayPicker(title: "Entrada", time: Binding(
                        get: { appState.education.schoolStart ?? TimeOfDay(7) },
                        set: { appState.education.schoolStart = $0 }))
                    TimeOfDayPicker(title: "Salida", time: Binding(
                        get: { appState.education.schoolEnd ?? TimeOfDay(15) },
                        set: { appState.education.schoolEnd = $0 }))
                }

                Section("Mis clases") {
                    ForEach(appState.classes) { item in
                        Button { editingClass = item } label: { ClassRow(item: item) }
                            .buttonStyle(.plain)
                    }
                    .onDelete { indexSet in
                        for index in indexSet { appState.deleteClass(appState.classes[index]) }
                    }
                    Button { showNewClass = true } label: {
                        Label("Agregar clase", systemImage: "plus")
                    }
                }
            }
        }
        .ascendListStyle()
        .navigationTitle("Escuela")
        .sheet(isPresented: $showNewClass) {
            ClassEditorSheet { appState.addClass($0) }
        }
        .sheet(item: $editingClass) { item in
            ClassEditorSheet(editing: item) { appState.updateClass($0) }
        }
        .onDisappear { Task { await NotificationService.shared.reschedule(state: appState) } }
    }
}

struct EditTrainingView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showNewWorkout = false
    @State private var showNewSport = false

    var body: some View {
        List {
            Section("Actividad física") {
                Picker("Haces", selection: $appState.activityKind) {
                    ForEach(PhysicalActivityKind.allCases) { Text($0.rawValue).tag($0) }
                }
            }

            Section("Entrenamientos") {
                ForEach(appState.workouts) { workout in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(workout.name)
                        Text("\(workout.daysLabel) · \(workout.start?.label ?? "—")–\(workout.end?.label ?? "—")")
                            .font(.caption).foregroundColor(.ascendTextSecondary)
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet { appState.deleteWorkout(appState.workouts[index]) }
                }
                Button { showNewWorkout = true } label: { Label("Agregar entrenamiento", systemImage: "plus") }
            }

            Section("Deportes") {
                ForEach(appState.sports) { sport in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(sport.name)
                        Text("\(sport.daysLabel) · \(sport.start.label)–\(sport.end.label)")
                            .font(.caption).foregroundColor(.ascendTextSecondary)
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet { appState.deleteSport(appState.sports[index]) }
                }
                Button { showNewSport = true } label: { Label("Agregar deporte", systemImage: "plus") }
            }
        }
        .ascendListStyle()
        .navigationTitle("Entrenamiento")
        .sheet(isPresented: $showNewWorkout) { WorkoutScheduleSheet { appState.addWorkout($0) } }
        .sheet(isPresented: $showNewSport) { SportEditorSheet { appState.addSport($0) } }
        .onDisappear { Task { await NotificationService.shared.reschedule(state: appState) } }
    }
}

struct EditMealsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var editingMeal: Meal? = nil
    @State private var showNewMeal = false

    var body: some View {
        List {
            Section("Objetivo físico") {
                Picker("Objetivo", selection: $appState.physicalGoal) {
                    ForEach(PhysicalGoal.allCases) { Text($0.rawValue).tag($0) }
                }
            }
            Section("Horarios de comida") {
                ForEach(appState.meals) { meal in
                    Button { editingMeal = meal } label: {
                        HStack {
                            Text(meal.name).foregroundColor(.ascendTextPrimary)
                            Spacer()
                            Text(meal.time.label).foregroundColor(.ascendTextSecondary)
                        }
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet { appState.deleteMeal(appState.meals[index]) }
                }
                Button { showNewMeal = true } label: { Label("Agregar comida", systemImage: "plus") }
            }
        }
        .ascendListStyle()
        .navigationTitle("Comidas")
        .sheet(isPresented: $showNewMeal) { MealEditorSheet { appState.addMeal($0) } }
        .sheet(item: $editingMeal) { meal in
            MealEditorSheet(editing: meal,
                            onSave: { appState.updateMeal($0) },
                            onDelete: { appState.deleteMeal(meal) })
        }
        .onDisappear { Task { await NotificationService.shared.reschedule(state: appState) } }
    }
}

struct EditActivitiesView: View {
    @EnvironmentObject private var appState: AppState
    @State private var editingActivity: CustomActivity? = nil
    @State private var showNewActivity = false

    var body: some View {
        List {
            Section("Bloques de tiempo libre") {
                if appState.freeTimeBlocks.isEmpty {
                    Text("Sin bloques marcados. ASCEND igual detecta los huecos entre tus actividades.")
                        .font(.footnote).foregroundColor(.ascendTextSecondary)
                }
                ForEach(appState.freeTimeBlocks) { block in
                    Text("\(block.days.sorted().map(\.short).joined(separator: ", ")) · \(block.start.label)–\(block.end.label)")
                }
                .onDelete { indexSet in
                    appState.freeTimeBlocks.remove(atOffsets: indexSet)
                }
            }

            Section("Actividades") {
                ForEach(appState.customActivities) { activity in
                    Button { editingActivity = activity } label: {
                        HStack {
                            Image(systemName: activity.icon).foregroundColor(Color(hex: activity.colorHex))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(activity.name).foregroundColor(.ascendTextPrimary)
                                Text("\(activity.category) · \(activity.daysLabel)")
                                    .font(.caption).foregroundColor(.ascendTextSecondary)
                            }
                        }
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet { appState.deleteCustomActivity(appState.customActivities[index]) }
                }
                Button { showNewActivity = true } label: { Label("Agregar actividad", systemImage: "plus") }
            }
        }
        .ascendListStyle()
        .navigationTitle("Actividades")
        .sheet(isPresented: $showNewActivity) {
            CustomActivityEditorSheet(lanes: appState.customLanes) { appState.addCustomActivity($0) }
        }
        .sheet(item: $editingActivity) { activity in
            CustomActivityEditorSheet(editing: activity, lanes: appState.customLanes) {
                appState.updateCustomActivity($0)
            }
        }
        .onDisappear { Task { await NotificationService.shared.reschedule(state: appState) } }
    }
}
