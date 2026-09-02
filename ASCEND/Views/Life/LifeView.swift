import SwiftUI

struct LifeView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showGoalEditor = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    goalsBlock
                } header: {
                    Text("Tus metas")
                }

                Section("Tu vida") {
                    NavigationLink("To-dos por área") { TodosView() }
                    NavigationLink("Dinero") { ExpensesGateView() }
                    NavigationLink("Guía de trámites") { TramitesView() }
                    NavigationLink("Reventa estudiantil") { ResaleView() }
                }

                Section("Resumen") {
                    LabeledContent("Racha actual", value: "\(appState.currentStreak) días")
                    LabeledContent("Pendientes", value: "\(appState.todos.filter { !$0.isDone }.count)")
                    if appState.budget.isConfigured {
                        LabeledContent("Presupuesto restante",
                                       value: "$\(Int(appState.remainingBudgetMXN)) MXN")
                    }
                }
            }
            .ascendListStyle()
            .navigationTitle("Vida")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { StreakBadge() }
            }
            .sheet(isPresented: $showGoalEditor) {
                GoalEditorSheet { appState.addGoal($0) }
            }
        }
    }

    @ViewBuilder
    private var goalsBlock: some View {
        if let goal = appState.primaryGoal {
            NavigationLink {
                GoalsListView()
            } label: {
                VStack(alignment: .leading, spacing: 10) {
                    Text(goal.title)
                        .font(.title3.bold())
                        .foregroundColor(.ascendTextPrimary)
                    if !goal.detail.isEmpty {
                        Text(goal.detail).font(.footnote).foregroundColor(.ascendTextSecondary)
                    }
                    if !goal.milestones.isEmpty {
                        ProgressView(value: goal.progress).tint(.ascendGold)
                        Text("\(goal.milestones.filter(\.isDone).count) de \(goal.milestones.count) pasos")
                            .font(.caption)
                            .foregroundColor(.ascendTextSecondary)
                    }
                }
                .padding(.vertical, 6)
            }
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Text("Aún no tienes una meta definida.")
                    .font(.subheadline)
                    .foregroundColor(.ascendTextPrimary)
                Text("Una meta con pasos concretos hace que el resto de ASCEND tenga sentido.")
                    .font(.footnote)
                    .foregroundColor(.ascendTextSecondary)
                Button("Crear mi meta") { showGoalEditor = true }
                    .buttonStyle(.borderedProminent)
                    .tint(.ascendGold)
            }
            .padding(.vertical, 6)
        }
    }
}

struct GoalsListView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showEditor = false

    var body: some View {
        List {
            ForEach(appState.goals) { goal in
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(goal.title).font(.headline)
                            Spacer()
                            if goal.isPrimary {
                                Text("Principal").font(.caption2)
                                    .padding(.horizontal, 8).padding(.vertical, 3)
                                    .background(Color.ascendSurface).clipShape(Capsule())
                            }
                        }
                        if !goal.detail.isEmpty {
                            Text(goal.detail).font(.footnote).foregroundColor(.ascendTextSecondary)
                        }
                        if let date = goal.targetDate {
                            Text("Para \(date.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption).foregroundColor(.ascendTextSecondary)
                        }
                    }

                    ForEach(goal.milestones) { milestone in
                        Button { appState.toggleMilestone(milestone, in: goal) } label: {
                            HStack {
                                Image(systemName: milestone.isDone ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(milestone.isDone ? .ascendGold : .ascendGray)
                                Text(milestone.title)
                                    .foregroundColor(.ascendTextPrimary)
                                    .strikethrough(milestone.isDone)
                            }
                        }
                    }

                    if !goal.isPrimary {
                        Button("Hacer principal") { appState.setPrimaryGoal(goal) }
                            .font(.caption)
                    }
                    Button("Eliminar meta", role: .destructive) { appState.deleteGoal(goal) }
                        .font(.caption)
                }
            }
        }
        .ascendListStyle()
        .navigationTitle("Metas")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showEditor = true } label: { Image(systemName: "plus") }
                    .accessibilityLabel("Nueva meta")
            }
        }
        .sheet(isPresented: $showEditor) {
            GoalEditorSheet { appState.addGoal($0) }
        }
    }
}

struct GoalEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (Goal) -> Void

    @State private var title = ""
    @State private var detail = ""
    @State private var hasTargetDate = false
    @State private var targetDate = Date()
    @State private var milestones: [String] = [""]

    var body: some View {
        NavigationStack {
            Form {
                Section("Meta") {
                    TextField("Ej. Pasar el semestre sin reprobar", text: $title)
                    TextField("¿Por qué te importa? (opcional)", text: $detail)
                }
                Section("Fecha objetivo") {
                    Toggle("Tiene fecha", isOn: $hasTargetDate)
                    if hasTargetDate {
                        DatePicker("Para", selection: $targetDate, displayedComponents: .date)
                    }
                }
                Section("Pasos") {
                    ForEach(milestones.indices, id: \.self) { index in
                        TextField("Paso \(index + 1)", text: $milestones[index])
                    }
                    Button("Agregar paso") { milestones.append("") }
                        .font(.caption)
                }
            }
            .ascendListStyle()
            .navigationTitle("Nueva meta")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        onSave(Goal(
                            title: title, detail: detail,
                            milestones: milestones.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
                                .map { Milestone(title: $0) },
                            targetDate: hasTargetDate ? targetDate : nil))
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

struct TodosView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showEditor = false

    private var grouped: [(LifeArea, [TodoItem])] {
        LifeArea.allCases.map { area in (area, appState.todos.filter { $0.area == area }) }
            .filter { !$0.1.isEmpty }
    }

    var body: some View {
        List {
            if appState.todos.isEmpty {
                Text("Sin pendientes. Agrega los tuyos con el +.")
                    .font(.footnote).foregroundColor(.ascendTextSecondary)
            }
            ForEach(grouped, id: \.0) { area, items in
                Section(area.rawValue) {
                    ForEach(items) { item in
                        HStack {
                            Button { appState.toggleTodo(item) } label: {
                                Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(item.isDone ? .ascendGold : .ascendGray)
                            }
                            .buttonStyle(.plain)
                            .frame(minWidth: 44, minHeight: 44)
                            .accessibilityLabel(item.isDone ? "Hecho: \(item.title)" : "Marcar como hecho: \(item.title)")

                            VStack(alignment: .leading) {
                                Text(item.title).strikethrough(item.isDone)
                                Text(item.priority.rawValue).font(.caption).foregroundColor(.ascendTextSecondary)
                            }
                            Spacer()
                            Button("Posponer") { appState.postpone(item) }
                                .font(.caption)
                                .foregroundColor(.ascendGray)
                        }
                        .swipeActions {
                            Button("Eliminar", role: .destructive) { appState.deleteTodo(item) }
                        }
                    }
                }
            }
        }
        .ascendListStyle()
        .navigationTitle("To-dos")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showEditor = true } label: { Image(systemName: "plus") }
                    .accessibilityLabel("Nuevo pendiente")
            }
        }
        .sheet(isPresented: $showEditor) {
            TodoEditorSheet { appState.addTodo($0) }
        }
    }
}

struct TodoEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (TodoItem) -> Void

    @State private var title = ""
    @State private var area: LifeArea = .personal
    @State private var priority: TodoPriority = .medium

    var body: some View {
        NavigationStack {
            Form {
                TextField("Pendiente", text: $title)
                Picker("Área", selection: $area) {
                    ForEach(LifeArea.allCases) { Text($0.rawValue).tag($0) }
                }
                Picker("Prioridad", selection: $priority) {
                    ForEach(TodoPriority.allCases) { Text($0.rawValue).tag($0) }
                }
            }
            .ascendListStyle()
            .navigationTitle("Nuevo pendiente")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        onSave(TodoItem(title: title, area: area, priority: priority))
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

struct TramitesView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        List(appState.tramites) { guide in
            NavigationLink(guide.title) { TramiteDetailView(guide: guide) }
        }
        .ascendListStyle()
        .navigationTitle("Trámites")
    }
}

struct TramiteDetailView: View {
    @EnvironmentObject private var appState: AppState
    let guide: TramiteGuide

    private var current: TramiteGuide {
        appState.tramites.first { $0.id == guide.id } ?? guide
    }

    var body: some View {
        List {
            Section {
                Text(current.progressText).foregroundColor(.ascendTextSecondary)
            }
            ForEach(Array(current.steps.enumerated()), id: \.offset) { index, step in
                Button { appState.toggleStep(index, in: current) } label: {
                    HStack {
                        Image(systemName: current.completedSteps.contains(index) ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(current.completedSteps.contains(index) ? .ascendGold : .ascendGray)
                        Text(step).foregroundColor(.ascendTextPrimary)
                    }
                }
            }
        }
        .ascendListStyle()
        .navigationTitle(current.title)
    }
}

struct ResaleView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showEditor = false

    var body: some View {
        List {
            Section {
                Text("Aquí solo se conecta a estudiantes. ASCEND no procesa pagos.")
                    .font(.footnote)
                    .foregroundColor(.ascendTextSecondary)
            }
            if appState.resaleItems.isEmpty {
                Text("Todavía no hay publicaciones. Publica algo que quieras vender o intercambiar.")
                    .font(.footnote).foregroundColor(.ascendTextSecondary)
            }
            ForEach(appState.resaleItems) { item in
                HStack {
                    VStack(alignment: .leading) {
                        Text(item.title)
                        Text("Vende: \(item.seller)").font(.caption).foregroundColor(.ascendTextSecondary)
                    }
                    Spacer()
                    Text("$\(Int(item.priceMXN)) MXN").bold()
                }
                .swipeActions {
                    Button("Eliminar", role: .destructive) { appState.deleteResaleItem(item) }
                }
            }
        }
        .ascendListStyle()
        .navigationTitle("Reventa")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showEditor = true } label: { Image(systemName: "plus") }
                    .accessibilityLabel("Publicar artículo")
            }
        }
        .sheet(isPresented: $showEditor) {
            ResaleEditorSheet(seller: appState.profile.name) { appState.addResaleItem($0) }
        }
    }
}

struct ResaleEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    let seller: String
    let onSave: (ResaleItem) -> Void

    @State private var title = ""
    @State private var price = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("¿Qué vendes?", text: $title)
                TextField("Precio (MXN)", text: $price).keyboardType(.decimalPad)
            }
            .ascendListStyle()
            .navigationTitle("Publicar")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Publicar") {
                        onSave(ResaleItem(title: title, priceMXN: Double(price) ?? 0,
                                          seller: seller.isEmpty ? "Yo" : seller))
                        dismiss()
                    }
                    .disabled(title.isEmpty || Double(price) == nil)
                }
            }
        }
    }
}
