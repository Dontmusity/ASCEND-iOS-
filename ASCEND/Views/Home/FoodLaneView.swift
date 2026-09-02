import SwiftUI

/// Comida: horarios del día y el objetivo configurado. Sin recomendaciones médicas.
struct FoodLaneView: View {
    @EnvironmentObject private var appState: AppState
    @State private var editingMeal: Meal? = nil
    @State private var showNewMeal = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            LaneHeader(title: "Comida", icon: "fork.knife", color: Color(hex: "8FA173")) {
                Button { showNewMeal = true } label: {
                    Image(systemName: "plus.circle").foregroundColor(.ascendGold)
                }
                .frame(minWidth: 44, minHeight: 44)
                .accessibilityLabel("Agregar comida")
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    goalCard

                    VStack(alignment: .leading, spacing: 8) {
                        Text("HOY").font(.caption.bold()).foregroundColor(.ascendTextSecondary)
                        if appState.meals.isEmpty {
                            EmptyHint(text: "Aún no registras horarios de comida.")
                        } else {
                            ForEach(appState.meals) { meal in
                                Button { editingMeal = meal } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(meal.name.uppercased())
                                                .font(.subheadline.bold())
                                                .foregroundColor(.ascendTextPrimary)
                                            if meal.reminder.minutesBefore != nil {
                                                Text(meal.reminder.label)
                                                    .font(.caption2).foregroundColor(.ascendTextSecondary)
                                            }
                                        }
                                        Spacer()
                                        Text(meal.time.label)
                                            .font(.subheadline)
                                            .foregroundColor(.ascendTextSecondary)
                                    }
                                    .padding(14)
                                    .background(Color.ascendCard)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.ascendGray.opacity(0.15)))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    Text("ASCEND no da dietas, ayunos ni metas de peso. Solo te ayuda a no saltarte comidas.")
                        .font(.caption)
                        .foregroundColor(.ascendTextSecondary)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .sheet(isPresented: $showNewMeal) {
            MealEditorSheet { appState.addMeal($0) }
        }
        .sheet(item: $editingMeal) { meal in
            MealEditorSheet(editing: meal,
                            onSave: { appState.updateMeal($0) },
                            onDelete: { appState.deleteMeal(meal) })
        }
    }

    private var goalCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("TU OBJETIVO").font(.caption.bold()).foregroundColor(.ascendTextSecondary)
            Text(appState.physicalGoal.shortLabel)
                .font(.title3.bold())
                .foregroundColor(.ascendTextPrimary)
            Text(appState.physicalGoal == .notSet
                 ? "Puedes definirlo en Perfil cuando quieras."
                 : "Lo guardamos solo para darte contexto, nunca para presionarte.")
                .font(.caption)
                .foregroundColor(.ascendTextSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.ascendSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct MealEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft: Meal
    private let onSave: (Meal) -> Void
    private let onDelete: (() -> Void)?

    init(editing existing: Meal? = nil, onSave: @escaping (Meal) -> Void, onDelete: (() -> Void)? = nil) {
        _draft = State(initialValue: existing ?? Meal(name: "", time: TimeOfDay(13)))
        self.onSave = onSave
        self.onDelete = onDelete
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Comida") {
                    TextField("Ej. Desayuno", text: $draft.name)
                    TimeOfDayPicker(title: "Hora", time: $draft.time)
                }
                Section("Recordatorio") {
                    ReminderPicker(reminder: $draft.reminder)
                }
                if let onDelete {
                    Section {
                        Button("Eliminar", role: .destructive) { onDelete(); dismiss() }
                    }
                }
            }
            .ascendListStyle()
            .navigationTitle(draft.name.isEmpty ? "Nueva comida" : draft.name)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") { onSave(draft); dismiss() }
                        .disabled(draft.name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
