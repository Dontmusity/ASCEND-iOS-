import SwiftUI

struct FocusView: View {
    @EnvironmentObject private var appState: AppState

    @State private var timer: Timer? = nil
    @State private var displaySeconds: Int = 20 * 60
    @State private var phrase = DemoData.motivationalPhrases.randomElement() ?? ""

    private let blockOptions = [10, 20, 30, 45]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    timerCard
                    appBlockingCard
                    usageCard
                }
                .padding(.vertical, 16)
                .readableWidth()
            }
            .background(Color.ascendBackground.ignoresSafeArea())
            .navigationTitle("Enfoque")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { StreakBadge() }
            }
        }
        .onAppear { resumeIfNeeded() }
        .onDisappear { timer?.invalidate() }
    }

    // MARK: Temporizador

    private var timerCard: some View {
        VStack(spacing: 16) {
            Text(phrase)
                .font(.subheadline)
                .foregroundColor(.ascendTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)

            ZStack {
                Circle()
                    .stroke(Color.ascendGray.opacity(0.15), lineWidth: 10)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.ascendGold, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text(timeText)
                    .font(.system(.title, design: .rounded).bold())
                    .minimumScaleFactor(0.5)
                    .accessibilityLabel(accessibleTimeText)
            }
            .frame(width: 180, height: 180)

            if !appState.isFocusSessionActive {
                Picker("Micro-bloque", selection: $appState.focusBlockMinutes) {
                    ForEach(blockOptions, id: \.self) { minutes in
                        Text("\(minutes) min").tag(minutes)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 30)
                .onChange(of: appState.focusBlockMinutes) { newValue in
                    displaySeconds = newValue * 60
                }

                Button("Empezar sesión") { start() }
                    .buttonStyle(.borderedProminent)
                    .tint(.ascendGold)
            } else {
                Button("Desbloquear ahora") { stop() }
                    .buttonStyle(.borderedProminent)
                    .tint(.ascendGray)
                    .frame(minHeight: 44)
            }
        }
        .padding(.horizontal, 20)
    }

    private var progress: Double {
        let total = Double(appState.focusBlockMinutes * 60)
        return total == 0 ? 0 : 1 - (Double(displaySeconds) / total)
    }

    private var timeText: String {
        String(format: "%02d:%02d", displaySeconds / 60, displaySeconds % 60)
    }

    private var accessibleTimeText: String {
        "\(displaySeconds / 60) minutos \(displaySeconds % 60) segundos restantes"
    }

    /// Reanuda el conteo si ya había una sesión activa en AppState (p. ej. al volver de otro tab):
    /// el tiempo real corre por reloj de pared en AppState, aquí solo se refresca la vista cada segundo.
    private func resumeIfNeeded() {
        if appState.isFocusSessionActive {
            if appState.focusSecondsRemaining <= 0 {
                appState.unlockAllNow()
                displaySeconds = appState.focusBlockMinutes * 60
            } else {
                displaySeconds = appState.focusSecondsRemaining
                armTicker()
            }
        } else {
            displaySeconds = appState.focusBlockMinutes * 60
        }
    }

    private func start() {
        appState.startFocusSession(minutes: appState.focusBlockMinutes)
        displaySeconds = appState.focusSecondsRemaining
        armTicker()
    }

    private func stop() {
        timer?.invalidate()
        timer = nil
        appState.unlockAllNow()
        displaySeconds = appState.focusBlockMinutes * 60
    }

    private func armTicker() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor in
                let remaining = appState.focusSecondsRemaining
                displaySeconds = remaining
                if remaining <= 0 {
                    stop()
                }
            }
        }
    }

    // MARK: Bloqueo de apps (simulado)

    private var appBlockingCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Apps a bloquear durante la sesión").font(.headline)
            ForEach(appState.blockableApps) { app in
                Button {
                    appState.toggleBlock(app)
                } label: {
                    HStack {
                        Image(systemName: app.icon).accessibilityHidden(true)
                        Text(app.name)
                        Spacer()
                        Image(systemName: app.isBlocked ? "lock.fill" : "lock.open")
                            .foregroundColor(app.isBlocked ? .ascendGold : .ascendGray)
                            .accessibilityHidden(true)
                    }
                    .padding(12)
                    .frame(minHeight: 44)
                    .background(Color.ascendCard)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.ascendGray.opacity(0.15)))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .foregroundColor(.ascendTextPrimary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(app.name), \(app.isBlocked ? "bloqueada" : "desbloqueada")")
                .accessibilityAddTraits(app.isBlocked ? .isSelected : [])
            }
            Text("Nunca se bloquean: \(appState.vitalApps.joined(separator: ", ")).")
                .font(.caption)
                .foregroundColor(.ascendTextSecondary)
        }
        .padding(.horizontal, 20)
    }

    // MARK: Medidor de uso (dato demo, solo tiempo)

    private var usageCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Uso del celular hoy").font(.headline)
            HStack {
                Text("\(appState.phoneUsageMinutesToday / 60) h \(appState.phoneUsageMinutesToday % 60) min")
                    .font(.title3.bold())
                Spacer()
                Text("\(appState.focusMinutesToday) min en enfoque")
                    .font(.caption)
                    .foregroundColor(.ascendTextSecondary)
            }
        }
        .padding(16)
        .background(Color.ascendCream)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 20)
    }
}
