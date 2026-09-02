import SwiftUI

struct ExpensesGateView: View {
    @EnvironmentObject private var appState: AppState
    @State private var pinInput = ""
    @State private var pinError = false

    var body: some View {
        Group {
            if appState.expensesPINEnabled && !appState.expensesUnlockedThisSession {
                pinPrompt
            } else {
                ExpensesView()
            }
        }
    }

    private var pinPrompt: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.fill").font(.system(size: 36)).foregroundColor(.ascendGold)
            Text("Sección privada").font(.headline)
            SecureField("PIN de 4 dígitos", text: $pinInput)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.numberPad)
                .frame(width: 160)
                .multilineTextAlignment(.center)
            if pinError {
                Text("PIN incorrecto").font(.caption).foregroundColor(.red)
            }
            Button("Desbloquear") {
                if !appState.unlockExpenses(withPIN: pinInput) {
                    pinError = true
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.ascendGold)
        }
        .padding()
        .navigationTitle("Dinero")
    }
}

struct ExpensesView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showNewExpense = false
    @State private var showDeleteAllConfirm = false

    var body: some View {
        List {
            Section {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Etiqueta Privado").font(.caption).foregroundColor(.ascendTextSecondary)
                        Text(amountText(appState.totalSpentMXN))
                            .font(.title2.bold())
                        Text("de \(amountText(appState.monthlyBudgetMXN)) presupuestados")
                            .font(.caption)
                            .foregroundColor(.ascendTextSecondary)
                    }
                    Spacer()
                    Button {
                        appState.expensesHidden.toggle()
                    } label: {
                        Image(systemName: appState.expensesHidden ? "eye.slash" : "eye")
                    }
                    .frame(minWidth: 44, minHeight: 44)
                    .accessibilityLabel(appState.expensesHidden ? "Mostrar montos" : "Ocultar montos")
                }

                ProgressView(value: min(appState.totalSpentMXN / appState.monthlyBudgetMXN, 1))
                    .tint(.ascendGold)
            }

            Section("Resumen amable de la semana") {
                Text("Gastos hormiga: \(amountText(appState.antExpensesTotalMXN)). Nada de qué preocuparse, solo para que lo veas.")
                    .font(.footnote)
                    .foregroundColor(.ascendTextSecondary)
            }

            Section("Movimientos") {
                ForEach(appState.expenses) { expense in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(expense.title)
                            Text(expense.category.rawValue).font(.caption).foregroundColor(.ascendTextSecondary)
                        }
                        Spacer()
                        Text(amountText(expense.amountMXN))
                    }
                    .swipeActions {
                        Button("Eliminar", role: .destructive) {
                            appState.deleteExpense(expense)
                        }
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
                Button("Borrar todos los gastos", role: .destructive) {
                    showDeleteAllConfirm = true
                }
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
            NewExpenseSheet()
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

struct NewExpenseSheet: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var amount = ""
    @State private var category: ExpenseCategory = .food

    var body: some View {
        NavigationStack {
            Form {
                TextField("Título", text: $title)
                TextField("Monto (MXN)", text: $amount).keyboardType(.decimalPad)
                Picker("Categoría", selection: $category) {
                    ForEach(ExpenseCategory.allCases) { cat in
                        Text(cat.rawValue).tag(cat)
                    }
                }
            }
            .ascendListStyle()
            .navigationTitle("Nuevo gasto")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        if let value = Double(amount) {
                            appState.addExpense(Expense(title: title, amountMXN: value, category: category, date: Date()))
                        }
                        dismiss()
                    }.disabled(title.isEmpty || Double(amount) == nil)
                }
            }
        }
    }
}
