import SwiftUI

struct UpgradeView: View {
    @EnvironmentObject private var appState: AppState

    private let monthlyPrice = 79.0

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if appState.isPro {
                    VStack(spacing: 4) {
                        Text("Ya eres Pro").font(.title3.bold())
                        Text("Te quedan \(appState.proDaysRemaining) días")
                            .foregroundColor(.ascendTextSecondary)
                    }
                }

                HStack(spacing: 16) {
                    planColumn(title: "Gratis", price: "$0", features: ["Anuncios discretos", "Funciones principales"], highlighted: false)
                    planColumn(title: "Pro", price: "$\(Int(monthlyPrice))/mes", features: ["Sin anuncios", "Analítica completa", "Carruseles ilimitados*"], highlighted: true)
                }

                VStack(spacing: 10) {
                    Button {
                        appState.buyMonthly()
                    } label: {
                        Text("Suscribirme mensual — $\(Int(monthlyPrice))")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.ascendGold)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    Button {
                        appState.buyAnnual()
                    } label: {
                        VStack(spacing: 2) {
                            Text("Suscribirme anual — $\(Int(monthlyPrice * 12 * 0.95)) (ahorras \(Int(monthlyPrice * 12 * 0.05)))")
                            Text("5% de descuento vs. pagar mes a mes").font(.caption2)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.ascendGold, lineWidth: 1.5))
                    }
                }

                Text("Si tus días Pro llegan a 0, vuelves al plan Gratis sin penalización.")
                    .font(.footnote)
                    .foregroundColor(.ascendTextSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(20)
            .readableWidth()
        }
        .navigationTitle("Actualizar plan")
    }

    private func planColumn(title: String, price: String, features: [String], highlighted: Bool) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.headline)
            Text(price).font(.title3.bold()).foregroundColor(highlighted ? .ascendGold : .ascendTextPrimary)
            ForEach(features, id: \.self) { feature in
                Label(feature, systemImage: "checkmark").font(.caption)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(highlighted ? Color.ascendCream : Color.ascendCard)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(highlighted ? Color.ascendGold : Color.ascendGray.opacity(0.2)))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
