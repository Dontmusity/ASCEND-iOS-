import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 14) {
                        Circle()
                            .fill(Color.ascendCream)
                            .frame(width: 56, height: 56)
                            .overlay(Text(String(appState.profile.name.prefix(1))).font(.title2.bold()).foregroundColor(.ascendTextPrimary).minimumScaleFactor(0.5))
                        VStack(alignment: .leading) {
                            Text(appState.profile.name).font(.headline)
                            Text(appState.profile.university).font(.subheadline).foregroundColor(.ascendTextSecondary)
                        }
                    }
                }

                Section("Meta") {
                    Text(appState.profile.mainGoal.isEmpty ? "Sin meta definida" : appState.profile.mainGoal)
                }

                Section("Plan") {
                    HStack {
                        Text(appState.isPro ? "Plan Pro" : "Plan Gratis")
                        Spacer()
                        if appState.isPro {
                            Text("\(appState.proDaysRemaining) días restantes").foregroundColor(.ascendTextSecondary)
                        } else {
                            Text("con anuncios").foregroundColor(.ascendTextSecondary)
                        }
                    }
                    NavigationLink("Invita amigos y gana Pro") { ReferralsView() }
                    NavigationLink("Comparar planes") { UpgradeView() }
                }

                Section("Configuración") {
                    NavigationLink("Notificaciones") { NotificationsSettingsView() }
                    NavigationLink("Privacidad") { PrivacySettingsView() }
                }
            }
            .ascendListStyle()
            .navigationTitle("Perfil")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { StreakBadge() }
            }
        }
    }
}

struct NotificationsSettingsView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Form {
            Section("Frecuencia") {
                Stepper("Máximo \(appState.notificationsPerDay) al día", value: $appState.notificationsPerDay, in: 0...5)
            }
            Section("Horario silencioso") {
                Stepper("Desde las \(appState.quietHoursStart):00", value: $appState.quietHoursStart, in: 18...23)
                Stepper("Hasta las \(appState.quietHoursEnd):00", value: $appState.quietHoursEnd, in: 5...10)
            }
            Section {
                Text("Ascender nunca notifica de madrugada ni durante tus horarios de clase.")
                    .font(.footnote)
                    .foregroundColor(.ascendTextSecondary)
            }

            if !appState.customLanes.isEmpty {
                Section("Carruseles personalizados") {
                    ForEach($appState.customLanes) { $lane in
                        Toggle(lane.name, isOn: $lane.notificationsEnabled)
                    }
                }
            }
        }
        .ascendListStyle()
        .navigationTitle("Notificaciones")
    }
}

struct PrivacySettingsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showResetPIN = false
    @State private var newPIN = ""

    var body: some View {
        Form {
            Section("Datos") {
                Text("ASCEND guarda tus hábitos, calendario, gastos, trámites y conversaciones con Ascender, todo de forma privada. Puedes exportar o borrar tus datos cuando quieras.")
                    .font(.footnote)
                    .foregroundColor(.ascendTextSecondary)
            }

            Section("Gastos") {
                Toggle("Bloquear sección con PIN", isOn: $appState.expensesPINEnabled)
                if appState.expensesPINEnabled {
                    Button("Cambiar PIN") { showResetPIN = true }
                }
                Text("Tus gastos nunca se comparten con terceros ni se usan para anuncios.")
                    .font(.footnote)
                    .foregroundColor(.ascendTextSecondary)
            }

            Section("Permisos") {
                Text("La app funciona aunque rechaces permisos opcionales como notificaciones o calendario.")
                    .font(.footnote)
                    .foregroundColor(.ascendTextSecondary)
            }
        }
        .ascendListStyle()
        .navigationTitle("Privacidad")
        .alert("Nuevo PIN", isPresented: $showResetPIN) {
            SecureField("4 dígitos", text: $newPIN).keyboardType(.numberPad)
            Button("Guardar") {
                if newPIN.count == 4 { appState.expensesPIN = newPIN }
                newPIN = ""
            }
            Button("Cancelar", role: .cancel) {}
        }
    }
}
