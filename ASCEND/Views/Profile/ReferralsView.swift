import SwiftUI

struct ReferralsView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 6) {
                    Text("Invita amigos a ASCEND").font(.title3.bold())
                    Text("y gana Pro gratis").font(.subheadline).foregroundColor(.ascendTextSecondary)
                }

                VStack(spacing: 8) {
                    Text(appState.referralCode)
                        .font(.title2.bold())
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.ascendCream)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    ShareLink(item: "Únete a ASCEND con mi código \(appState.referralCode)") {
                        Label("Compartir enlace", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.ascendGold)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("\(appState.referralCount) invitados válidos")
                        .font(.headline)

                    if let next = appState.nextReferralTier {
                        ProgressView(value: Double(appState.referralCount), total: Double(next.count))
                            .tint(.ascendGold)
                        Text("Siguiente: \(next.label) al llegar a \(next.count)")
                            .font(.caption)
                            .foregroundColor(.ascendTextSecondary)
                    } else {
                        Text("Ya alcanzaste todos los niveles de recompensa 🎉")
                            .font(.caption)
                            .foregroundColor(.ascendTextSecondary)
                    }
                }
                .padding()
                .background(Color.ascendCard)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.ascendGray.opacity(0.15)))
                .clipShape(RoundedRectangle(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(appState.referralTiers, id: \.count) { tier in
                        HStack {
                            Image(systemName: appState.redeemedTierCounts.contains(tier.count) ? "checkmark.seal.fill" : "seal")
                                .foregroundColor(appState.redeemedTierCounts.contains(tier.count) ? .ascendGold : .ascendGray)
                            Text("\(tier.count) personas → \(tier.label)")
                            Spacer()
                        }
                    }
                    Text("Los paquetes no se combinan: 2 personas no dan 2 semanas, la recompensa se gana al llegar exacto a cada nivel.")
                        .font(.caption2)
                        .foregroundColor(.ascendTextSecondary)
                        .padding(.top, 4)
                }
                .padding()
                .background(Color.ascendCream)
                .clipShape(RoundedRectangle(cornerRadius: 14))

                Text("Para contar un referido de verdad hace falta un servidor que valide quién se registró con tu código. ASCEND todavía no tiene backend, así que el contador no sube solo.")
                    .font(.caption2)
                    .foregroundColor(.ascendTextSecondary)
                    .multilineTextAlignment(.center)

                #if DEBUG
                Button("Registrar referido (solo pruebas)") {
                    appState.registerReferral()
                }
                .buttonStyle(.bordered)
                .tint(.ascendGray)
                #endif
            }
            .padding(20)
            .readableWidth()
        }
        .navigationTitle("Referidos")
    }
}
