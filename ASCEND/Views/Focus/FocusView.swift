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
                VStack(spacing: 22) {
                    timerCard
                    focusProfileCard
                    if !appState.studySessions.isEmpty { historyCard }
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
                Circle().stroke(Color.ascendGray.opacity(0.15), lineWidth: 10)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.ascendGold, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text(timeText)
                    .font(.system(.title, design: .rounded).bold())
                    .minimumScaleFactor(0.5)
                    .accessibilityLabel("\(displaySeconds / 60) minutos \(displaySeconds % 60) segundos restantes")
            }
            .frame(width: 180, height: 180)

            if !appState.isFocusSessionActive {
                Picker("Micro-bloque", selection: $appState.focusBlockMinutes) {
                    ForEach(blockOptions, id: \.self) { Text("\($0) min").tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 30)
                .onChange(of: appState.focusBlockMinutes) { newValue in
                    displaySeconds = newValue * 60
                }

                if !appState.subjects.isEmpty {
                    Picker("Materia", selection: $selectedSubject) {
                        Text("Sin materia").tag("")
                        ForEach(appState.subjects, id: \.self) { Text($0).tag($0) }
                    }
                    .padding(.horizontal, 30)
                }

                Button("Empezar sesión") { start() }
                    .buttonStyle(.borderedProminent)
                    .tint(.ascendGold)
                    .frame(minHeight: 44)
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
        VStack(alignment: .leading, spacing: 10) {
            Text("Modo de enfoque").font(.headline).foregroundColor(.ascendTextPrimary)

            if appState.focusProfiles.isEmpty {
                EmptyHint(text: "Crea perfiles de enfoque en Perfil → Enfoque y bloqueo para elegir qué apps limitar.")
            } else {
                ForEach(appState.focusProfiles) { profile in
                    Button {
                        selectedProfileID = selectedProfileID == profile.id ? nil : profile.id
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(profile.name).foregroundColor(.ascendTextPrimary)
                                Text(profile.blockedApps.isEmpty ? "Sin apps seleccionadas"
                                     : profile.blockedApps.joined(separator: ", "))
                                    .font(.caption).foregroundColor(.ascendTextSecondary).lineLimit(1)
                            }
                            Spacer()
                            Image(systemName: selectedProfileID == profile.id ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(selectedProfileID == profile.id ? .ascendGold : .ascendGray)
                        }
                        .padding(12)
                        .frame(minHeight: 44)
                        .background(Color.ascendCard)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.ascendGray.opacity(0.15)))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }

            Text(ScreenTimeService.availabilityNote)
                .font(.caption2)
                .foregroundColor(.ascendTextSecondary)
        }
        .padding(.horizontal, 20)
    }

    private var historyCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tus sesiones").font(.headline).foregroundColor(.ascendTextPrimary)
            let total = appState.studySessions.reduce(0) { $0 + $1.minutes }
            HStack {
                Text("\(appState.studySessions.count) sesiones")
                Spacer()
                Text("\(total / 60)h \(total % 60)m en total")
                    .foregroundColor(.ascendTextSecondary)
            }
            .font(.subheadline)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.ascendSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 20)
    }
}
