import SwiftUI

/// Componente global: racha siempre visible, nunca en rojo ni como fracaso.
struct StreakBadge: View {
    @EnvironmentObject private var appState: AppState
    @State private var showDetail = false

    var body: some View {
        Button {
            showDetail = true
        } label: {
            HStack(spacing: 5) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.ascendGold)
                    .accessibilityHidden(true)
                Text("\(appState.currentStreak)")
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                    .foregroundColor(.ascendTextSecondary)
                    .contentTransition(.numericText())
                    .animation(.default, value: appState.currentStreak)
            }
            .padding(.horizontal, 11)
            .padding(.vertical, 5)
            .overlay(Capsule().stroke(Color.ascendHairline, lineWidth: 1))
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(AscendPressStyle())
        .accessibilityLabel("Racha actual: \(appState.currentStreak) días")
        .popover(isPresented: $showDetail) {
            StreakDetailView()
                .frame(minWidth: 260, minHeight: 220)
        }
    }
}

private struct StreakDetailView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Tu racha").font(.headline)

            HStack(spacing: 24) {
                statColumn(value: "\(appState.currentStreak)", label: "Racha actual")
                statColumn(value: "\(appState.bestStreak)", label: "Mejor racha")
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Este mes").font(.caption).foregroundColor(.ascendTextSecondary)
                Text("\(appState.accumulatedThisMonth) de 30 días con progreso")
                    .font(.subheadline.bold())
            }

            Text("Un mal día no borra tu camino. Lo que ya lograste se queda contigo.")
                .font(.footnote)
                .foregroundColor(.ascendTextSecondary)

            Spacer()
        }
        .padding()
    }

    private func statColumn(value: String, label: String) -> some View {
        VStack {
            Text(value).font(.title2.bold()).foregroundColor(.ascendGold)
            Text(label).font(.caption).foregroundColor(.ascendTextSecondary)
        }
    }
}
