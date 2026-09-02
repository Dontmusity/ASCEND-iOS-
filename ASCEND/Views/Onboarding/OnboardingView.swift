import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var appState: AppState

    @State private var step = 0
    @State private var name = ""
    @State private var university = ""
    @State private var major = ""
    @State private var livingSituation = "Vive sola/o"
    @State private var mainGoal = ""
    @State private var academicLoad: AcademicLoad = .moderate

    private let livingOptions = ["Vive sola/o", "Con roommates", "Con familia", "En dormitorio universitario"]
    private let totalSteps = 5

    var body: some View {
        VStack(spacing: 24) {
            AscendLogo()
                .frame(width: 44, height: 44)
                .padding(.top, 32)

            ProgressView(value: Double(step + 1), total: Double(totalSteps))
                .tint(.ascendGold)
                .padding(.horizontal, 32)

            Spacer()

            Group {
                switch step {
                case 0: nameStep
                case 1: schoolStep
                case 2: livingStep
                case 3: goalStep
                default: loadStep
                }
            }
            .padding(.horizontal, 32)
            .transition(.opacity)

            Spacer()

            Button(action: advance) {
                Text(step == totalSteps - 1 ? "Empezar" : "Continuar")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.ascendGold)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .disabled(!canAdvance)
            .opacity(canAdvance ? 1 : 0.5)
            .padding(.horizontal, 32)
            .padding(.bottom, 24)
        }
        .background(Color.ascendBackground.ignoresSafeArea())
    }

    private var canAdvance: Bool {
        switch step {
        case 0: return !name.trimmingCharacters(in: .whitespaces).isEmpty
        case 1: return !university.isEmpty && !major.isEmpty
        default: return true
        }
    }

    private func advance() {
        if step < totalSteps - 1 {
            withAnimation { step += 1 }
        } else {
            let profile = UserProfile(
                name: name,
                university: university,
                major: major,
                livingSituation: livingSituation,
                mainGoal: mainGoal,
                academicLoad: academicLoad
            )
            appState.completeOnboarding(profile: profile)
        }
    }

    private var nameStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("¿Cómo te llamas?").font(.title2.bold())
            Text("Así te vamos a hablar en toda la app.").foregroundColor(.ascendTextSecondary)
            TextField("Tu nombre", text: $name)
                .textFieldStyle(.roundedBorder)
        }
    }

    private var schoolStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("¿Dónde estudias?").font(.title2.bold())
            TextField("Universidad", text: $university).textFieldStyle(.roundedBorder)
            TextField("Carrera", text: $major).textFieldStyle(.roundedBorder)
        }
    }

    private var livingStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("¿Cómo vives ahora?").font(.title2.bold())
            ForEach(livingOptions, id: \.self) { option in
                SelectableRow(label: option, isSelected: livingSituation == option) {
                    livingSituation = option
                }
            }
        }
    }

    private var goalStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("¿Cuál es tu meta principal ahora?").font(.title2.bold())
            TextField("Ej. mantener mis hábitos, ahorrar más...", text: $mainGoal)
                .textFieldStyle(.roundedBorder)
        }
    }

    private var loadStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("¿Cómo sientes tu carga académica?").font(.title2.bold())
            ForEach(AcademicLoad.allCases) { load in
                SelectableRow(label: load.rawValue, isSelected: academicLoad == load) {
                    academicLoad = load
                }
            }
        }
    }
}

private struct SelectableRow: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(label).foregroundColor(.ascendTextPrimary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(.ascendGold)
                }
            }
            .padding()
            .background(isSelected ? Color.ascendCream : Color.ascendCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.ascendGray.opacity(0.2)))
        }
    }
}

struct AscendLogo: View {
    var body: some View {
        ZStack {
            Image(systemName: "arrowtriangle.up.fill")
                .resizable()
                .scaledToFit()
                .foregroundColor(.ascendGold)
        }
    }
}
