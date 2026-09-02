import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 14) {
                        Circle()
                            .fill(Color.ascendSurface)
                            .frame(width: 56, height: 56)
                            .overlay(
                                Text(String(appState.profile.name.prefix(1)).uppercased())
                                    .font(.title2.bold())
                                    .foregroundColor(.ascendTextPrimary)
                                    .minimumScaleFactor(0.5))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(appState.profile.name.isEmpty ? "Tu perfil" : appState.profile.name)
                                .font(.headline)
                            Text(appState.education.summary)
                                .font(.subheadline)
                                .foregroundColor(.ascendTextSecondary)
                        }
                    }
                }

                Section("Mi rutina") {
                    NavigationLink("Escuela y horario") { EditScheduleView() }
                    NavigationLink("Entrenamiento y deporte") { EditTrainingView() }
                    NavigationLink("Comidas y objetivo") { EditMealsView() }
                    NavigationLink("Actividades personalizadas") { EditActivitiesView() }
                }

                Section("Plan") {
                    HStack {
                        Text(appState.subscription.label)
                        Spacer()
                        if appState.isPro, let until = appState.subscription.expirationDate {
                            Text("hasta \(until.formatted(date: .abbreviated, time: .omitted))")
                                .foregroundColor(.ascendTextSecondary)
                                .font(.caption)
                        } else {
                            Text("con anuncios").foregroundColor(.ascendTextSecondary).font(.caption)
                        }
                    }
                    NavigationLink("Invita amigos y gana Pro") { ReferralsView() }
                    NavigationLink("Suscripción") { UpgradeView() }
                }

                Section("Ajustes") {
                    NavigationLink("Notificaciones") { NotificationsSettingsView() }
                    NavigationLink("Enfoque y bloqueo de apps") { FocusSettingsView() }
                    NavigationLink("Privacidad") { PrivacySettingsView() }
                }

                Section("Cuenta") {
                    NavigationLink("Cuenta") { AccountSettingsView() }
                }

                #if DEBUG
                Section("Desarrollo") {
                    Button("Cargar datos de ejemplo") { appState.loadSampleData() }
                }
                #endif
            }
            .ascendListStyle()
            .navigationTitle("Perfil")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { StreakBadge() }
            }
        }
    }
}

// MARK: - Cuenta

struct AccountSettingsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showLogOutConfirm = false
    @State private var showDeleteConfirm = false
    @State private var showFinalDeleteConfirm = false

    var body: some View {
        List {
            Section("Perfil") {
                TextField("Nombre", text: $appState.profile.name)
                TextField("Universidad o escuela", text: $appState.profile.university)
            }

            Section {
                Button("Cerrar sesión") { showLogOutConfirm = true }
            } footer: {
                Text("Tu rutina se queda guardada en este dispositivo.")
            }

            Section {
                Button("Eliminar cuenta", role: .destructive) { showDeleteConfirm = true }
            } footer: {
                Text("Borra permanentemente todos tus datos de ASCEND en este dispositivo.")
            }
        }
        .ascendListStyle()
        .navigationTitle("Cuenta")
        .confirmationDialog("¿Cerrar sesión?", isPresented: $showLogOutConfirm, titleVisibility: .visible) {
            Button("Cerrar sesión") { appState.logOut() }
            Button("Cancelar", role: .cancel) {}
        }
        .alert("¿Eliminar tu cuenta?", isPresented: $showDeleteConfirm) {
            Button("Cancelar", role: .cancel) {}
            Button("Eliminar cuenta", role: .destructive) { showFinalDeleteConfirm = true }
        } message: {
            Text("Esto elimina permanentemente tu cuenta de ASCEND y los datos asociados: horario, entrenamientos, gastos, metas y racha. No se puede deshacer.")
        }
        .alert("Confirma una vez más", isPresented: $showFinalDeleteConfirm) {
            Button("Cancelar", role: .cancel) {}
            Button("Sí, eliminar todo", role: .destructive) {
                NotificationService.shared.cancelAll()
                appState.deleteAccount()
            }
        } message: {
            Text("Se borrará todo y volverás a la pantalla de inicio de sesión.")
        }
    }
}

// MARK: - Notificaciones

struct NotificationsSettingsView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var notifications = NotificationService.shared

    var body: some View {
        Form {
            if notifications.authorizationStatus != .authorized {
                Section {
                    Text("ASCEND puede recordarte clases, entrenamientos, entregas y actividades importantes.")
                        .font(.footnote)
                        .foregroundColor(.ascendTextSecondary)
                    Button("Activar notificaciones") {
                        Task {
                            await notifications.requestAuthorization()
                            await notifications.reschedule(state: appState)
                        }
                    }
                }
            }

            Section("Qué quieres recibir") {
                Toggle("Clases", isOn: $appState.notificationPrefs.classes)
                Toggle("Tareas", isOn: $appState.notificationPrefs.assignments)
                Toggle("Exámenes", isOn: $appState.notificationPrefs.exams)
                Toggle("Entrenamientos", isOn: $appState.notificationPrefs.workouts)
                Toggle("Comidas", isOn: $appState.notificationPrefs.meals)
                Toggle("Metas y hábitos", isOn: $appState.notificationPrefs.goals)
                Toggle("Actividades personalizadas", isOn: $appState.notificationPrefs.customActivities)
            }

            Section("Frecuencia") {
                Stepper("Máximo \(appState.notificationPrefs.maxPerDay) al día",
                        value: $appState.notificationPrefs.maxPerDay, in: 0...8)
                Stepper("Silencio desde las \(appState.notificationPrefs.quietHoursStart):00",
                        value: $appState.notificationPrefs.quietHoursStart, in: 18...23)
                Stepper("Hasta las \(appState.notificationPrefs.quietHoursEnd):00",
                        value: $appState.notificationPrefs.quietHoursEnd, in: 5...11)
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
        .task { await notifications.refreshStatus() }
        .onDisappear {
            Task { await notifications.reschedule(state: appState) }
        }
    }
}

// MARK: - Enfoque y bloqueo

struct FocusSettingsView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var screenTime = ScreenTimeService.shared
    @State private var newProfileName = ""

    private let commonApps = ["Instagram", "TikTok", "X", "YouTube", "WhatsApp", "Juegos"]

    var body: some View {
        List {
            Section {
                Text(ScreenTimeService.availabilityNote)
                    .font(.footnote)
                    .foregroundColor(.ascendTextSecondary)
                Button(screenTime.isAuthorized ? "Screen Time autorizado ✓" : "Autorizar Screen Time") {
                    Task { await screenTime.requestAuthorization() }
                }
                .disabled(screenTime.isAuthorized)
                if let error = screenTime.lastError {
                    Text(error).font(.caption).foregroundColor(.ascendTextSecondary)
                }
            }

            Section("Tus perfiles") {
                if appState.focusProfiles.isEmpty {
                    Text("Crea perfiles como Estudio, Gym o Personal y elige qué limitar en cada uno.")
                        .font(.footnote).foregroundColor(.ascendTextSecondary)
                }
                ForEach($appState.focusProfiles) { $profile in
                    NavigationLink {
                        FocusProfileEditor(profile: $profile, options: commonApps)
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(profile.name)
                            Text(profile.blockedApps.isEmpty ? "Sin apps" : profile.blockedApps.joined(separator: ", "))
                                .font(.caption).foregroundColor(.ascendTextSecondary).lineLimit(1)
                        }
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet { appState.deleteFocusProfile(appState.focusProfiles[index]) }
                }

                HStack {
                    TextField("Nuevo perfil (ej. Estudio)", text: $newProfileName)
                    Button("Crear") {
                        appState.addFocusProfile(FocusProfile(name: newProfileName))
                        newProfileName = ""
                    }
                    .disabled(newProfileName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }

            Section {
                Text("Las apps vitales (Teléfono, Mensajes, Cámara, Mapas) nunca se bloquean, y el botón “Desbloquear ahora” siempre está disponible durante una sesión.")
                    .font(.caption)
                    .foregroundColor(.ascendTextSecondary)
            }
        }
        .ascendListStyle()
        .navigationTitle("Enfoque y bloqueo")
    }
}

struct FocusProfileEditor: View {
    @Binding var profile: FocusProfile
    let options: [String]

    var body: some View {
        List {
            Section("Nombre") {
                TextField("Nombre", text: $profile.name)
            }
            Section("Apps a limitar") {
                ForEach(options, id: \.self) { app in
                    Button {
                        if let index = profile.blockedApps.firstIndex(of: app) {
                            profile.blockedApps.remove(at: index)
                        } else {
                            profile.blockedApps.append(app)
                        }
                    } label: {
                        HStack {
                            Text(app).foregroundColor(.ascendTextPrimary)
                            Spacer()
                            Image(systemName: profile.blockedApps.contains(app) ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(profile.blockedApps.contains(app) ? .ascendGold : .ascendGray)
                        }
                    }
                }
            }
        }
        .ascendListStyle()
        .navigationTitle(profile.name.isEmpty ? "Perfil" : profile.name)
    }
}

// MARK: - Privacidad

struct PrivacySettingsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showSetPIN = false
    @State private var newPIN = ""

    var body: some View {
        Form {
            Section("Datos") {
                Text("ASCEND guarda tu horario, hábitos, gastos, metas y preferencias solo en este dispositivo. No hay servidor ni terceros involucrados.")
                    .font(.footnote)
                    .foregroundColor(.ascendTextSecondary)
            }

            Section("Gastos") {
                Toggle("Bloquear sección con PIN", isOn: $appState.expensesPINEnabled)
                    .onChange(of: appState.expensesPINEnabled) { enabled in
                        if enabled && appState.expensesPIN.isEmpty { showSetPIN = true }
                    }
                if appState.expensesPINEnabled {
                    Button(appState.expensesPIN.isEmpty ? "Definir PIN" : "Cambiar PIN") { showSetPIN = true }
                }
                Text("Tus gastos nunca se comparten con terceros ni se usan para anuncios.")
                    .font(.footnote)
                    .foregroundColor(.ascendTextSecondary)
            }

            Section("Permisos") {
                Text("La app funciona aunque rechaces permisos opcionales como notificaciones.")
                    .font(.footnote)
                    .foregroundColor(.ascendTextSecondary)
            }
        }
        .ascendListStyle()
        .navigationTitle("Privacidad")
        .alert("PIN de 4 dígitos", isPresented: $showSetPIN) {
            SecureField("4 dígitos", text: $newPIN).keyboardType(.numberPad)
            Button("Guardar") {
                if newPIN.count == 4 { appState.expensesPIN = newPIN }
                if appState.expensesPIN.isEmpty { appState.expensesPINEnabled = false }
                newPIN = ""
            }
            Button("Cancelar", role: .cancel) {
                if appState.expensesPIN.isEmpty { appState.expensesPINEnabled = false }
            }
        }
    }
}
