import SwiftUI

struct LifeView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showTodoEditor = false
    /// nil = todavía no se toca: abre el área con más pendientes.
    @State private var expandedAreas: Set<LifeArea>? = nil

    private var pending: [TodoItem] { appState.todos.filter { !$0.isDone } }

    private var groups: [(area: LifeArea, items: [TodoItem])] {
        LifeArea.allCases.map { area in (area: area, items: appState.todos.filter { $0.area == area }) }
            .filter { !$0.items.isEmpty }
    }

    private var effectiveExpanded: Set<LifeArea> {
        if let expandedAreas { return expandedAreas }
        let busiest = groups.max { a, b in
            a.items.filter { !$0.isDone }.count < b.items.filter { !$0.isDone }.count
        }
        return busiest.map { [$0.area] } ?? []
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header

                    if appState.todos.isEmpty {
                        AscendEmptyState(
                            title: "Tu día está despejado",
                            message: "Cuando agregues pendientes aparecen aquí, agrupados por área. No hay nada que alcanzar hoy.",
                            actionTitle: "Agregar pendiente") { showTodoEditor = true }
                            .padding(.vertical, 40)
                    } else {
                        titleBlock
                        VStack(spacing: 10) {
                            ForEach(groups, id: \.area) { group in
                                areaGroup(group.area, items: group.items)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }

                    tilesGrid

                    AscendKicker(text: "Tu progreso")
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                    ProgressSummaryCard()
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                }
                .padding(.bottom, 90) // deja libre el FAB
                .readableWidth()
            }
            .background(Color.ascendBackground.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showTodoEditor) {
                TodoEditorSheet { appState.addTodo($0) }
            }
        }
    }

    // MARK: Encabezado

    private var header: some View {
        HStack(spacing: 4) {
            AscendKicker(text: "Vida")
            Spacer()
            StreakBadge()
            Button { showTodoEditor = true } label: {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.ascendGold)
                    .frame(minWidth: 44, minHeight: 44)
            }
            .accessibilityLabel("Nuevo pendiente")
        }
        .padding(.horizontal, 20)
        .padding(.top, 6)
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(pendingTitle)
                .font(.ascendRounded(27, relativeTo: .title))
                .foregroundColor(.ascendTextPrimary)
            Text("Puedes posponer lo que quieras, sin penalización.")
                .font(.footnote)
                .foregroundColor(.ascendTextSecondary)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }

    /// "Cuatro pendientes\npara hoy". Hasta diez se escribe con letra; más, con número.
    private var pendingTitle: String {
        let count = pending.count
        switch count {
        case 0: return "Todo al día\npor hoy"
        case 1: return "Un pendiente\npara hoy"
        default:
            let formatter = NumberFormatter()
            formatter.numberStyle = .spellOut
            formatter.locale = Locale(identifier: "es_MX")
            let word = count <= 10 ? (formatter.string(from: NSNumber(value: count)) ?? "\(count)") : "\(count)"
            return "\(word.prefix(1).uppercased())\(word.dropFirst()) pendientes\npara hoy"
        }
    }

    // MARK: Grupos colapsables por área

    private func toggle(_ area: LifeArea) {
        var set = effectiveExpanded
        if set.contains(area) { set.remove(area) } else { set.insert(area) }
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) { expandedAreas = set }
    }

    private func areaGroup(_ area: LifeArea, items: [TodoItem]) -> some View {
        let isOpen = effectiveExpanded.contains(area)
        let pendingCount = items.filter { !$0.isDone }.count
        return VStack(spacing: 0) {
            Button { toggle(area) } label: {
                HStack(spacing: 10) {
                    Image(systemName: area.icon)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(area.tint)
                    Text(area.rawValue)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.ascendTextPrimary)
                    Spacer()
                    Text("\(pendingCount)")
                        .font(.ascendRounded(12, relativeTo: .caption))
                        .foregroundColor(isOpen ? .ascendTextPrimary : .ascendTextSecondary)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(isOpen ? area.tint.opacity(0.28) : Color.ascendHairline))
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(isOpen ? area.tint : .ascendGray)
                        .rotationEffect(.degrees(isOpen ? 0 : -90))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .frame(minHeight: 44)
                .background(area.tint.opacity(isOpen ? 0.22 : 0.08))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(area.rawValue), \(pendingCount) pendientes")
            .accessibilityHint(isOpen ? "Contraer" : "Expandir")

            if isOpen {
                VStack(spacing: 0) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        todoRow(item)
                        if index < items.count - 1 {
                            Rectangle().fill(Color.ascendHairline).frame(height: 1)
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color.ascendCard)
        .overlay(alignment: .leading) { area.tint.frame(width: 3) }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color.ascendHairline, lineWidth: 1))
    }

    private func todoRow(_ item: TodoItem) -> some View {
        HStack(spacing: 12) {
            Button { appState.toggleTodo(item) } label: {
                AscendCheck(isOn: item.isDone, size: 24)
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(item.isDone ? "Hecho: \(item.title)" : "Marcar como hecho: \(item.title)")

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.ascendTextPrimary)
                    .strikethrough(item.isDone)
                Text(item.priority.rawValue)
                    .font(.caption2)
                    .foregroundColor(.ascendTextSecondary)
            }
            Spacer(minLength: 8)
            if !item.isDone {
                Button("Posponer") { appState.postpone(item) }
                    .buttonStyle(AscendPillButtonStyle())
            }
        }
        .padding(.leading, 6)
        .padding(.trailing, 16)
        .padding(.vertical, 4)
        .contextMenu {
            Button("Eliminar", role: .destructive) { appState.deleteTodo(item) }
        }
    }

    // MARK: Dinero, Trámites, Reventa, Metas

    private var moneySubtitle: String {
        guard appState.budget.isConfigured else { return "Sin presupuesto" }
        if appState.expensesHidden || appState.expensesPINEnabled { return "Privado" }
        return "$\(Int(appState.remainingBudgetMXN)) restantes"
    }

    private var tramitesSubtitle: String {
        let inProgress = appState.tramites.filter { !$0.completedSteps.isEmpty && $0.completedSteps.count < $0.steps.count }.count
        return inProgress == 0 ? "\(appState.tramites.count) guías" : "\(inProgress) en curso"
    }

    private var goalSubtitle: String {
        guard let goal = appState.primaryGoal else { return "Crea tu meta" }
        guard !goal.milestones.isEmpty else { return goal.title }
        return "\(goal.milestones.filter(\.isDone).count) de \(goal.milestones.count) pasos"
    }

    private var tilesGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 9), GridItem(.flexible(), spacing: 9)], spacing: 9) {
            tile(icon: "creditcard", title: "Dinero", subtitle: moneySubtitle) { ExpensesGateView() }
            tile(icon: "doc.text", title: "Trámites", subtitle: tramitesSubtitle) { TramitesView() }
            tile(icon: "bag", title: "Reventa", subtitle: "\(appState.resaleItems.count) publicaciones") { ResaleView() }
            tile(icon: "scope", title: "Metas", subtitle: goalSubtitle) { GoalsListView() }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    private func tile<Destination: View>(icon: String, title: String, subtitle: String,
                                         @ViewBuilder destination: @escaping () -> Destination) -> some View {
        NavigationLink(destination: destination) {
            VStack(alignment: .leading, spacing: 0) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.ascendGold)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.ascendTextPrimary)
                    .padding(.top, 10)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.ascendTextSecondary)
                    .lineLimit(1)
                    .padding(.top, 2)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .ascendCard()
        }
        .buttonStyle(AscendPressStyle())
        .accessibilityElement(children: .combine)
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
                Label("ASCEND solo conecta estudiantes entre sí. No procesa pagos, no verifica a compradores/vendedores y no es responsable de lo publicado.", systemImage: "exclamationmark.triangle.fill")
                    .font(.footnote.bold())
                    .foregroundColor(.ascendTextPrimary)
                    .padding(10)
                    .background(Color.ascendSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
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
