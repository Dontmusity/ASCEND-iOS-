import SwiftUI

struct NewEventSheet: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    private enum LaneChoice: Hashable {
        case builtin(CalendarLane)
        case custom(UUID)
    }

    @State private var title = ""
    @State private var subtitle = ""
    @State private var startHour: Double = 9
    @State private var durationHours: Double = 1
    @State private var laneChoice: LaneChoice = .builtin(.school)

    private var laneOptions: [LaneChoice] {
        CalendarLane.allCases.filter { $0 != .all }.map { .builtin($0) } + appState.customLanes.map { .custom($0.id) }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Evento") {
                    TextField("Título", text: $title)
                    TextField("Detalle (opcional)", text: $subtitle)
                }
                Section("Horario") {
                    Stepper("Inicia: \(formatted(startHour))", value: $startHour, in: 5...23, step: 0.5)
                    Stepper("Duración: \(formatted(durationHours)) h", value: $durationHours, in: 0.5...6, step: 0.5)
                }
                Section("Carrusel") {
                    Picker("Asignar a", selection: $laneChoice) {
                        ForEach(laneOptions, id: \.self) { option in
                            Text(label(for: option)).tag(option)
                        }
                    }
                }
            }
            .navigationTitle("Nuevo evento")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") { save() }.disabled(title.isEmpty)
                }
            }
        }
    }

    private func label(for option: LaneChoice) -> String {
        switch option {
        case .builtin(let lane): return lane.rawValue
        case .custom(let id): return appState.customLanes.first { $0.id == id }?.name ?? "Carrusel"
        }
    }

    private func formatted(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f:00", value) : String(format: "%.0f:30", value.rounded(.down))
    }

    private func save() {
        var lane: CalendarLane = .all
        var customID: UUID? = nil
        switch laneChoice {
        case .builtin(let l): lane = l
        case .custom(let id): customID = id
        }
        appState.addEvent(CalendarEvent(title: title, subtitle: subtitle.isEmpty ? nil : subtitle, startHour: startHour, durationHours: durationHours, lane: lane, customLaneID: customID))
        dismiss()
    }
}
