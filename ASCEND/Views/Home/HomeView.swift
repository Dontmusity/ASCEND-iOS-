import SwiftUI
import Combine

enum CarouselPage: Hashable {
    case builtin(CalendarLane)
    case custom(UUID)
}

enum HomePeriod: String, CaseIterable, Hashable {
    case day = "Día", week = "Semana", month = "Mes"
}

struct HomeView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selectedPage: CarouselPage = .builtin(.all)
    @State private var period: HomePeriod = .day
    @State private var showExtraLanes = false
    @State private var showNewEvent = false
    @State private var showNewLane = false
    @Namespace private var chipNamespace
    private let completionTicker = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    /// Los carriles se adaptan: si no estudias, no aparece Escuela; si no entrenas, no aparece Gym.
    private var builtinPages: [CarouselPage] {
        var lanes: [CalendarLane] = [.all]
        if appState.education.studies || !appState.classes.isEmpty { lanes.append(.school) }
        if appState.activityKind != .none || !appState.workouts.isEmpty || !appState.sports.isEmpty { lanes.append(.gym) }
        if !appState.meals.isEmpty { lanes.append(.food) }
        if appState.customActivities.contains(where: { $0.laneID == nil }) { lanes.append(.hobbies) }
        return lanes.map { CarouselPage.builtin($0) }
    }

    private var customPages: [CarouselPage] { appState.customLanes.map { .custom($0.id) } }
    private var pages: [CarouselPage] { builtinPages + customPages }

    /// Si el carril elegido desaparece (se borró), vuelve a Todo.
    private var activePage: CarouselPage { pages.contains(selectedPage) ? selectedPage : .builtin(.all) }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                header
                controls
                chips
                nowCard
                content
                    .padding(.top, 14)
                    .frame(maxHeight: .infinity)
                    // Atajo del carrusel anterior: deslizar a los lados cambia de carril.
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 30).onEnded { value in
                            let dx = value.translation.width
                            guard abs(dx) > 60, abs(dx) > abs(value.translation.height) * 1.5 else { return }
                            movePage(by: dx < 0 ? 1 : -1)
                        }
                    )
            }
            .readableWidth()
            .background(Color.ascendBackground.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showNewEvent) { NewEventSheet() }
            .sheet(isPresented: $showNewLane) { NewLaneSheet() }
            .onAppear { appState.checkEndedEntries() }
            .onReceive(completionTicker) { _ in appState.checkEndedEntries() }
            .alert(
                "¿Completaste \"\(appState.pendingCompletionEntry?.title ?? "")\"?",
                isPresented: Binding(
                    get: { appState.pendingCompletionEntry != nil },
                    set: { if !$0 { appState.pendingCompletionEntryID = nil } }
                )
            ) {
                Button("Sí") { answerPendingCompletion(true) }
                Button("No") { answerPendingCompletion(false) }
                Button("Preguntar después", role: .cancel) { appState.pendingCompletionEntryID = nil }
            }
        }
    }

    private func answerPendingCompletion(_ done: Bool) {
        guard let id = appState.pendingCompletionEntryID else { return }
        appState.setCompletion(id, done: done)
        appState.pendingCompletionEntryID = nil
    }

    private func movePage(by step: Int) {
        guard let index = pages.firstIndex(of: activePage) else { return }
        let target = min(max(index + step, 0), pages.count - 1)
        guard target != index else { return }
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) {
            selectedPage = pages[target]
            if case .custom = pages[target] { showExtraLanes = true }
        }
    }

    // MARK: Encabezado

    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 9) {
                AscendMark(strokeColor: .ascendGray, innerColor: .ascendGold)
                    .frame(width: 20, height: 20)
                AscendKicker(text: AscendDateText.kicker(Date()))
                Spacer()
                StreakBadge()
            }
            .padding(.top, 6)

            Text(appState.greeting.replacingOccurrences(of: ", ", with: ",\n"))
                .font(.ascendTitleXL)
                .foregroundColor(.ascendTextPrimary)
                .padding(.top, 10)
            Text(appState.aiDaySummary)
                .font(.subheadline)
                .foregroundColor(.ascendTextSecondary)
                .lineLimit(2)
                .padding(.top, 9)
        }
        .padding(.horizontal, 20)
    }

    // MARK: Día / Semana / Mes + calendario

    private var controls: some View {
        HStack(spacing: 10) {
            AscendSegmented(options: HomePeriod.allCases, selection: $period) { $0.rawValue }
            Spacer()
            // El "+" de agregar evento vive aquí ahora: calendario con plus, a un toque.
            Button { showNewEvent = true } label: {
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.ascendTextSecondary)
                    .frame(width: 32, height: 32)
                    .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.ascendHairline, lineWidth: 1))
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(AscendPressStyle())
            .accessibilityLabel("Agregar evento")
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    // MARK: Chips de carriles

    private var chips: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(builtinPages, id: \.self) { page in
                        chip(for: page)
                    }
                    AscendChip(icon: "plus", title: showExtraLanes ? "Ocultar carriles" : "Más carriles",
                               color: .ascendGray, showsTitle: false, dashed: true) {
                        if appState.customLanes.isEmpty {
                            showNewLane = true
                        } else {
                            showExtraLanes.toggle()
                        }
                    }
                }
                .padding(.horizontal, 20)
            }

            if showExtraLanes && !appState.customLanes.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(customPages, id: \.self) { page in
                            chip(for: page)
                        }
                        if appState.canAddCustomLane {
                            AscendChip(icon: "plus", title: "Nuevo carril", color: .ascendGray, dashed: true) {
                                showNewLane = true
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.top, 2)
    }

    private func chip(for page: CarouselPage) -> some View {
        let info = chipInfo(page)
        return AscendChip(icon: info.icon, title: info.title, color: info.color,
                          isActive: activePage == page, namespace: chipNamespace) {
            selectedPage = page
        }
    }

    private func chipInfo(_ page: CarouselPage) -> (icon: String, title: String, color: Color) {
        switch page {
        case .builtin(let lane):
            return (lane.icon, lane.rawValue, lane.accentColor)
        case .custom(let id):
            let lane = appState.customLanes.first { $0.id == id }
            return (lane?.icon ?? "star", lane?.name ?? "Carril", lane?.accentColor ?? .ascendGold)
        }
    }

    // MARK: Ahora / siguiente

    @ViewBuilder
    private var nowCard: some View {
        // Se redibuja cada 30 s para que los minutos restantes y la barra avancen solos.
        TimelineView(.periodic(from: .now, by: 30)) { _ in
            if let current = appState.currentEntry {
                currentCard(current)
            } else if let next = appState.nextEntry {
                nextCard(next)
            }
        }
    }

    private func currentCard(_ current: ScheduleEntry) -> some View {
        let total = max(current.end.totalMinutes - current.start.totalMinutes, 1)
        let remaining = appState.minutesRemaining(of: current)
        return HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 0) {
                AscendKicker(text: "Ahora", color: .ascendOnSurfaceTertiary)
                Text(current.title)
                    .font(.ascendTitleM)
                    .foregroundColor(.ascendOnSurface)
                    .padding(.top, 8)
                if let subtitle = current.subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundColor(.ascendOnSurfaceSecondary)
                        .padding(.top, 3)
                }
            }
            Spacer(minLength: 0)
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(remaining)")
                    .font(.ascendNumber(34))
                    .monospacedDigit()
                    .foregroundColor(.ascendOnSurface)
                    .contentTransition(.numericText())
                Text("min restantes")
                    .font(.caption2.weight(.medium))
                    .foregroundColor(.ascendOnSurfaceSecondary)
            }
        }
        .padding(EdgeInsets(top: 15, leading: 18, bottom: 20, trailing: 18))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.ascendSurface)
        .overlay(alignment: .bottom) {
            AscendProgressBar(progress: Double(total - remaining) / Double(total),
                              track: Color.ascendOnSurface.opacity(0.08), height: 5, rounded: false)
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .accessibilityElement(children: .combine)
    }

    private func nextCard(_ next: ScheduleEntry) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                AscendKicker(text: "Siguiente")
                Text(next.title).font(.body.weight(.semibold)).foregroundColor(.ascendTextPrimary)
            }
            Spacer()
            Text(next.start.label)
                .font(.ascendNumber(18))
                .monospacedDigit()
                .foregroundColor(.ascendTextPrimary)
        }
        .padding(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
        .areaTint(next.color, fill: 0.10)
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .accessibilityElement(children: .combine)
    }

    // MARK: Contenido

    @ViewBuilder
    private var content: some View {
        switch period {
        case .day:
            pageView(activePage)
        case .week:
            AgendaListView(days: 7) { entries(for: activePage, on: $0) }
        case .month:
            AgendaListView(days: Self.daysLeftInMonth()) { entries(for: activePage, on: $0) }
        }
    }

    private func entries(for page: CarouselPage, on weekday: Weekday) -> [ScheduleEntry] {
        switch page {
        case .builtin(let lane):
            return appState.entries(for: weekday, lane: lane)
        case .custom(let id):
            guard let lane = appState.customLanes.first(where: { $0.id == id }) else { return [] }
            return appState.entries(inCustomLane: lane, weekday: weekday)
        }
    }

    private static func daysLeftInMonth(from date: Date = Date()) -> Int {
        let calendar = Calendar.current
        let total = calendar.range(of: .day, in: .month, for: date)?.count ?? 30
        return total - calendar.component(.day, from: date) + 1
    }

    @ViewBuilder
    private func pageView(_ page: CarouselPage) -> some View {
        switch page {
        case .builtin(let lane):
            switch lane {
            case .all: GeneralLaneView()
            case .school: SchoolLaneView()
            case .gym: GymLaneView()
            case .food: FoodLaneView()
            case .hobbies: PersonalLaneView()
            }
        case .custom(let id):
            if let lane = appState.customLanes.first(where: { $0.id == id }) {
                CustomLaneView(lane: lane)
            }
        }
    }
}

/// Semana y Mes: los mismos datos del horario, agrupados por día. Solo muestra días con algo.
struct AgendaListView: View {
    let days: Int
    let entriesFor: (Weekday) -> [ScheduleEntry]

    private var agenda: [(date: Date, entries: [ScheduleEntry])] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<days).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: today) else { return nil }
            let list = entriesFor(Weekday.from(date))
            return list.isEmpty ? nil : (date, list)
        }
    }

    var body: some View {
        let agenda = agenda
        ScrollView {
            if agenda.isEmpty {
                AscendEmptyState(title: "Tu día está vacío",
                                 message: "Agrega tus clases, entrenamientos o actividades y aparecerán aquí.")
                    .padding(.top, 40)
            } else {
                LazyVStack(alignment: .leading, spacing: 20) {
                    ForEach(agenda, id: \.date) { day in
                        VStack(alignment: .leading, spacing: 10) {
                            AscendKicker(text: AscendDateText.kicker(day.date))
                            ForEach(day.entries) { entry in
                                HStack(spacing: 12) {
                                    Text(entry.start.label)
                                        .font(.ascendRounded(11, .medium, relativeTo: .caption2))
                                        .foregroundColor(.ascendTextSecondary)
                                        .frame(width: 38, alignment: .leading)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(entry.title)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundColor(.ascendTextPrimary)
                                        Text([entry.timeLabel, entry.subtitle ?? ""].filter { !$0.isEmpty }.joined(separator: " · "))
                                            .font(.caption)
                                            .foregroundColor(.ascendTextSecondary)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 9)
                                    .areaTint(entry.color, fill: 0.14, cornerRadius: 12, bordered: false)
                                }
                                .accessibilityElement(children: .combine)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 90) // deja libre el FAB
            }
        }
    }
}

/// Vista general: el día completo mezclando todos los carriles.
struct GeneralLaneView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        DayTimelineView(entries: appState.entries(for: .today, lane: .all)) { entry in
            appState.delete(entry: entry)
        }
    }
}

struct PersonalLaneView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            LaneHeader(title: "Personal", icon: "paintpalette", color: CalendarLane.hobbies.accentColor)
            DayTimelineView(entries: appState.entries(for: .today, lane: .hobbies)) { entry in
                appState.delete(entry: entry)
            }
        }
    }
}

struct CustomLaneView: View {
    @EnvironmentObject private var appState: AppState
    let lane: CustomLane
    @State private var showEditor = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            LaneHeader(title: lane.name, icon: lane.icon, color: lane.accentColor) {
                Menu {
                    Button("Agregar actividad") { showEditor = true }
                    Button("Eliminar carrusel", role: .destructive) { appState.deleteCustomLane(lane) }
                } label: {
                    Image(systemName: "ellipsis.circle").foregroundColor(.ascendGray)
                }
                .frame(minWidth: 44, minHeight: 44)
                .accessibilityLabel("Opciones de \(lane.name)")
            }
            DayTimelineView(entries: appState.entries(inCustomLane: lane)) { entry in
                appState.delete(entry: entry)
            }
        }
        .sheet(isPresented: $showEditor) {
            CustomActivityEditorSheet(lanes: appState.customLanes) { activity in
                var activity = activity
                activity.laneID = lane.id
                appState.addCustomActivity(activity)
            }
        }
    }
}

struct LaneHeader<Trailing: View>: View {
    let title: String
    let icon: String
    let color: Color
    @ViewBuilder var trailing: () -> Trailing

    init(title: String, icon: String, color: Color, @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() }) {
        self.title = title
        self.icon = icon
        self.color = color
        self.trailing = trailing
    }

    var body: some View {
        HStack(spacing: 8) {
            Circle().fill(color).frame(width: 7, height: 7).accessibilityHidden(true)
            Image(systemName: icon).font(.footnote.weight(.semibold)).foregroundColor(color).accessibilityHidden(true)
            Text(title).font(.ascendRounded(17, relativeTo: .headline)).foregroundColor(.ascendTextPrimary)
            Spacer()
            trailing()
        }
        .padding(.horizontal, 20)
    }
}
