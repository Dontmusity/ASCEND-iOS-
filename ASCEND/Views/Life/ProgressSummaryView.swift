import SwiftUI

enum ProgressPeriod: String, CaseIterable, Identifiable {
    case day = "Día", week = "Semana", month = "Mes"
    var id: String { rawValue }
    var days: Int { self == .day ? 1 : self == .week ? 7 : 30 }
}

/// Círculo grande de % completado + desglose por área y por dinero (punto pedido: "qué completaste y por qué ese %").
struct ProgressSummaryCard: View {
    @EnvironmentObject private var appState: AppState
    @State private var period: ProgressPeriod = .day
    @State private var detailLane: CalendarLane? = nil
    @State private var showMoneyDetail = false

    private var percent: Double? {
        period == .day ? appState.completionPercent() : appState.averageCompletionPercent(days: period.days)
    }

    private var lanesWithData: [CalendarLane] {
        CalendarLane.allCases.filter { $0 != .all && !appState.todayCompletionDetail(lane: $0).isEmpty }
    }

    var body: some View {
        VStack(spacing: 16) {
            Picker("Periodo", selection: $period) {
                ForEach(ProgressPeriod.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)

            Button { detailLane = .all } label: { progressCircle }
                .buttonStyle(.plain)

            if lanesWithData.isEmpty {
                Text("Agrega actividades a tu día para ver tu progreso por área.")
                    .font(.footnote)
                    .foregroundColor(.ascendTextSecondary)
            } else {
                VStack(spacing: 8) {
                    ForEach(lanesWithData) { lane in
                        Button { detailLane = lane } label: { laneRow(lane) }
                            .buttonStyle(.plain)
                    }
                }
            }

            Button { showMoneyDetail = true } label: { moneyRow }
                .buttonStyle(.plain)
        }
        .padding(16)
        .background(Color.ascendSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .sheet(item: $detailLane) { lane in
            LaneCompletionDetailSheet(lane: lane, period: period)
        }
        .sheet(isPresented: $showMoneyDetail) { MoneyBreakdownSheet() }
    }

    private var progressCircle: some View {
        ZStack {
            Circle().stroke(Color.ascendGray.opacity(0.15), lineWidth: 12)
            if let percent {
                Circle()
                    .trim(from: 0, to: percent / 100)
                    .stroke(Color.ascendGold, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            VStack(spacing: 2) {
                Text(percent.map { "\(Int($0.rounded()))%" } ?? "—")
                    .font(.system(.title, design: .rounded).bold())
                    .foregroundColor(.ascendTextPrimary)
                Text("completado · \(period.rawValue.lowercased())")
                    .font(.caption2)
                    .foregroundColor(.ascendTextSecondary)
            }
        }
        .frame(width: 140, height: 140)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(Int((percent ?? 0).rounded())) por ciento completado esta \(period.rawValue.lowercased())")
    }

    private func laneRow(_ lane: CalendarLane) -> some View {
        let value = period == .day
            ? appState.completionPercent(lane: lane)
            : appState.averageCompletionPercent(days: period.days, lane: lane)
        return HStack {
            Image(systemName: lane.icon).foregroundColor(lane.accentColor)
            Text(lane.rawValue).foregroundColor(.ascendTextPrimary)
            Spacer()
            Text(value.map { "\(Int($0.rounded()))%" } ?? "—")
                .foregroundColor(.ascendTextSecondary)
            Image(systemName: "chevron.right").font(.caption2).foregroundColor(.ascendGray)
        }
        .padding(10)
        .frame(minHeight: 44)
        .background(Color.ascendCard)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var moneyRow: some View {
        HStack {
            Image(systemName: "banknote").foregroundColor(.ascendGold)
            Text("Dinero").foregroundColor(.ascendTextPrimary)
            Spacer()
            Text("$\(Int(appState.spentToday)) hoy").foregroundColor(.ascendTextSecondary)
            Image(systemName: "chevron.right").font(.caption2).foregroundColor(.ascendGray)
        }
        .padding(10)
        .frame(minHeight: 44)
        .background(Color.ascendCard)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

/// Desglose de una sola área: qué se marcó completado hoy y qué no, para explicar el %.
struct LaneCompletionDetailSheet: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    let lane: CalendarLane
    let period: ProgressPeriod

    var body: some View {
        NavigationStack {
            List {
                Section {
                    let percent = period == .day
                        ? appState.completionPercent(lane: lane)
                        : appState.averageCompletionPercent(days: period.days, lane: lane)
                    LabeledContent("Cumplimiento (\(period.rawValue.lowercased()))",
                                   value: percent.map { "\(Int($0.rounded()))%" } ?? "—")
                }
                Section("Hoy") {
                    let detail = appState.todayCompletionDetail(lane: lane)
                    if detail.isEmpty {
                        Text("No tienes nada de \(lane.rawValue.lowercased()) agendado hoy.")
                            .font(.footnote)
                            .foregroundColor(.ascendTextSecondary)
                    }
                    ForEach(detail, id: \.entry.id) { item in
                        HStack {
                            Image(systemName: statusIcon(item.done))
                                .foregroundColor(statusColor(item.done))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.entry.title).foregroundColor(.ascendTextPrimary)
                                Text(item.entry.timeLabel).font(.caption).foregroundColor(.ascendTextSecondary)
                            }
                            Spacer()
                            Text(statusLabel(item.done)).font(.caption).foregroundColor(.ascendTextSecondary)
                        }
                    }
                }
            }
            .ascendListStyle()
            .navigationTitle(lane == .all ? "Tu día" : lane.rawValue)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cerrar") { dismiss() } }
            }
        }
    }

    private func statusIcon(_ done: Bool?) -> String {
        switch done {
        case .some(true): return "checkmark.circle.fill"
        case .some(false): return "xmark.circle.fill"
        case .none: return "circle.dashed"
        }
    }

    private func statusColor(_ done: Bool?) -> Color {
        done == true ? .ascendGold : .ascendGray
    }

    private func statusLabel(_ done: Bool?) -> String {
        switch done {
        case .some(true): return "Completada"
        case .some(false): return "No completada"
        case .none: return "Sin responder"
        }
    }
}

/// Cuánto se ha gastado por periodo, con promedios. Mismos datos que Dinero, solo agrupados distinto.
struct MoneyBreakdownSheet: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Gastado") {
                    LabeledContent("Hoy", value: money(appState.spentToday))
                    LabeledContent("Esta semana", value: money(appState.spentThisWeek))
                    LabeledContent("Este mes", value: money(appState.spentThisMonth))
                    LabeledContent("Este año", value: money(appState.spentThisYear))
                }
                Section("Promedio") {
                    LabeledContent("Diario (este mes)", value: money(appState.averageDailySpendThisMonth))
                    LabeledContent("Semanal (este mes)", value: money(appState.averageWeeklySpendThisMonth))
                    LabeledContent("Mensual (este año)", value: money(appState.averageMonthlySpendThisYear))
                }
            }
            .ascendListStyle()
            .navigationTitle("Dinero")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cerrar") { dismiss() } }
            }
        }
    }

    private func money(_ value: Double) -> String { "$\(Int(value.rounded())) MXN" }
}
