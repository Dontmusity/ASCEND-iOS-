import SwiftUI

enum CarouselPage: Hashable {
    case builtin(CalendarLane)
    case custom(UUID)
    case addNew
}

struct HomeView: View {
    @EnvironmentObject private var appState: AppState
    @State private var selectedPage: CarouselPage = .builtin(.all)
    @State private var showNewEvent = false
    @State private var showNewLane = false

    /// Los carruseles se adaptan: si no estudias, no aparece Escuela; si no entrenas, no aparece Gym.
    private var pages: [CarouselPage] {
        var lanes: [CalendarLane] = [.all]
        if appState.education.studies || !appState.classes.isEmpty { lanes.append(.school) }
        if appState.activityKind != .none || !appState.workouts.isEmpty || !appState.sports.isEmpty { lanes.append(.gym) }
        if !appState.meals.isEmpty { lanes.append(.food) }
        if appState.customActivities.contains(where: { $0.laneID == nil }) { lanes.append(.hobbies) }

        var result = lanes.map { CarouselPage.builtin($0) }
        result += appState.customLanes.map { .custom($0.id) }
        if appState.canAddCustomLane { result.append(.addNew) }
        return result
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                header
                nowCard
                carousel
            }
            .readableWidth()
            .background(Color.ascendBackground.ignoresSafeArea())
            .navigationBarHidden(true)
            .sheet(isPresented: $showNewEvent) { NewEventSheet() }
            .sheet(isPresented: $showNewLane) { NewLaneSheet() }
        }
    }

    // MARK: Encabezado

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(appState.greeting)
                    .font(.title3.bold())
                    .foregroundColor(.ascendTextPrimary)
                Text(appState.aiDaySummary)
                    .font(.footnote)
                    .foregroundColor(.ascendTextSecondary)
                    .lineLimit(2)
            }
            Spacer()
            StreakBadge()
            Button { showNewEvent = true } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(.ascendGold)
            }
            .frame(minWidth: 44, minHeight: 44)
            .accessibilityLabel("Agregar evento")
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    // MARK: Ahora / siguiente (punto 43)

    @ViewBuilder
    private var nowCard: some View {
        if let current = appState.currentEntry {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(current.color)
                    .frame(width: 4, height: 38)
                VStack(alignment: .leading, spacing: 2) {
                    Text("AHORA").font(.caption2.bold()).foregroundColor(.ascendTextSecondary)
                    Text(current.title).font(.subheadline.bold()).foregroundColor(.ascendTextPrimary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(appState.minutesRemaining(of: current)) min")
                        .font(.subheadline.bold())
                        .foregroundColor(.ascendTextPrimary)
                    Text("restantes").font(.caption2).foregroundColor(.ascendTextSecondary)
                }
            }
            .padding(12)
            .background(Color.ascendSurface)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, 20)
            .accessibilityElement(children: .combine)
        } else if let next = appState.nextEntry {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(next.color.opacity(0.6))
                    .frame(width: 4, height: 38)
                VStack(alignment: .leading, spacing: 2) {
                    Text("SIGUIENTE").font(.caption2.bold()).foregroundColor(.ascendTextSecondary)
                    Text(next.title).font(.subheadline.bold()).foregroundColor(.ascendTextPrimary)
                }
                Spacer()
                Text(next.start.label)
                    .font(.subheadline.bold())
                    .foregroundColor(.ascendTextPrimary)
            }
            .padding(12)
            .background(Color.ascendCard)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.ascendGray.opacity(0.2)))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, 20)
            .accessibilityElement(children: .combine)
        }
    }

    // MARK: Carrusel

    private var carousel: some View {
        TabView(selection: $selectedPage) {
            ForEach(pages, id: \.self) { page in
                pageView(page).tag(page)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .frame(maxHeight: .infinity)
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
        case .addNew:
            AddLaneCard { showNewLane = true }
        }
    }
}

/// Vista resumen: el día completo mezclando todo, compacto.
struct GeneralLaneView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            LaneHeader(title: "Todo", icon: "square.stack.3d.up", color: .ascendGold)
            DayTimelineView(entries: appState.entries(for: .today, lane: .all)) { entry in
                appState.delete(entry: entry)
            }
        }
    }
}

struct PersonalLaneView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            LaneHeader(title: "Personal", icon: "paintpalette", color: Color(hex: "9E8AA8"))
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
            Image(systemName: icon).foregroundColor(color).accessibilityHidden(true)
            Text(title).font(.headline).foregroundColor(.ascendTextPrimary)
            Spacer()
            trailing()
        }
        .padding(.horizontal, 20)
    }
}

struct AddLaneCard: View {
    let action: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "plus.circle")
                .font(.system(size: 38))
                .foregroundColor(.ascendGold)
            Text("Crea tu propio carrusel").font(.headline).foregroundColor(.ascendTextPrimary)
            Text("Hasta 3 áreas propias para lo que tú quieras seguir.")
                .font(.footnote)
                .foregroundColor(.ascendTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Button("Crear carrusel", action: action)
                .buttonStyle(.borderedProminent)
                .tint(.ascendGold)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
