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
                .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
        }
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
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 10) {
                    Circle()
                        .fill(Color.ascendGold)
                        .frame(width: 36, height: 36)
                        .overlay(Image(systemName: "sparkles").foregroundColor(.white))
                    VStack(alignment: .leading) {
                        Text("Ascender").font(.headline)
                        Text(appState.profile.name.isEmpty ? "Hola" : "Hola, \(appState.profile.name)")
                            .font(.caption)
                            .foregroundColor(.ascendTextSecondary)
                    }
                }

                Text(suggestion)
                    .padding()
                    .background(Color.ascendCream)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 6) {
                    Text("Ascender no reemplaza ayuda profesional.")
                        .font(.caption.bold())
                    Text("No da diagnósticos, no inventa datos tuyos, y si detecta una señal de crisis emocional te va a sugerir buscar apoyo profesional en lugar de intentar resolverlo solo.")
                        .font(.caption2)
                        .foregroundColor(.ascendTextSecondary)
                }
                .padding(.top, 4)

                Spacer()
            }
            .padding()
            .background(Color.ascendBackground.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
    }
}
