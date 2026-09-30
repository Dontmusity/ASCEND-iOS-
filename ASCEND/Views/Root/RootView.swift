import SwiftUI

struct RootView: View {
    @EnvironmentObject private var appState: AppState

    enum Tab: Hashable { case today, habits, focus, life, profile }

    @State private var tab: Tab = .today

    /// Alto estándar de la tab bar de iOS. El FAB queda ~16 pt por encima, dentro del safe area.
    private let tabBarHeight: CGFloat = 49

    init() {
        // Activa en dorado (.tint abajo), inactiva en gris de marca.
        UITabBar.appearance().unselectedItemTintColor = UIColor(Color.ascendGray)
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            TabView(selection: $tab) {
                HomeView()
                    .tabItem { Label { Text("Hoy") } icon: { AscendMark.tabIcon } }
                    .tag(Tab.today)
                HabitsView()
                    .tabItem { Label("Hábitos", systemImage: "checkmark.seal") }
                    .tag(Tab.habits)
                FocusView()
                    .tabItem { Label("Enfoque", systemImage: "timer") }
                    .tag(Tab.focus)
                LifeView()
                    .tabItem { Label("Vida", systemImage: "leaf") }
                    .tag(Tab.life)
                ProfileView()
                    .tabItem { Label("Perfil", systemImage: "person.crop.circle") }
                    .tag(Tab.profile)
            }

            ChatbotButton()
                .padding(.trailing, 20)
                .padding(.bottom, tabBarHeight + 16)
        }
        .tint(.ascendGold)
        .onOpenURL(perform: handle)
    }

    /// Enlaces de los widgets, la pantalla de bloqueo y la isla dinámica (ver AscendLink).
    private func handle(_ url: URL) {
        switch url {
        case AscendLink.unlockFocus:
            // "Desbloquear" desde la Live Activity: siempre funciona, sin preguntar.
            appState.finishFocusSession()
            FocusLiveActivity.end()
            tab = .focus
        case AscendLink.focus:
            tab = .focus
        case AscendLink.habits:
            tab = .habits
        case AscendLink.today:
            tab = .today
        default:
            break
        }
    }
}
