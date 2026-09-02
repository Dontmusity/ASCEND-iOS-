import SwiftUI

/// Escuela: no es el calendario filtrado, es una experiencia académica completa.
struct SchoolLaneView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showClassEditor = false
    @State private var showAssignmentEditor = false
    @State private var showExamEditor = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            LaneHeader(title: "Escuela", icon: "book.closed", color: Color(hex: "C9A15A")) {
                Menu {
                    Button("Agregar clase") { showClassEditor = true }
                    Button("Agregar tarea") { showAssignmentEditor = true }
                    Button("Agregar examen") { showExamEditor = true }
                } label: {
                    Image(systemName: "plus.circle").foregroundColor(.ascendGold)
                }
                .frame(minWidth: 44, minHeight: 44)
                .accessibilityLabel("Agregar en Escuela")
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    todayClasses
                    studySuggestion
                    assignments
                    exams
                    subjectsSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .sheet(isPresented: $showClassEditor) {
            ClassEditorSheet { appState.addClass($0) }
        }
        .sheet(isPresented: $showAssignmentEditor) {
            AssignmentEditorSheet(subjects: appState.subjects) { appState.addAssignment($0) }
        }
        .sheet(isPresented: $showExamEditor) {
            ExamEditorSheet(subjects: appState.subjects) { appState.addExam($0) }
        }
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.caption.bold())
            .tracking(0.8)
            .foregroundColor(.ascendTextSecondary)
    }

    private var todayClasses: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("Clases de hoy")
            let classes = appState.classes(on: .today)
            if classes.isEmpty {
                EmptyHint(text: "Hoy no tienes clases registradas.")
            } else {
                ForEach(classes) { item in
                    NavigationLink {
                        SubjectDetailView(subject: item.subject)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.subject).font(.subheadline.bold()).foregroundColor(.ascendTextPrimary)
                                Text(item.room.isEmpty ? item.timeLabel : "\(item.timeLabel) · \(item.room)")
                                    .font(.caption).foregroundColor(.ascendTextSecondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").font(.caption).foregroundColor(.ascendGray)
                        }
                        .padding(12)
                        .background(Color.ascendCard)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.ascendGray.opacity(0.15)))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private var studySuggestion: some View {
        if let suggestion = appState.studySuggestion {
            VStack(alignment: .leading, spacing: 8) {
                sectionTitle("Estudiar hoy")
                VStack(alignment: .leading, spacing: 6) {
                    Text(suggestion.reason).font(.subheadline).foregroundColor(.ascendTextPrimary)
                    Text("Sugerencia: repasar \(suggestion.subject) — \(suggestion.minutes) min")
                        .font(.footnote).foregroundColor(.ascendTextSecondary)
                    HStack {
                        Button("Agregar al día") {
                            let start = appState.freeSlots().first?.start ?? TimeOfDay.now
                            appState.addCustomActivity(CustomActivity(
                                name: "Estudiar \(suggestion.subject)", category: "Estudio",
                                icon: "book", colorHex: "C9A15A", days: [.today],
                                start: start, end: start.adding(minutes: suggestion.minutes)))
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.ascendGold)
                        .controlSize(.small)

                        Text("Solo si tú quieres — nunca se agrega solo.")
                            .font(.caption2).foregroundColor(.ascendTextSecondary)
                    }
                }
                .padding(12)
                .background(Color.ascendSurface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var assignments: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("Tareas")
            if appState.pendingAssignments.isEmpty {
                EmptyHint(text: "Sin tareas pendientes.")
            } else {
                ForEach(appState.pendingAssignments) { item in
                    HStack {
                        Button { appState.toggleAssignment(item) } label: {
                            Image(systemName: "circle").foregroundColor(.ascendGray)
                        }
                        .frame(minWidth: 44, minHeight: 44)
                        .accessibilityLabel("Marcar \(item.title) como hecha")

                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title).font(.subheadline).foregroundColor(.ascendTextPrimary)
                            Text("\(item.subject) · \(dueLabel(item.daysRemaining))")
                                .font(.caption).foregroundColor(.ascendTextSecondary)
                        }
                        Spacer()
                        Text(item.priority.rawValue)
                            .font(.caption2)
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(Color.ascendSurface)
                            .clipShape(Capsule())
                    }
                    .padding(.horizontal, 12)
                    .background(Color.ascendCard)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.ascendGray.opacity(0.15)))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    private var exams: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("Próximos exámenes")
            if appState.upcomingExams.isEmpty {
                EmptyHint(text: "Sin exámenes registrados.")
            } else {
                ForEach(appState.upcomingExams) { exam in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(exam.subject).font(.subheadline.bold()).foregroundColor(.ascendTextPrimary)
                            Text(exam.title).font(.caption).foregroundColor(.ascendTextSecondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(exam.date, style: .date).font(.caption).foregroundColor(.ascendTextSecondary)
                            Text(dueLabel(exam.daysRemaining)).font(.caption2.bold()).foregroundColor(.ascendTextPrimary)
                        }
                    }
                    .padding(12)
                    .background(Color.ascendCard)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.ascendGray.opacity(0.15)))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }

    private var subjectsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !appState.subjects.isEmpty {
                sectionTitle("Mis materias")
                ForEach(appState.subjects, id: \.self) { subject in
                    NavigationLink {
                        SubjectDetailView(subject: subject)
                    } label: {
                        HStack {
                            Text(subject).foregroundColor(.ascendTextPrimary)
                            Spacer()
                            Image(systemName: "chevron.right").font(.caption).foregroundColor(.ascendGray)
                        }
                        .padding(12)
                        .background(Color.ascendCard)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.ascendGray.opacity(0.15)))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func dueLabel(_ days: Int) -> String {
        switch days {
        case ..<0: return "Vencida"
        case 0: return "Hoy"
        case 1: return "Mañana"
        default: return "En \(days) días"
        }
    }
}

/// Detalle de una materia (punto 17).
struct SubjectDetailView: View {
    @EnvironmentObject private var appState: AppState
    let subject: String

    var body: some View {
        List {
            Section {
                if let (next, day) = appState.nextClass(for: subject) {
                    LabeledContent("Próxima clase", value: "\(day.short) \(next.start.label)")
                }
                LabeledContent("Tareas", value: "\(appState.assignments(for: subject).count)")
                if let exam = appState.exams(for: subject).first {
                    LabeledContent("Próximo examen", value: exam.date.formatted(date: .abbreviated, time: .omitted))
                }
                LabeledContent("Estudio esta semana", value: studyLabel)
            }

            Section("Tareas") {
                let items = appState.assignments(for: subject)
                if items.isEmpty {
                    Text("Sin tareas pendientes.").foregroundColor(.ascendTextSecondary).font(.footnote)
                } else {
                    ForEach(items) { item in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(item.title)
                                Text(item.dueDate, style: .date).font(.caption).foregroundColor(.ascendTextSecondary)
                            }
                            Spacer()
                            Button("Hecha") { appState.toggleAssignment(item) }
                                .font(.caption)
                        }
                    }
                }
            }

            Section("Exámenes") {
                let items = appState.exams(for: subject)
                if items.isEmpty {
                    Text("Sin exámenes registrados.").foregroundColor(.ascendTextSecondary).font(.footnote)
                } else {
                    ForEach(items) { exam in
                        HStack {
                            Text(exam.title)
                            Spacer()
                            Text(exam.date, style: .date).foregroundColor(.ascendTextSecondary)
                        }
                    }
                }
            }

            Section("Horario") {
                ForEach(appState.classes.filter { $0.subject == subject }) { item in
                    ClassRow(item: item)
                }
            }
        }
        .ascendListStyle()
        .navigationTitle(subject)
    }

    private var studyLabel: String {
        let minutes = appState.studyMinutesThisWeek(for: subject)
        return minutes == 0 ? "—" : "\(minutes / 60)h \(minutes % 60)m"
    }
}

struct EmptyHint: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.footnote)
            .foregroundColor(.ascendTextSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Color.ascendCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct AssignmentEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    let subjects: [String]
    let onSave: (Assignment) -> Void

    @State private var title = ""
    @State private var subject = ""
    @State private var dueDate = Date()
    @State private var priority: TodoPriority = .medium
    @State private var reminder: ReminderOffset = .none

    var body: some View {
        NavigationStack {
            Form {
                TextField("Tarea", text: $title)
                if subjects.isEmpty {
                    TextField("Materia", text: $subject)
                } else {
                    Picker("Materia", selection: $subject) {
                        Text("Selecciona").tag("")
                        ForEach(subjects, id: \.self) { Text($0).tag($0) }
                    }
                }
                DatePicker("Fecha límite", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                Picker("Prioridad", selection: $priority) {
                    ForEach(TodoPriority.allCases) { Text($0.rawValue).tag($0) }
                }
                ReminderPicker(reminder: $reminder)
            }
            .ascendListStyle()
            .navigationTitle("Nueva tarea")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        onSave(Assignment(title: title, subject: subject, dueDate: dueDate,
                                          priority: priority, reminder: reminder))
                        dismiss()
                    }
                    .disabled(title.isEmpty || subject.isEmpty)
                }
            }
        }
    }
}

struct ExamEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    let subjects: [String]
    let onSave: (Exam) -> Void

    @State private var title = ""
    @State private var subject = ""
    @State private var date = Date()
    @State private var reminder: ReminderOffset = .none

    var body: some View {
        NavigationStack {
            Form {
                TextField("Ej. Parcial 2", text: $title)
                if subjects.isEmpty {
                    TextField("Materia", text: $subject)
                } else {
                    Picker("Materia", selection: $subject) {
                        Text("Selecciona").tag("")
                        ForEach(subjects, id: \.self) { Text($0).tag($0) }
                    }
                }
                DatePicker("Fecha", selection: $date, displayedComponents: [.date, .hourAndMinute])
                ReminderPicker(reminder: $reminder)
            }
            .ascendListStyle()
            .navigationTitle("Nuevo examen")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        onSave(Exam(title: title, subject: subject, date: date, reminder: reminder))
                        dismiss()
                    }
                    .disabled(title.isEmpty || subject.isEmpty)
                }
            }
        }
    }
}
