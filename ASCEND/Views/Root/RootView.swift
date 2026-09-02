import SwiftUI

struct RootView: View {
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            TabView {
                HomeView()
                    .tabItem { Label("Hoy", systemImage: "sun.max") }
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
                .padding(.bottom, 70)
        }
        .tint(.ascendGold)
    }
}
