import SwiftUI

/// Selector de días de la semana. Se usa en clases, gym, deporte y actividades personalizadas.
struct WeekdayPicker: View {
    @Binding var selection: [Weekday]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(Weekday.allCases) { day in
                Button {
                    if let index = selection.firstIndex(of: day) {
                        selection.remove(at: index)
                    } else {
                        selection.append(day)
                    }
                } label: {
                    Text(day.short)
                        .font(.caption.bold())
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(selection.contains(day) ? Color.ascendGold : Color.ascendCard)
                        .foregroundColor(selection.contains(day) ? .white : .ascendTextSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.ascendGray.opacity(0.25)))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(day.full)
                .accessibilityAddTraits(selection.contains(day) ? .isSelected : [])
            }
        }
    }
}

/// Selector de hora exacta que trabaja con TimeOfDay pero usa el picker nativo de iOS.
struct TimeOfDayPicker: View {
    let title: String
    @Binding var time: TimeOfDay

    var body: some View {
        DatePicker(
            title,
            selection: Binding(
                get: { time.date() ?? Date() },
                set: { time = TimeOfDay.from($0) }
            ),
            displayedComponents: .hourAndMinute
        )
    }
}

/// Fila seleccionable con el look de ASCEND (tarjeta crema cuando está activa).
struct AscendOptionRow: View {
    let label: String
    var detail: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(label).foregroundColor(.ascendTextPrimary)
                    if let detail {
                        Text(detail).font(.caption).foregroundColor(.ascendTextSecondary)
                    }
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(.ascendGold)
                }
            }
            .padding()
            .frame(minHeight: 44)
            .background(isSelected ? Color.ascendSurface : Color.ascendCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.ascendGray.opacity(0.2)))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// Editor de clase reutilizado por el onboarding y por Ajustes (punto 47: nada queda bloqueado).
struct ClassEditorSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var draft: SchoolClass
    private let onSave: (SchoolClass) -> Void
    private let isNew: Bool

    init(editing existing: SchoolClass? = nil, onSave: @escaping (SchoolClass) -> Void) {
        _draft = State(initialValue: existing ?? SchoolClass(
            subject: "", days: [], start: TimeOfDay(8), end: TimeOfDay(9)))
        self.onSave = onSave
        self.isNew = existing == nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Materia") {
                    TextField("Ej. Matemáticas", text: $draft.subject)
                }
                Section("Días") {
                    WeekdayPicker(selection: $draft.days)
                        .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                }
                Section("Horario") {
                    TimeOfDayPicker(title: "Inicia", time: $draft.start)
                    TimeOfDayPicker(title: "Termina", time: $draft.end)
                }
                Section("Opcional") {
                    TextField("Profesor", text: $draft.professor)
                    TextField("Salón", text: $draft.room)
                }
                Section("Recordatorio") {
                    ReminderPicker(reminder: $draft.reminder)
                }
            }
            .ascendListStyle()
            .navigationTitle(isNew ? "Nueva clase" : "Editar clase")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        if draft.end <= draft.start { draft.end = draft.start.adding(minutes: 60) }
                        onSave(draft)
                        dismiss()
                    }
                    .disabled(draft.subject.trimmingCharacters(in: .whitespaces).isEmpty || draft.days.isEmpty)
                }
            }
        }
    }
}

struct ReminderPicker: View {
    @Binding var reminder: ReminderOffset

    var body: some View {
        Picker("Recordatorio", selection: $reminder) {
            ForEach(ReminderOffset.allCases) { option in
                Text(option.label).tag(option)
            }
        }
    }
}

/// Tarjeta resumen de una clase ya creada.
struct ClassRow: View {
    let item: SchoolClass

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(item.subject).font(.subheadline.bold()).foregroundColor(.ascendTextPrimary)
            Text("\(item.daysLabel) · \(item.timeLabel)")
                .font(.caption)
                .foregroundColor(.ascendTextSecondary)
            if !item.room.isEmpty || !item.professor.isEmpty {
                Text([item.room, item.professor].filter { !$0.isEmpty }.joined(separator: " · "))
                    .font(.caption2)
                    .foregroundColor(.ascendTextSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
