import SwiftUI

struct ExpensesGateView: View {
    @EnvironmentObject private var appState: AppState
    @State private var pinInput = ""
    @State private var pinError = false

    var body: some View {
        Group {
            if appState.expensesPINEnabled && !appState.expensesPIN.isEmpty && !appState.expensesUnlockedThisSession {
                pinPrompt
            } else {
                ExpensesView()
            }
        }
    }

    private var pinPrompt: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.fill").font(.system(size: 34)).foregroundColor(.ascendGold)
            Text("Sección privada").font(.headline).foregroundColor(.ascendTextPrimary)
            SecureField("PIN de 4 dígitos", text: $pinInput)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.numberPad)
                .frame(width: 160)
                .multilineTextAlignment(.center)
            if pinError {
                Text("PIN incorrecto").font(.caption).foregroundColor(.ascendTextSecondary)
            }
            Button("Desbloquear") {
                pinError = !appState.unlockExpenses(withPIN: pinInput)
            }
            .buttonStyle(.borderedProminent)
            .tint(.ascendGold)
            .frame(minHeight: 44)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.ascendBackground.ignoresSafeArea())
        .navigationTitle("Dinero")
    }
}

struct ExpensesView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showNewExpense = false
    @State private var editingExpense: Expense? = nil
    @State private var showBudgetEditor = false
    @State private var showDeleteAllConfirm = false

    var body: some View {
        List {
            Section {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("PRIVADO").font(.caption2.bold()).foregroundColor(.ascendTextSecondary)
                        Text(amountText(appState.totalSpentMXN))
                            .font(.title2.bold())
                            .foregroundColor(.ascendTextPrimary)
                        if appState.budget.isConfigured {
                            Text("de \(amountText(appState.monthlyBudgetMXN)) · quedan \(amountText(appState.remainingBudgetMXN))")
                                .font(.caption)
                                .foregroundColor(.ascendTextSecondary)
                        } else {
                            Text("Aún no defines presupuesto")
                                .font(.caption)
                                .foregroundColor(.ascendTextSecondary)
                        }
                    }
                    Spacer()
                    Button { appState.expensesHidden.toggle() } label: {
                        Image(systemName: appState.expensesHidden ? "eye.slash" : "eye")
                    }
                    .frame(minWidth: 44, minHeight: 44)
                    .accessibilityLabel(appState.expensesHidden ? "Mostrar montos" : "Ocultar montos")
                }

                if appState.budget.isConfigured {
                    ProgressView(value: appState.budgetUsedRatio).tint(.ascendGold)
                }

                Button(appState.budget.isConfigured ? "Editar presupuesto" : "Definir presupuesto") {
                    showBudgetEditor = true
                }
            }

            if !appState.expenses.isEmpty {
                Section("Resumen amable de la semana") {
                    Text("Gastos hormiga: \(amountText(appState.antExpensesTotalMXN)). Nada de qué preocuparse, solo para que lo veas.")
                        .font(.footnote)
                        .foregroundColor(.ascendTextSecondary)
                }
            }

            Section("Movimientos") {
                if appState.expenses.isEmpty {
                    Text("Sin gastos registrados todavía.")
                        .font(.footnote).foregroundColor(.ascendTextSecondary)
                }
                ForEach(appState.expenses.sorted { $0.date > $1.date }) { expense in
                    Button { editingExpense = expense } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(expense.title).foregroundColor(.ascendTextPrimary)
                                Text("\(expense.category.rawValue) · \(expense.date.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.caption).foregroundColor(.ascendTextSecondary)
                            }
                            Spacer()
                            Text(amountText(expense.amountMXN)).foregroundColor(.ascendTextPrimary)
                        }
                    }
                    .swipeActions {
                        Button("Eliminar", role: .destructive) { appState.deleteExpense(expense) }
                    }
                }
            }

            Section("Privacidad") {
                Text("Tus gastos nunca se comparten con terceros ni se usan para anuncios.")
                    .font(.footnote)
                    .foregroundColor(.ascendTextSecondary)
                ShareLink(item: appState.exportExpensesCSV(), preview: SharePreview("gastos.csv")) {
                    Label("Exportar CSV", systemImage: "square.and.arrow.up")
                }
                Button("Borrar todos los gastos", role: .destructive) { showDeleteAllConfirm = true }
            }
        }
        .ascendListStyle()
        .navigationTitle("Dinero")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showNewExpense = true } label: { Image(systemName: "plus") }
                    .accessibilityLabel("Agregar gasto")
            }
        }
        .sheet(isPresented: $showNewExpense) {
            ExpenseEditorSheet { appState.addExpense($0) }
        }
        .sheet(item: $editingExpense) { expense in
            ExpenseEditorSheet(editing: expense,
                               onSave: { appState.updateExpense($0) },
                               onDelete: { appState.deleteExpense(expense) })
        }
        .sheet(isPresented: $showBudgetEditor) {
            BudgetEditorSheet()
        }
        .confirmationDialog("¿Borrar todos los gastos?", isPresented: $showDeleteAllConfirm, titleVisibility: .visible) {
            Button("Borrar todo", role: .destructive) { appState.deleteAllExpenses() }
            Button("Cancelar", role: .cancel) {}
        }
    }

    private func amountText(_ value: Double) -> String {
        appState.expensesHidden ? "•••" : "$\(Int(value)) MXN"
    }
}

/// Punto 34-35: el presupuesto lo decide el usuario y todo lo demás se recalcula solo.
struct BudgetEditorSheet: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var monthly = ""
    @State private var weekly = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Presupuesto mensual") {
                    HStack {
                        Text("$")
                        TextField("0", text: $monthly).keyboardType(.decimalPad)
                        Text("MXN").foregroundColor(.ascendTextSecondary)
                    }
                }
                Section("Semanal (opcional)") {
                    HStack {
                        Text("$")
                        TextField("0", text: $weekly).keyboardType(.decimalPad)
                        Text("MXN").foregroundColor(.ascendTextSecondary)
                    }
                }
                Section {
                    Button("Reiniciar presupuesto", role: .destructive) {
                        appState.resetBudget()
                        monthly = ""; weekly = ""
                    }
                } footer: {
                    Text("Al cambiarlo se actualizan de inmediato el restante, el porcentaje y el resumen.")
                }
            }
            .ascendListStyle()
            .navigationTitle("Presupuesto")
            .onAppear {
                if appState.budget.monthlyAmount > 0 { monthly = String(Int(appState.budget.monthlyAmount)) }
                if let w = appState.budget.weeklyAmount, w > 0 { weekly = String(Int(w)) }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        appState.setMonthlyBudget(Double(monthly) ?? 0)
                        appState.setWeeklyBudget(Double(weekly))
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ExpenseEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft: Expense
    @State private var amountText: String
    private let onSave: (Expense) -> Void
    private let onDelete: (() -> Void)?

    init(editing existing: Expense? = nil, onSave: @escaping (Expense) -> Void, onDelete: (() -> Void)? = nil) {
        let expense = existing ?? Expense(title: "", amountMXN: 0, category: .food, date: Date())
        _draft = State(initialValue: expense)
        _amountText = State(initialValue: expense.amountMXN > 0 ? String(Int(expense.amountMXN)) : "")
        self.onSave = onSave
        self.onDelete = onDelete
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Título", text: $draft.title)
                HStack {
                    Text("$")
                    TextField("Monto", text: $amountText).keyboardType(.decimalPad)
                    Text("MXN").foregroundColor(.ascendTextSecondary)
                }
                Picker("Categoría", selection: $draft.category) {
                    ForEach(ExpenseCategory.allCases) { Text($0.rawValue).tag($0) }
                }
                DatePicker("Fecha", selection: $draft.date, displayedComponents: .date)

                if let onDelete {
                    Button("Eliminar gasto", role: .destructive) { onDelete(); dismiss() }
                }
            }
            .ascendListStyle()
            .navigationTitle(draft.title.isEmpty ? "Nuevo gasto" : "Editar gasto")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        draft.amountMXN = Double(amountText) ?? 0
                        onSave(draft)
                        dismiss()
                    }
                    .disabled(draft.title.isEmpty || Double(amountText) == nil)
                }
            }
        }
    }
}
