import SwiftUI

struct ReferralsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var copied = false

    private var shareText: String { "Únete a ASCEND con mi código \(appState.referralCode)" }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Invita amigos a ASCEND")
                        .font(.ascendRounded(25, relativeTo: .title))
                        .foregroundColor(.ascendTextPrimary)
                    Text("y gana Pro gratis")
                        .font(.footnote)
                        .foregroundColor(.ascendTextSecondary)
                }
                .padding(.top, 8)

                codeCard

                AscendKicker(text: "Recompensas").padding(.top, 22)
                VStack(spacing: 0) {
                    ForEach(Array(appState.referralTiers.enumerated()), id: \.element.count) { index, tier in
                        let redeemed = appState.redeemedTierCounts.contains(tier.count)
                        HStack(spacing: 12) {
                            Image(systemName: redeemed ? "checkmark.seal.fill" : "seal")
                                .foregroundColor(redeemed ? .ascendGold : .ascendGray)
                                .frame(width: 34, height: 34)
                            Text("\(tier.count) personas → \(tier.label)")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.ascendTextPrimary)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        if index < appState.referralTiers.count - 1 {
                            Rectangle().fill(Color.ascendHairline).frame(height: 1)
                        }
                    }
                }
                .ascendCard(cornerRadius: 20)
                .padding(.top, 12)

                // TODO(diseño): lista "Ya se unieron" con nombre y fecha. Sin backend no se sabe
                // quién usó el código; hoy solo existe el contador.

                VStack(alignment: .leading, spacing: 8) {
                    Text("Los paquetes no se combinan: 2 personas no dan 2 semanas, la recompensa se gana al llegar exacto a cada nivel.")
                    Text("Para contar un referido de verdad hace falta un servidor que valide quién se registró con tu código. ASCEND todavía no tiene backend, así que el contador no sube solo.")
                }
                .font(.caption)
                .foregroundColor(.ascendTextSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.ascendLine.opacity(0.4), style: StrokeStyle(lineWidth: 1, dash: [4, 3])))
                .padding(.top, 16)

                ShareLink(item: shareText) {
                    Label("Compartir enlace", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(AscendPrimaryButtonStyle())
                .padding(.top, 22)

                #if DEBUG
                Button("Registrar referido (solo pruebas)") {
                    appState.registerReferral()
                }
                .buttonStyle(.bordered)
                .tint(.ascendGray)
                .frame(maxWidth: .infinity)
                .padding(.top, 12)
                #endif
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
            .readableWidth()
        }
        .background(Color.ascendBackground.ignoresSafeArea())
        .navigationTitle("Referidos")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var codeCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            AscendKicker(text: "Tu código", color: .ascendOnSurfaceTertiary)
            HStack(spacing: 12) {
                Text(appState.referralCode)
                    .font(.ascendRounded(26, relativeTo: .title))
                    .tracking(1.5)
                    .foregroundColor(.ascendOnSurface)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .textSelection(.enabled)
                Spacer(minLength: 8)
                Button {
                    UIPasteboard.general.string = appState.referralCode
                    copied = true
                } label: {
                    Label(copied ? "Copiado" : "Copiar", systemImage: copied ? "checkmark" : "doc.on.doc")
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(.ascendOnGold)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 9)
                        .background(Capsule().fill(Color.ascendGold))
                        .frame(minHeight: 44)
                }
                .buttonStyle(AscendPressStyle())
                .sensoryFeedback(.success, trigger: copied) { _, isCopied in isCopied }
            }
            .padding(.top, 12)

            if let next = appState.nextReferralTier {
                HStack(spacing: 9) {
                    AscendProgressBar(progress: Double(appState.referralCount) / Double(next.count),
                                      track: Color.ascendOnSurface.opacity(0.08), height: 6)
                    Text("\(appState.referralCount) de \(next.count)")
                        .font(.ascendRounded(12, .medium, relativeTo: .caption))
                        .monospacedDigit()
                        .foregroundColor(.ascendOnSurfaceSecondary)
                }
                .padding(.top, 18)
                Text("Siguiente: \(next.label) al llegar a \(next.count)")
                    .font(.caption)
                    .foregroundColor(.ascendOnSurfaceSecondary)
                    .padding(.top, 8)
            } else {
                Text("Ya alcanzaste todos los niveles de recompensa 🎉")
                    .font(.caption)
                    .foregroundColor(.ascendOnSurfaceSecondary)
                    .padding(.top, 14)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .ascendSurfaceCard()
        .padding(.top, 20)
    }
}
