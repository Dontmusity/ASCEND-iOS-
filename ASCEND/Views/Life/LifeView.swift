import SwiftUI

struct LifeView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink("To-dos por área") { TodosView() }
                NavigationLink("Dinero") { ExpensesGateView() }
                NavigationLink("Comida") { FoodView() }
                NavigationLink("Guía de trámites") { TramitesView() }
                NavigationLink("Reventa estudiantil") { ResaleView() }
            }
            .ascendListStyle()
            .navigationTitle("Vida")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { StreakBadge() }
            }
        }
    }
}

struct TodosView: View {
    @EnvironmentObject private var appState: AppState

    private var grouped: [(LifeArea, [TodoItem])] {
        LifeArea.allCases.map { area in (area, appState.todos.filter { $0.area == area }) }
            .filter { !$0.1.isEmpty }
    }

    var body: some View {
        List {
            ForEach(grouped, id: \.0) { area, items in
                Section(area.rawValue) {
                    ForEach(items) { item in
                        HStack {
                            Button {
                                appState.toggleTodo(item)
                            } label: {
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
                    }
                }
            }
        }
        .ascendListStyle()
        .navigationTitle("To-dos")
    }
}

struct FoodView: View {
    @EnvironmentObject private var appState: AppState

    private var suggestion: (title: String, detail: String) {
        switch appState.weekIntensity {
        case .high:
            return ("Semana pesada: algo rápido y nutritivo", "Bowl de arroz, huevo y verdura salteada — 15 minutos, sin complicarte.")
        case .light:
            return ("Tienes espacio esta semana", "Buen momento para cocinar algo que te guste con calma.")
        case .normal:
            return ("Ritmo normal", "Pollo con verduras y arroz integral, sencillo y balanceado.")
        }
    }

    var body: some View {
        List {
            Section("Sugerencia de hoy") {
                VStack(alignment: .leading, spacing: 4) {
                    Text(suggestion.title).font(.headline)
                    Text(suggestion.detail).foregroundColor(.ascendTextSecondary)
                }
                .padding(.vertical, 4)
            }
            Section {
                Text("ASCEND no da dietas extremas, ayunos ni metas de peso — solo ideas simples según tu semana.")
                    .font(.footnote)
                    .foregroundColor(.ascendTextSecondary)
            }
        }
        .ascendListStyle()
        .navigationTitle("Comida")
    }
}

struct TramitesView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        List(appState.tramites) { guide in
            NavigationLink(guide.title) {
                TramiteDetailView(guide: guide)
            }
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
                Button {
                    appState.toggleStep(index, in: current)
                } label: {
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

    var body: some View {
        List {
            Section {
                Text("Aquí solo se conecta a estudiantes. ASCEND no procesa pagos.")
                    .font(.footnote)
                    .foregroundColor(.ascendTextSecondary)
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
                    Button("Reportar", role: .destructive) {}
                }
            }
        }
        .ascendListStyle()
        .navigationTitle("Reventa")
    }
}
