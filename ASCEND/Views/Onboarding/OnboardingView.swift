import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var notifications = NotificationService.shared

    private enum Step: Hashable {
        case welcome, education, educationDetail, schoolHours, classes
        case freeTime, activity, gym, sport, meals, physicalGoal, custom, notifications
    }

    @State private var index = 0

    // Respuestas en borrador: nada se escribe en AppState hasta terminar cada paso.
    @State private var name = ""
    @State private var education = UserEducation()
    @State private var classes: [SchoolClass] = []
    @State private var freeBlocks: [FreeTimeBlock] = []
    @State private var activityKind: PhysicalActivityKind = .none
    @State private var workouts: [Workout] = []
    @State private var sports: [Sport] = []
    @State private var meals: [Meal] = [
        Meal(name: "Desayuno", time: TimeOfDay(8)),
        Meal(name: "Comida", time: TimeOfDay(14)),
        Meal(name: "Cena", time: TimeOfDay(20, 30))
    ]
    @State private var physicalGoal: PhysicalGoal = .notSet
    @State private var customActivities: [CustomActivity] = []

    @State private var showClassEditor = false
    @State private var showWorkoutEditor = false
    @State private var showSportEditor = false
    @State private var showActivityEditor = false
    @State private var showFreeTimeEditor = false

    /// El flujo se adapta solo: si no estudia, los pasos escolares no existen.
    private var steps: [Step] {
        var result: [Step] = [.welcome, .education]
        if education.level.studies {
            result.append(.educationDetail)
            result.append(.schoolHours)
            result.append(.classes)
        }
        result.append(.freeTime)
        result.append(.activity)
        if activityKind.includesGym { result.append(.gym) }
        if activityKind.includesSport { result.append(.sport) }
        result += [.meals, .physicalGoal, .custom, .notifications]
        return result
    }

    private var currentStep: Step { steps[min(index, steps.count - 1)] }
    private var isLastStep: Bool { index >= steps.count - 1 }

    var body: some View {
        VStack(spacing: 20) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    stepContent
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
                .readableWidth()
            }

            footer
        }
        .background(Color.ascendBackground.ignoresSafeArea())
        .sheet(isPresented: $showClassEditor) {
            ClassEditorSheet { classes.append($0) }
        }
        .sheet(isPresented: $showWorkoutEditor) {
            WorkoutScheduleSheet { workouts.append($0) }
        }
        .sheet(isPresented: $showSportEditor) {
            SportEditorSheet { sports.append($0) }
        }
        .sheet(isPresented: $showActivityEditor) {
            CustomActivityEditorSheet(lanes: []) { customActivities.append($0) }
        }
        .sheet(isPresented: $showFreeTimeEditor) {
            FreeTimeEditorSheet { freeBlocks.append($0) }
        }
    }

    // MARK: Header / footer

    private var header: some View {
        VStack(spacing: 14) {
            AscendLogoTile(size: 52)
                .padding(.top, 28)
            ProgressView(value: Double(index + 1), total: Double(steps.count))
                .tint(.ascendGold)
                .padding(.horizontal, 24)
        }
    }

    private var footer: some View {
        HStack(spacing: 12) {
            if index > 0 {
                Button("Atrás") { withAnimation { index -= 1 } }
                    .foregroundColor(.ascendTextSecondary)
                    .frame(minWidth: 66, minHeight: 44)
            }
            Button(action: advance) {
                Text(isLastStep ? "Empezar" : "Continuar")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(canAdvance ? Color.ascendGold : Color.ascendGray.opacity(0.4))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .disabled(!canAdvance)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
        .readableWidth()
    }

    private var canAdvance: Bool {
        switch currentStep {
        case .welcome: return !name.trimmingCharacters(in: .whitespaces).isEmpty
        case .education: return education.level != .none || education.level == .none // siempre hay respuesta válida
        case .educationDetail:
            switch education.level {
            case .middleSchool: return !education.grade.isEmpty
            case .highSchool: return !education.semester.isEmpty
            case .university: return !education.career.isEmpty && !education.semester.isEmpty
            case .other: return !education.customStudy.isEmpty
            case .none: return true
            }
        default: return true // todo lo demás es opcional: ASCEND no obliga a llenar nada
        }
    }

    private func advance() {
        if isLastStep {
            finish()
        } else {
            withAnimation { index += 1 }
        }
    }

    private func finish() {
        appState.profile.name = name
        appState.education = education
        appState.classes = classes
        appState.freeTimeBlocks = freeBlocks
        appState.activityKind = activityKind
        appState.workouts = workouts
        appState.sports = sports
        appState.meals = meals.sorted { $0.time < $1.time }
        appState.physicalGoal = physicalGoal
        appState.customActivities = customActivities
        appState.completeOnboarding()

        Task {
            await NotificationService.shared.reschedule(state: appState)
        }
    }

    // MARK: Contenido por paso

    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case .welcome: welcomeStep
        case .education: educationStep
        case .educationDetail: educationDetailStep
        case .schoolHours: schoolHoursStep
        case .classes: classesStep
        case .freeTime: freeTimeStep
        case .activity: activityStep
        case .gym: gymStep
        case .sport: sportStep
        case .meals: mealsStep
        case .physicalGoal: goalStep
        case .custom: customStep
        case .notifications: notificationsStep
        }
    }

    private func title(_ text: String, _ subtitle: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(text).font(.title2.bold()).foregroundColor(.ascendTextPrimary)
            if let subtitle {
                Text(subtitle).font(.subheadline).foregroundColor(.ascendTextSecondary)
            }
        }
    }

    private var welcomeStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            title("¿Cómo te llamas?", "ASCEND se construye alrededor de tu rutina real, no al revés.")
            TextField("Tu nombre", text: $name).textFieldStyle(.roundedBorder)
        }
    }

    private var educationStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            title("¿Actualmente estudias?")
            ForEach(EducationLevel.allCases) { level in
                AscendOptionRow(label: level.rawValue, isSelected: education.level == level) {
                    education.level = level
                }
            }
        }
    }

    @ViewBuilder
    private var educationDetailStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            switch education.level {
            case .middleSchool:
                title("¿Qué grado cursas?")
                ForEach(["1°", "2°", "3°"], id: \.self) { grade in
                    AscendOptionRow(label: "\(grade) de secundaria", isSelected: education.grade == grade) {
                        education.grade = grade
                    }
                }
            case .highSchool:
                title("¿Qué semestre o grado cursas?")
                TextField("Ej. 3er semestre", text: $education.semester).textFieldStyle(.roundedBorder)
            case .university:
                title("¿Qué estudias?")
                TextField("Carrera", text: $education.career).textFieldStyle(.roundedBorder)
                TextField("Semestre actual", text: $education.semester).textFieldStyle(.roundedBorder)
            case .other:
                title("¿Qué estudias?")
                TextField("Escríbelo con tus palabras", text: $education.customStudy).textFieldStyle(.roundedBorder)
            case .none:
                EmptyView()
            }
        }
    }

    private var schoolHoursStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            title("¿De qué hora a qué hora normalmente estás en la escuela?",
                  "Es aproximado. Sirve para saber en qué parte del día tienes espacio.")
            VStack(spacing: 10) {
                TimeOfDayPicker(title: "Entrada", time: Binding(
                    get: { education.schoolStart ?? TimeOfDay(7) },
                    set: { education.schoolStart = $0 }))
                TimeOfDayPicker(title: "Salida", time: Binding(
                    get: { education.schoolEnd ?? TimeOfDay(15) },
                    set: { education.schoolEnd = $0 }))
            }
            .padding()
            .background(Color.ascendCard)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    private var classesStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            title("Ahora vamos a construir tu horario real",
                  "Agrega tus materias una por una. ASCEND no inventa ninguna: solo usa las que tú pongas.")

            ForEach(classes) { item in
                HStack {
                    ClassRow(item: item)
                    Button {
                        classes.removeAll { $0.id == item.id }
                    } label: {
                        Image(systemName: "trash").foregroundColor(.ascendGray)
                    }
                    .frame(minWidth: 44, minHeight: 44)
                    .accessibilityLabel("Eliminar \(item.subject)")
                }
                .padding(12)
                .background(Color.ascendCard)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Button {
                showClassEditor = true
            } label: {
                Label("Agregar clase", systemImage: "plus")
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(Color.ascendSurface)
                    .foregroundColor(.ascendTextPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            if classes.isEmpty {
                Text("Puedes saltarte esto y agregarlas después desde Ajustes.")
                    .font(.footnote)
                    .foregroundColor(.ascendTextSecondary)
            }
        }
    }

    private var freeTimeStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            title("¿Cuándo tienes tiempo libre normalmente?",
                  "ASCEND puede usar tus espacios libres para ayudarte a encontrar mejores momentos para estudiar, entrenar o completar pendientes. Nunca los va a llenar solo.")

            ForEach(freeBlocks) { block in
                HStack {
                    VStack(alignment: .leading) {
                        Text(block.days.sorted().map(\.short).joined(separator: ", "))
                            .font(.subheadline.bold())
                        Text("\(block.start.label) – \(block.end.label)")
                            .font(.caption).foregroundColor(.ascendTextSecondary)
                    }
                    Spacer()
                    Button {
                        freeBlocks.removeAll { $0.id == block.id }
                    } label: {
                        Image(systemName: "trash").foregroundColor(.ascendGray)
                    }
                    .frame(minWidth: 44, minHeight: 44)
                }
                .padding(12)
                .background(Color.ascendCard)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Button {
                showFreeTimeEditor = true
            } label: {
                Label("Agregar bloque libre", systemImage: "plus")
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(Color.ascendSurface)
                    .foregroundColor(.ascendTextPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Text("También los detecta solo con los huecos entre tus actividades.")
                .font(.footnote).foregroundColor(.ascendTextSecondary)
        }
    }

    private var activityStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            title("¿Realizas alguna actividad física?")
            ForEach(PhysicalActivityKind.allCases) { kind in
                AscendOptionRow(label: kind.rawValue, isSelected: activityKind == kind) {
                    activityKind = kind
                }
            }
        }
    }

    private var gymStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            title("Tu gimnasio", "Qué días entrenas y a qué hora. La rutina con ejercicios la puedes armar después.")

            ForEach(workouts) { workout in
                HStack {
                    VStack(alignment: .leading) {
                        Text(workout.name).font(.subheadline.bold())
                        Text("\(workout.daysLabel) · \(workout.start?.label ?? "")–\(workout.end?.label ?? "")")
                            .font(.caption).foregroundColor(.ascendTextSecondary)
                    }
                    Spacer()
                    Button {
                        workouts.removeAll { $0.id == workout.id }
                    } label: { Image(systemName: "trash").foregroundColor(.ascendGray) }
                        .frame(minWidth: 44, minHeight: 44)
                }
                .padding(12)
                .background(Color.ascendCard)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Button {
                showWorkoutEditor = true
            } label: {
                Label("Agregar día de entrenamiento", systemImage: "plus")
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(Color.ascendSurface)
                    .foregroundColor(.ascendTextPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var sportStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            title("Tu deporte")

            ForEach(sports) { sport in
                HStack {
                    VStack(alignment: .leading) {
                        Text(sport.name).font(.subheadline.bold())
                        Text("\(sport.daysLabel) · \(sport.start.label)–\(sport.end.label)")
                            .font(.caption).foregroundColor(.ascendTextSecondary)
                    }
                    Spacer()
                    Button {
                        sports.removeAll { $0.id == sport.id }
                    } label: { Image(systemName: "trash").foregroundColor(.ascendGray) }
                        .frame(minWidth: 44, minHeight: 44)
                }
                .padding(12)
                .background(Color.ascendCard)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Button {
                showSportEditor = true
            } label: {
                Label("Agregar deporte", systemImage: "plus")
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(Color.ascendSurface)
                    .foregroundColor(.ascendTextPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var mealsStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            title("¿A qué horas sueles comer?", "Cambia las horas, los nombres, o elimina las que no apliquen.")

            ForEach($meals) { $meal in
                VStack(spacing: 8) {
                    HStack {
                        TextField("Nombre", text: $meal.name)
                        Button {
                            meals.removeAll { $0.id == meal.id }
                        } label: { Image(systemName: "trash").foregroundColor(.ascendGray) }
                            .frame(minWidth: 44, minHeight: 44)
                            .accessibilityLabel("Eliminar \(meal.name)")
                    }
                    TimeOfDayPicker(title: "Hora", time: $meal.time)
                }
                .padding(12)
                .background(Color.ascendCard)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Button {
                meals.append(Meal(name: "Snack", time: TimeOfDay(17)))
            } label: {
                Label("Agregar comida o snack", systemImage: "plus")
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(Color.ascendSurface)
                    .foregroundColor(.ascendTextPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var goalStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            title("¿Cuál es tu objetivo físico ahora?", "Solo se guarda en tu perfil. ASCEND no da recomendaciones médicas ni dietas.")
            ForEach(PhysicalGoal.allCases.filter { $0 != .notSet }) { goal in
                AscendOptionRow(label: goal.rawValue, isSelected: physicalGoal == goal) {
                    physicalGoal = goal
                }
            }
            AscendOptionRow(label: "Prefiero no decirlo", isSelected: physicalGoal == .notSet) {
                physicalGoal = .notSet
            }
        }
    }

    private var customStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            title("¿Quieres agregar algo más a tu rutina?", "Trabajo, hobbies, lectura, familia, proyectos… lo que tú quieras seguir.")

            ForEach(customActivities) { activity in
                HStack {
                    Image(systemName: activity.icon).foregroundColor(Color(hex: activity.colorHex))
                    VStack(alignment: .leading) {
                        Text(activity.name).font(.subheadline.bold())
                        Text("\(activity.category) · \(activity.daysLabel) · \(activity.start.label)–\(activity.end.label)")
                            .font(.caption).foregroundColor(.ascendTextSecondary)
                    }
                    Spacer()
                    Button {
                        customActivities.removeAll { $0.id == activity.id }
                    } label: { Image(systemName: "trash").foregroundColor(.ascendGray) }
                        .frame(minWidth: 44, minHeight: 44)
                }
                .padding(12)
                .background(Color.ascendCard)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Button {
                showActivityEditor = true
            } label: {
                Label("Agregar actividad", systemImage: "plus")
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(Color.ascendSurface)
                    .foregroundColor(.ascendTextPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var notificationsStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            title("¿Te avisamos de lo importante?",
                  "ASCEND puede recordarte clases, entrenamientos, entregas y actividades importantes. Tú decides cuáles, y siempre puedes apagarlas.")

            VStack(alignment: .leading, spacing: 8) {
                Label("Máximo \(appState.notificationPrefs.maxPerDay) al día", systemImage: "bell.badge")
                Label("Nunca de madrugada", systemImage: "moon.zzz")
                Label("Puedes cambiarlo cuando quieras", systemImage: "slider.horizontal.3")
            }
            .font(.subheadline)
            .foregroundColor(.ascendTextSecondary)

            Button {
                Task { await notifications.requestAuthorization() }
            } label: {
                Text(notifications.authorizationStatus == .authorized ? "Notificaciones activadas ✓" : "Activar notificaciones")
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(Color.ascendSurface)
                    .foregroundColor(.ascendTextPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(notifications.authorizationStatus == .authorized)

            Text("Si prefieres no activarlas, ASCEND funciona igual.")
                .font(.footnote)
                .foregroundColor(.ascendTextSecondary)
        }
        .task { await notifications.refreshStatus() }
    }
}
