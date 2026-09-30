import SwiftUI

struct FocusView: View {
    @EnvironmentObject private var appState: AppState

    @State private var timer: Timer? = nil
    @State private var displaySeconds: Int = 20 * 60
    @State private var phrase = DemoData.motivationalPhrases.randomElement() ?? ""
    @State private var selectedSubject: String = ""
    @State private var selectedProfileID: UUID? = nil

    private let blockOptions = [10, 20, 30, 45]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    header
                    timerCard
                    focusProfileCard
                    if !appState.studySessions.isEmpty { historyCard }
                }
                .padding(.bottom, 90) // deja libre el FAB
                .readableWidth()
            }
            .background(Color.ascendBackground.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
        .onAppear { resumeIfNeeded() }
        .onDisappear { timer?.invalidate() }
        .onChange(of: appState.isFocusSessionActive) { _, isActive in
            // Si la sesión se cerró desde fuera (widget, isla dinámica), el contador de aquí también para.
            if !isActive {
                timer?.invalidate()
                timer = nil
                displaySeconds = appState.focusBlockMinutes * 60
            }
        }
    }

    private var header: some View {
        HStack {
            AscendKicker(text: "Enfoque")
            Spacer()
            StreakBadge()
        }
        .padding(.horizontal, 20)
        .padding(.top, 6)
    }

    // MARK: Temporizador

    private var timerCard: some View {
        VStack(spacing: 0) {
            Text(phrase)
                .font(.subheadline)
                .foregroundColor(.ascendTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 34)
                .padding(.top, 8)

            ZStack {
                Circle().fill(Color.ascendSurface.opacity(0.55))
                AscendRing(progress: progress, track: Color.ascendOnSurface.opacity(0.08), lineWidth: 10)
                VStack(spacing: 9) {
                    Text(timeText)
                        .font(.ascendRounded(46, relativeTo: .largeTitle))
                        .monospacedDigit()
                        .foregroundColor(.ascendOnSurface)
                        .minimumScaleFactor(0.5)
                        .accessibilityLabel("\(displaySeconds / 60) minutos \(displaySeconds % 60) segundos restantes")
                    if !selectedSubject.isEmpty {
                        AscendKicker(text: selectedSubject, color: .ascendOnSurfaceTertiary)
                            .lineLimit(1)
                            .padding(.horizontal, 30)
                    }
                }
            }
            .frame(width: 212, height: 212)
            .padding(.top, 14)

            if !appState.isFocusSessionActive {
                HStack(spacing: 8) {
                    ForEach(blockOptions, id: \.self) { minutes in
                        let isActive = appState.focusBlockMinutes == minutes
                        AscendChip(icon: nil, title: isActive ? "\(minutes) min" : "\(minutes)",
                                   isActive: isActive) {
                            appState.focusBlockMinutes = minutes
                            displaySeconds = minutes * 60
                        }
                        .accessibilityLabel("\(minutes) minutos")
                    }
                }
                .padding(.top, 18)

                if !appState.subjects.isEmpty {
                    Picker("Materia", selection: $selectedSubject) {
                        Text("Sin materia").tag("")
                        ForEach(appState.subjects, id: \.self) { Text($0).tag($0) }
                    }
                    .tint(.ascendTextSecondary)
                    .padding(.top, 4)
                }

                Button { start() } label: {
                    Label("Empezar sesión", systemImage: "play.fill")
                }
                .buttonStyle(AscendPrimaryButtonStyle())
                .padding(.top, 12)
            } else {
                Button("Desbloquear ahora") { stop() }
                    .font(.body.weight(.semibold))
                    .foregroundColor(.ascendTextPrimary)
                    .padding(.horizontal, 26)
                    .frame(minHeight: 50)
                    .overlay(Capsule().stroke(Color.ascendLine.opacity(0.5), lineWidth: 1))
                    .buttonStyle(AscendPressStyle())
                    .padding(.top, 18)
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

    private func resumeIfNeeded() {
        guard appState.isFocusSessionActive else {
            displaySeconds = appState.focusBlockMinutes * 60
            return
        }
        if appState.focusSecondsRemaining <= 0 {
            stop()
        } else {
            displaySeconds = appState.focusSecondsRemaining
            armTicker()
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
        appState.finishFocusSession(subject: selectedSubject.isEmpty ? nil : selectedSubject)
        displaySeconds = appState.focusBlockMinutes * 60
    }

    private func armTicker() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor in
                displaySeconds = appState.focusSecondsRemaining
                if displaySeconds <= 0 { stop() }
            }
        }
    }

    // MARK: Perfil de enfoque

    private var focusProfileCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            AscendKicker(text: "Modo de enfoque")

            if appState.focusProfiles.isEmpty {
                EmptyHint(text: "Crea perfiles de enfoque en Perfil → Enfoque y bloqueo para elegir qué apps limitar.")
                    .padding(.top, 12)
            } else {
                VStack(spacing: 9) {
                    ForEach(appState.focusProfiles) { profile in
                        let isSelected = selectedProfileID == profile.id
                        Button {
                            selectedProfileID = isSelected ? nil : profile.id
                        } label: {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(profile.name)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(.ascendTextPrimary)
                                    Text(profile.blockedApps.isEmpty ? "Sin apps seleccionadas"
                                         : profile.blockedApps.joined(separator: ", "))
                                        .font(.caption2)
                                        .foregroundColor(.ascendTextSecondary)
                                        .lineLimit(1)
                                }
                                Spacer()
                                AscendCheck(isOn: isSelected, size: 24)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 13)
                            .frame(minHeight: 44)
                            .areaTint(.ascendGold, fill: isSelected ? 0.12 : 0.05)
                        }
                        .buttonStyle(AscendPressStyle())
                        .accessibilityAddTraits(isSelected ? .isSelected : [])
                    }
                }
                .padding(.top, 12)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Las apps vitales (Teléfono, Mensajes, Cámara, Mapas) nunca se bloquean, y el botón “Desbloquear ahora” siempre está disponible durante una sesión.")
                Text(ScreenTimeService.availabilityNote)
            }
            .font(.caption)
            .foregroundColor(.ascendTextSecondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.ascendLine.opacity(0.4), style: StrokeStyle(lineWidth: 1, dash: [4, 3])))
            .padding(.top, 14)
        }
        .padding(.horizontal, 20)
        .padding(.top, 22)
    }

    private var historyCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            AscendKicker(text: "Tus sesiones")
            let total = appState.studySessions.reduce(0) { $0 + $1.minutes }
            HStack {
                Text("\(appState.studySessions.count) sesiones")
                    .foregroundColor(.ascendTextPrimary)
                Spacer()
                Text("\(total / 60)h \(total % 60)m en total")
                    .foregroundColor(.ascendTextSecondary)
            }
            .font(.subheadline)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .ascendCard()
        .padding(.horizontal, 20)
        .padding(.top, 14)
    }
}
