import SwiftUI

/// Día de entrenamiento: nombre, días y horario. Los ejercicios se arman en el tracker de Gym.
struct WorkoutScheduleSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft: Workout
    private let onSave: (Workout) -> Void

    init(editing existing: Workout? = nil, onSave: @escaping (Workout) -> Void) {
        _draft = State(initialValue: existing ?? Workout(
            name: "", days: [], start: TimeOfDay(18), end: TimeOfDay(19, 30)))
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Entrenamiento") {
                    TextField("Ej. Pecho + Espalda", text: $draft.name)
                }
                Section("Días") {
                    WeekdayPicker(selection: $draft.days)
                        .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                }
                Section("Horario") {
                    TimeOfDayPicker(title: "Inicia", time: Binding(
                        get: { draft.start ?? TimeOfDay(18) }, set: { draft.start = $0 }))
                    TimeOfDayPicker(title: "Termina", time: Binding(
                        get: { draft.end ?? TimeOfDay(19, 30) }, set: { draft.end = $0 }))
                }
                Section("Recordatorio") {
                    ReminderPicker(reminder: $draft.reminder)
                }
            }
            .ascendListStyle()
            .navigationTitle("Entrenamiento")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") { onSave(draft); dismiss() }
                        .disabled(draft.name.trimmingCharacters(in: .whitespaces).isEmpty || draft.days.isEmpty)
                }
            }
        }
    }
}

struct SportEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft: Sport
    private let onSave: (Sport) -> Void

    init(editing existing: Sport? = nil, onSave: @escaping (Sport) -> Void) {
        _draft = State(initialValue: existing ?? Sport(
            name: "", days: [], start: TimeOfDay(18), end: TimeOfDay(20)))
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Deporte") {
                    TextField("Ej. Fútbol", text: $draft.name)
                }
                Section("Días") {
                    WeekdayPicker(selection: $draft.days)
                        .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                }
                Section("Horario") {
                    TimeOfDayPicker(title: "Inicia", time: $draft.start)
                    TimeOfDayPicker(title: "Termina", time: $draft.end)
                }
                Section("Recordatorio") {
                    ReminderPicker(reminder: $draft.reminder)
                }
            }
            .ascendListStyle()
            .navigationTitle("Deporte")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") { onSave(draft); dismiss() }
                        .disabled(draft.name.trimmingCharacters(in: .whitespaces).isEmpty || draft.days.isEmpty)
                }
            }
        }
    }
}

struct CustomActivityEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft: CustomActivity
    private let lanes: [CustomLane]
    private let onSave: (CustomActivity) -> Void

    private let suggestedCategories = ["Tiempo libre", "Trabajo", "Hobby", "Lectura", "Familia", "Proyecto personal"]
    private let iconOptions = ["star", "briefcase", "book", "gamecontroller", "camera", "music.note", "heart", "person.2"]
    private let colorOptions = ["9E8AA8", "8FA173", "A8785A", "E8BC75", "6B8AA8"]

    init(editing existing: CustomActivity? = nil, lanes: [CustomLane], onSave: @escaping (CustomActivity) -> Void) {
        _draft = State(initialValue: existing ?? CustomActivity(
            name: "", category: "Tiempo libre", days: [], start: TimeOfDay(17), end: TimeOfDay(18)))
        self.lanes = lanes
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Actividad") {
                    TextField("Nombre", text: $draft.name)
                }
                Section("Categoría") {
                    Picker("Categoría", selection: $draft.category) {
                        ForEach(suggestedCategories, id: \.self) { Text($0).tag($0) }
                        if !suggestedCategories.contains(draft.category) {
                            Text(draft.category).tag(draft.category)
                        }
                    }
                    TextField("O escribe una nueva", text: $draft.category)
                }
                Section("Días") {
                    WeekdayPicker(selection: $draft.days)
                        .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                }
                Section("Horario") {
                    TimeOfDayPicker(title: "Inicia", time: $draft.start)
                    TimeOfDayPicker(title: "Termina", time: $draft.end)
                }
                Section("Apariencia") {
                    Picker("Ícono", selection: $draft.icon) {
                        ForEach(iconOptions, id: \.self) { Image(systemName: $0).tag($0) }
                    }
                    .pickerStyle(.segmented)

                    HStack(spacing: 14) {
                        ForEach(colorOptions, id: \.self) { hex in
                            Button { draft.colorHex = hex } label: {
                                Circle().fill(Color(hex: hex))
                                    .frame(width: 30, height: 30)
                                    .overlay(Circle().stroke(Color.ascendTextPrimary, lineWidth: draft.colorHex == hex ? 2 : 0))
                            }
                            .buttonStyle(.plain)
                            .frame(minWidth: 44, minHeight: 44)
                            .accessibilityLabel("Color \(hex)")
                        }
                    }
                }
                if !lanes.isEmpty {
                    Section("Carrusel") {
                        Picker("Mostrar en", selection: $draft.laneID) {
                            Text("Vista general").tag(UUID?.none)
                            ForEach(lanes) { lane in
                                Text(lane.name).tag(UUID?.some(lane.id))
                            }
                        }
                    }
                }
                Section("Recordatorio") {
                    ReminderPicker(reminder: $draft.reminder)
                }
            }
            .ascendListStyle()
            .navigationTitle("Actividad")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") { onSave(draft); dismiss() }
                        .disabled(draft.name.trimmingCharacters(in: .whitespaces).isEmpty || draft.days.isEmpty)
                }
            }
        }
    }
}

struct FreeTimeEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft = FreeTimeBlock(days: [], start: TimeOfDay(16), end: TimeOfDay(18))
    private let onSave: (FreeTimeBlock) -> Void

    init(onSave: @escaping (FreeTimeBlock) -> Void) { self.onSave = onSave }

    var body: some View {
        NavigationStack {
            Form {
                Section("Días") {
                    WeekdayPicker(selection: $draft.days)
                        .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                }
                Section("Horario libre") {
                    TimeOfDayPicker(title: "Desde", time: $draft.start)
                    TimeOfDayPicker(title: "Hasta", time: $draft.end)
                }
            }
            .ascendListStyle()
            .navigationTitle("Tiempo libre")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") { onSave(draft); dismiss() }
                        .disabled(draft.days.isEmpty)
                }
            }
        }
    }
}
