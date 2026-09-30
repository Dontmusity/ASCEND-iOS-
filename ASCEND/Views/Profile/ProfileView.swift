import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var appState: AppState

    // Datos vivos para los subtítulos de cada fila (derivados, sin tocar AppState).
    private var classesTodayText: String {
        let count = appState.classes(on: .today).count
        return count == 1 ? "1 clase hoy" : "\(count) clases hoy"
    }

    private var trainingText: String {
        let days = Set(appState.workouts.flatMap(\.days) + appState.sports.flatMap(\.days)).count
        return days == 0 ? appState.activityKind.rawValue : "\(days) días por semana"
    }

    private var activitiesText: String {
        let lanes = appState.customLanes.count
        if lanes > 0 { return lanes == 1 ? "1 carrusel" : "\(lanes) carruseles" }
        let count = appState.customActivities.count
        return count == 1 ? "1 actividad" : "\(count) actividades"
    }

    private var planDetail: String {
        if appState.isPro, let until = appState.subscription.expirationDate {
            return "hasta \(until.formatted(date: .abbreviated, time: .omitted))"
        }
        return "con anuncios"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        AscendKicker(text: "Perfil")
                        Spacer()
                        StreakBadge()
                    }
                    .padding(.top, 6)

                    identity

                    AscendKicker(text: "Mi rutina").padding(.top, 20)
                    groupedCard {
                        link(icon: "graduationcap", title: "Escuela y horario", subtitle: classesTodayText,
                             color: CalendarLane.school.accentColor) { EditScheduleView() }
                        divider
                        link(icon: "figure.strengthtraining.traditional", title: "Entrenamiento y deporte",
                             subtitle: trainingText, color: CalendarLane.gym.accentColor) { EditTrainingView() }
                        divider
                        link(icon: "fork.knife", title: "Comidas y objetivo", subtitle: appState.physicalGoal.shortLabel,
                             color: CalendarLane.food.accentColor) { EditMealsView() }
                        divider
                        link(icon: "list.bullet", title: "Actividades personalizadas", subtitle: activitiesText,
                             color: CalendarLane.hobbies.accentColor) { EditActivitiesView() }
                    }

                    planCard

                    AscendKicker(text: "Ajustes").padding(.top, 20)
                    groupedCard {
                        link(icon: "bell", title: "Notificaciones",
                             subtitle: "Máximo \(appState.notificationPrefs.maxPerDay) al día") { NotificationsSettingsView() }
                        divider
                        link(icon: "timer", title: "Enfoque y bloqueo de apps",
                             subtitle: appState.focusProfiles.count == 1 ? "1 perfil" : "\(appState.focusProfiles.count) perfiles") {
                            FocusSettingsView()
                        }
                        divider
                        link(icon: "shield", title: "Privacidad", subtitle: "Todo se queda en tu teléfono") { PrivacySettingsView() }
                    }

                    // Lo legal y la cuenta bajan a una línea al pie, fuera del recorrido principal.
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 14) {
                            footerLink("Cuenta") { AccountSettingsView() }
                            footerLink("Aviso de Privacidad") { PrivacyPolicyView() }
                            footerLink("Términos de Uso") { TermsOfServiceView() }
                            footerLink("Aviso Legal") { LegalNoticeView() }
                        }
                    }
                    .padding(.top, 8)

                    #if DEBUG
                    Button("Cargar datos de ejemplo") { appState.loadSampleData() }
                        .font(.footnote)
                        .foregroundColor(.ascendTextSecondary)
                        .frame(minHeight: 44)
                    #endif
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 90) // deja libre el FAB
                .readableWidth()
            }
            .background(Color.ascendBackground.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var identity: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(Color.ascendSurface)
                .frame(width: 58, height: 58)
                .overlay(
                    Text(String(appState.profile.name.prefix(1)).uppercased())
                        .font(.ascendNumber(24))
                        .foregroundColor(.ascendOnSurface)
                        .minimumScaleFactor(0.5))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(appState.profile.name.isEmpty ? "Tu perfil" : appState.profile.name)
                    .font(.ascendRounded(22, relativeTo: .title2))
                    .foregroundColor(.ascendTextPrimary)
                Text([appState.education.summary, appState.profile.university]
                        .filter { !$0.isEmpty }.joined(separator: " · "))
                    .font(.footnote)
                    .foregroundColor(.ascendTextSecondary)
            }
        }
        .padding(.top, 12)
    }

    /// "Tu plan" es la única pieza en ascendSurface de la pantalla.
    private var planCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 0) {
                    AscendKicker(text: "Tu plan", color: .ascendOnSurfaceTertiary)
                    Text(appState.subscription.label)
                        .font(.ascendRounded(18, relativeTo: .headline))
                        .foregroundColor(.ascendOnSurface)
                        .padding(.top, 7)
                    Text(planDetail)
                        .font(.caption)
                        .foregroundColor(.ascendOnSurfaceSecondary)
                        .padding(.top, 3)
                }
                Spacer()
                NavigationLink { UpgradeView() } label: {
                    Text(appState.isPro ? "Suscripción" : "Ver Pro")
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(.ascendOnGold)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 9)
                        .background(Capsule().fill(Color.ascendGold))
                        .frame(minHeight: 44)
                }
                .buttonStyle(AscendPressStyle())
            }
            NavigationLink { ReferralsView() } label: {
                HStack(spacing: 6) {
                    Image(systemName: "person.2")
                    Text("Invita amigos y gana Pro")
                    Spacer()
                    Image(systemName: "chevron.right").font(.caption.weight(.semibold))
                }
                .font(.footnote.weight(.medium))
                .foregroundColor(.ascendOnSurfaceSecondary)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 18)
        .padding(.top, 14)
        .padding(.bottom, 4)
        .ascendSurfaceCard(cornerRadius: 20)
        .padding(.top, 16)
    }

    // MARK: Piezas

    private var divider: some View {
        Rectangle().fill(Color.ascendHairline).frame(height: 1)
    }

    private func groupedCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) { content() }
            .ascendCard(cornerRadius: 20)
            .padding(.top, 11)
    }

    private func link<Destination: View>(icon: String, title: String, subtitle: String,
                                         color: Color = .ascendGray,
                                         @ViewBuilder destination: @escaping () -> Destination) -> some View {
        NavigationLink(destination: destination) {
            AscendAreaRow(icon: icon, title: title, subtitle: subtitle, color: color)
        }
        .buttonStyle(.plain)
    }

    private func footerLink<Destination: View>(_ title: String,
                                               @ViewBuilder destination: @escaping () -> Destination) -> some View {
        NavigationLink(destination: destination) {
            Text(title)
                .font(.caption)
                .foregroundColor(.ascendTextSecondary)
                .frame(minHeight: 44)
        }
        .buttonStyle(.plain)
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
    @State private var showDataExport = false

    /// Acciones que abren la puerta a los gastos: si ya hay PIN, primero se pide el actual.
    private enum ProtectedAction { case disablePIN, changePIN, exportData }
    @State private var pendingAction: ProtectedAction? = nil
    @State private var currentPIN = ""
    @State private var wrongPIN = false

    private var isLocked: Bool {
        appState.expensesPINEnabled && !appState.expensesPIN.isEmpty && !appState.expensesUnlockedThisSession
    }

    private func requirePIN(_ action: ProtectedAction) {
        if isLocked { pendingAction = action } else { perform(action) }
    }

    private func perform(_ action: ProtectedAction) {
        switch action {
        case .disablePIN: appState.expensesPINEnabled = false
        case .changePIN: showSetPIN = true
        case .exportData: showDataExport = true
        }
    }

    var body: some View {
        Form {
            Section("Datos") {
                Text("ASCEND guarda tu horario, hábitos, gastos, metas y preferencias solo en este dispositivo. No hay servidor ni terceros involucrados.")
                    .font(.footnote)
                    .foregroundColor(.ascendTextSecondary)
            }

            Section {
                Button("Solicitar mis datos") { requirePIN(.exportData) }
                NavigationLink("Aviso de Privacidad") { PrivacyPolicyView() }
            } header: {
                Text("Tus derechos (ARCO / CCPA)")
            } footer: {
                Text("Puedes acceder, rectificar, cancelar u oponerte al uso de tus datos. \"Eliminar cuenta\" en Perfil → Cuenta es tu derecho de cancelación; aquí puedes ver y exportar todo lo que ASCEND tiene guardado de ti.")
            }

            Section("Gastos") {
                // Encender el PIN es libre; apagarlo pide el PIN actual para que no se pueda saltar.
                Toggle("Bloquear sección con PIN", isOn: Binding(
                    get: { appState.expensesPINEnabled },
                    set: { enabled in
                        if enabled {
                            appState.expensesPINEnabled = true
                            if appState.expensesPIN.isEmpty { showSetPIN = true }
                        } else {
                            requirePIN(.disablePIN)
                        }
                    }))
                if appState.expensesPINEnabled {
                    Button(appState.expensesPIN.isEmpty ? "Definir PIN" : "Cambiar PIN") {
                        if appState.expensesPIN.isEmpty { showSetPIN = true } else { requirePIN(.changePIN) }
                    }
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
                newPIN = ""
            }
        }
        .alert("Escribe tu PIN actual", isPresented: Binding(
            get: { pendingAction != nil },
            set: { if !$0 { pendingAction = nil } })
        ) {
            SecureField("4 dígitos", text: $currentPIN).keyboardType(.numberPad)
            Button("Continuar") {
                let action = pendingAction
                pendingAction = nil
                if appState.unlockExpenses(withPIN: currentPIN), let action {
                    perform(action)
                } else {
                    wrongPIN = true
                }
                currentPIN = ""
            }
            Button("Cancelar", role: .cancel) { currentPIN = "" }
        } message: {
            Text("Tus gastos están protegidos con PIN.")
        }
        .alert("PIN incorrecto", isPresented: $wrongPIN) {
            Button("OK", role: .cancel) {}
        }
        .sheet(isPresented: $showDataExport) { DataExportView() }
    }
}

/// Derecho de acceso/portabilidad: todo lo que ASCEND sabe de ti, legible y exportable.
struct DataExportView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(appState.exportAllDataJSON())
                    .font(.system(.footnote, design: .monospaced))
                    .textSelection(.enabled)
                    .padding()
            }
            .navigationTitle("Tus datos")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cerrar") { dismiss() } }
                ToolbarItem(placement: .primaryAction) {
                    ShareLink(item: appState.exportAllDataJSON()) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
    }
}
