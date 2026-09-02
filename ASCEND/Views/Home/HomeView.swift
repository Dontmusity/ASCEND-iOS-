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

    private var pages: [CarouselPage] {
        var result: [CarouselPage] = CalendarLane.allCases.map { .builtin($0) }
        result += appState.customLanes.map { .custom($0.id) }
        if appState.canAddCustomLane {
            result.append(.addNew)
        }
        return result
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                header
                    .padding(.top, 12)

                TabView(selection: $selectedPage) {
                    ForEach(pages, id: \.self) { page in
                        pageView(page).tag(page)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                .frame(maxHeight: .infinity)

                if !appState.reminders.isEmpty {
                    remindersSection
                }
            }
            .readableWidth()
            .background(Color.ascendBackground.ignoresSafeArea())
            .navigationBarHidden(true)
            .sheet(isPresented: $showNewEvent) {
                NewEventSheet()
            }
            .sheet(isPresented: $showNewLane) {
                NewLaneSheet()
            }
        }
    }

    @ViewBuilder
    private func pageView(_ page: CarouselPage) -> some View {
        switch page {
        case .builtin(let lane):
            DayTimelineView(title: lane.rawValue, icon: lane.icon, accentColor: lane.accentColor, events: eventsForBuiltin(lane), onAddEvent: { showNewEvent = true })
        case .custom(let id):
            if let lane = appState.customLanes.first(where: { $0.id == id }) {
                DayTimelineView(title: lane.name, icon: lane.icon, accentColor: lane.accentColor, events: appState.events(inCustomLane: lane), onAddEvent: { showNewEvent = true })
            }
        case .addNew:
            AddLaneCard { showNewLane = true }
        }
    }

    private func eventsForBuiltin(_ lane: CalendarLane) -> [CalendarEvent] {
        if lane == .all { return appState.events }
        return appState.events.filter { $0.lane == lane && $0.customLaneID == nil }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(appState.greeting)
                    .font(.title2.bold())
                    .foregroundColor(.ascendTextPrimary)
                Text(appState.aiDaySummary)
                    .font(.subheadline)
                    .foregroundColor(.ascendTextSecondary)
            }
            Spacer()
            StreakBadge()
            Button {
                showNewEvent = true
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(.ascendGold)
            }
            .frame(minWidth: 44, minHeight: 44)
            .accessibilityLabel("Agregar evento")
        }
        .padding(.horizontal, 20)
    }

    private var remindersSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recordatorios").font(.headline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(appState.reminders) { reminder in
                        HStack(spacing: 8) {
                            Image(systemName: reminder.icon)
                            Text(reminder.title)
                        }
                        .font(.subheadline)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.ascendCream)
                        .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.bottom, 24)
    }
}

private struct AddLaneCard: View {
    let action: () -> Void
    var body: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "plus.circle")
                .font(.system(size: 40))
                .foregroundColor(.ascendGold)
            Text("Crea tu propio carrusel")
                .font(.headline)
            Text("Hasta 3 carruseles personalizados para lo que tú quieras seguir.")
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
