import SwiftUI

struct UpgradeView: View {
    @EnvironmentObject private var appState: AppState

    private let monthlyPrice = 79.0
    private var annualPrice: Double { (monthlyPrice * 12 * 0.95).rounded() }
    private var annualSavings: Double { (monthlyPrice * 12 - annualPrice).rounded() }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                statusCard

                if appState.isPro {
                    manageSection
                } else {
                    plansSection
                    purchaseButtons
                }

                Text("Si tus días Pro llegan a 0, vuelves al plan Gratis sin penalización y sin cobros sorpresa.")
                    .font(.footnote)
                    .foregroundColor(.ascendTextSecondary)
                    .multilineTextAlignment(.center)

                Text("El cobro real todavía no está conectado: requiere una cuenta del Apple Developer Program y los productos creados en App Store Connect (ver README).")
                    .font(.caption2)
                    .foregroundColor(.ascendTextSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(20)
            .readableWidth()
        }
        .ascendListStyle()
        .navigationTitle("Suscripción")
    }

    private var statusCard: some View {
        VStack(spacing: 6) {
            Text(appState.subscription.label)
                .font(.title3.bold())
                .foregroundColor(.ascendTextPrimary)

            switch appState.subscription {
            case .active(let until, let plan, _):
                Text("\(appState.proDaysRemaining) días restantes · renueva el \(until.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption).foregroundColor(.ascendTextSecondary)
                Text(plan == .annual ? "Plan anual" : plan == .monthly ? "Plan mensual" : "Ganado por referidos")
                    .font(.caption2).foregroundColor(.ascendTextSecondary)
            case .cancelled(let until):
                Text("Activo hasta el \(until.formatted(date: .abbreviated, time: .omitted)) y no se renovará.")
                    .font(.caption).foregroundColor(.ascendTextSecondary)
            case .trial(let until):
                Text("Prueba hasta el \(until.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption).foregroundColor(.ascendTextSecondary)
            case .expired:
                Text("Tu Pro terminó. Puedes reactivarlo cuando quieras.")
                    .font(.caption).foregroundColor(.ascendTextSecondary)
            case .free:
                Text("Estás en el plan Gratis, con anuncios discretos.")
                    .font(.caption).foregroundColor(.ascendTextSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(appState.isPro ? Color.ascendSurface : Color.ascendCard)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.ascendGray.opacity(0.2)))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    /// Ya es Pro: no se ofrece comprar otra vez, solo administrar.
    private var manageSection: some View {
        VStack(spacing: 10) {
            if case .active = appState.subscription {
                Button("Cancelar renovación automática") { appState.cancelRenewal() }
                    .buttonStyle(.bordered)
                    .tint(.ascendGray)
            }
            Link("Administrar suscripción en el App Store",
                 destination: URL(string: "https://apps.apple.com/account/subscriptions")!)
                .font(.footnote)
                .foregroundColor(.ascendTextSecondary)
        }
    }

    private var plansSection: some View {
        HStack(spacing: 14) {
            planColumn(title: "Gratis", price: "$0",
                       features: ["Anuncios discretos", "Funciones principales"], highlighted: false)
            planColumn(title: "Pro", price: "$\(Int(monthlyPrice))/mes",
                       features: ["Sin anuncios", "Analítica completa", "Carruseles ilimitados"], highlighted: true)
        }
    }

    private var purchaseButtons: some View {
        VStack(spacing: 10) {
            Button {
                appState.activateMonthly()
            } label: {
                Text("Plan mensual — $\(Int(monthlyPrice))")
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(Color.ascendGold)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            Button {
                appState.activateAnnual()
            } label: {
                VStack(spacing: 2) {
                    Text("Plan anual — $\(Int(annualPrice))")
                    Text("ahorras $\(Int(annualSavings)) vs. pagar mes a mes (5%)")
                        .font(.caption2)
                }
                .frame(maxWidth: .infinity, minHeight: 48)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.ascendGold, lineWidth: 1.5))
            }
        }
    }

    private func planColumn(title: String, price: String, features: [String], highlighted: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline).foregroundColor(.ascendTextPrimary)
            Text(price).font(.title3.bold()).foregroundColor(.ascendTextPrimary)
            ForEach(features, id: \.self) { feature in
                Label(feature, systemImage: "checkmark")
                    .font(.caption)
                    .foregroundColor(.ascendTextSecondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(highlighted ? Color.ascendSurface : Color.ascendCard)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(highlighted ? Color.ascendGold : Color.ascendGray.opacity(0.2)))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
