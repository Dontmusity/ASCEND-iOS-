import SwiftUI

struct RootView: View {
    /// Alto estándar de la tab bar de iOS. El FAB queda ~16 pt por encima, dentro del safe area.
    private let tabBarHeight: CGFloat = 49

    init() {
        // Activa en dorado (.tint abajo), inactiva en gris de marca.
        UITabBar.appearance().unselectedItemTintColor = UIColor(Color.ascendGray)
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            TabView {
                HomeView()
                    .tabItem { Label { Text("Hoy") } icon: { AscendMark.tabIcon } }
                HabitsView()
                    .tabItem { Label("Hábitos", systemImage: "checkmark.seal") }
                FocusView()
                    .tabItem { Label("Enfoque", systemImage: "timer") }
                LifeView()
                    .tabItem { Label("Vida", systemImage: "leaf") }
                ProfileView()
                    .tabItem { Label("Perfil", systemImage: "person.crop.circle") }
            }

            ChatbotButton()
                .padding(.trailing, 20)
                .padding(.bottom, tabBarHeight + 16)
        }
        .tint(.ascendGold)
    }
}
