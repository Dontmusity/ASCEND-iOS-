import SwiftUI

struct ChatbotButton: View {
    @State private var showChat = false

    var body: some View {
        Button {
            showChat = true
        } label: {
            Image(systemName: "sparkles")
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(Color.ascendGold)
                .clipShape(Circle())
                .goldGlow()
        }
        .buttonStyle(AscendPressStyle())
        .accessibilityLabel("Ascender")
        .sheet(isPresented: $showChat) {
            ChatbotSheetView()
        }
    }
}

struct ChatbotSheetView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    private var suggestion: String {
        switch appState.weekIntensity {
        case .high:
            return "Veo que traes varias cosas encima esta semana. No tienes que hacerlo todo hoy — ¿qué tal si dejamos algo para mañana?"
        case .light:
            return "Esta semana se ve más ligera. Buen momento para adelantar algo sin presión, o simplemente descansar."
        case .normal:
            return "Vas con buen ritmo. Si quieres, puedo sugerirte el siguiente paso del día."
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 11) {
                Circle()
                    .fill(Color.ascendGold)
                    .frame(width: 40, height: 40)
                    .overlay(Image(systemName: "sparkles").foregroundColor(.white))
                    .goldGlow()
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Ascender")
                        .font(.ascendRounded(18, relativeTo: .headline))
                        .foregroundColor(.ascendTextPrimary)
                    Text(appState.profile.name.isEmpty ? "Hola" : "Hola, \(appState.profile.name)")
                        .font(.caption)
                        .foregroundColor(.ascendTextSecondary)
                }
                Spacer()
                Button("Cerrar") { dismiss() }
                    .buttonStyle(AscendPillButtonStyle())
            }
            .padding(.top, 16)

            // Burbuja del asistente: esquina inferior izquierda más cerrada.
            Text(suggestion)
                .font(.body)
                .foregroundColor(.ascendOnSurface)
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .background(
                    UnevenRoundedRectangle(topLeadingRadius: 22, bottomLeadingRadius: 8,
                                           bottomTrailingRadius: 22, topTrailingRadius: 22,
                                           style: .continuous)
                        .fill(Color.ascendSurface)
                )
                .padding(.top, 20)

            // TODO(diseño): respuestas rápidas ("¿Qué sigue hoy?", "Mueve algo a mañana",
            // "Solo quiero desahogarme") y el campo de texto con enviar. El bot todavía no tiene
            // lógica para responder mensajes y el handoff pide no cambiarla; se agregan cuando exista.

            VStack(alignment: .leading, spacing: 5) {
                Text("Ascender no reemplaza ayuda profesional.")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.ascendTextPrimary)
                Text("No da diagnósticos, no inventa datos tuyos, y si detecta una señal de crisis emocional te va a sugerir buscar apoyo profesional en lugar de intentar resolverlo solo.")
                    .font(.caption2)
                    .foregroundColor(.ascendTextSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.ascendLine.opacity(0.4), style: StrokeStyle(lineWidth: 1, dash: [4, 3])))
            .padding(.top, 22)

            Spacer()
        }
        .padding(.horizontal, 20)
        .background(Color.ascendBackground.ignoresSafeArea())
        .presentationDragIndicator(.visible)
    }
}
