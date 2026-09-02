import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var appState: AppState
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            AscendLogo()
                .frame(width: 56, height: 56)

            VStack(spacing: 4) {
                Text("ASCEND").font(.title.bold())
                Text("Plan. Focus. Conquer.").font(.subheadline).foregroundColor(.ascendTextSecondary)
            }

            VStack(spacing: 12) {
                socialButton(title: "Continuar con Apple", systemImage: "apple.logo")
                socialButton(title: "Continuar con Google", systemImage: "g.circle.fill")
                socialButton(title: "Continuar con Microsoft", systemImage: "square.grid.2x2.fill")
            }
            .padding(.horizontal, 32)

            HStack {
                Rectangle().frame(height: 1).foregroundColor(.ascendGray.opacity(0.3))
                Text("o").font(.footnote).foregroundColor(.ascendTextSecondary)
                Rectangle().frame(height: 1).foregroundColor(.ascendGray.opacity(0.3))
            }
            .padding(.horizontal, 32)

            VStack(spacing: 10) {
                TextField("Correo", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                SecureField("Contraseña", text: $password)
                    .textFieldStyle(.roundedBorder)
            }
            .padding(.horizontal, 32)

            Button {
                appState.completeLogin()
            } label: {
                Text("Entrar")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.ascendGold)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 32)

            Spacer()
        }
        .background(Color.ascendBackground.ignoresSafeArea())
    }

    private func socialButton(title: String, systemImage: String) -> some View {
        Button {
            // Simulado: sin Supabase conectado, el login social entra directo a onboarding.
            appState.completeLogin()
        } label: {
            HStack {
                Image(systemName: systemImage)
                Text(title)
                Spacer()
            }
            .padding()
            .background(Color.ascendCard)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.ascendGray.opacity(0.25)))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .foregroundColor(.ascendTextPrimary)
        }
    }
}
