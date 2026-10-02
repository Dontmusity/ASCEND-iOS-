import SwiftUI

// El color de cada área sale del modelo: se reutilizan los colores de CalendarLane
// (Escuela #C9A15A, Gimnasio #A8785A, Comida #8FA173, Hobbies #9E8AA8, Todo = dorado).
// Hábitos y Vida no tienen color propio en el modelo, así que se les asigna el carril más cercano.

extension HabitArea {
    var tint: Color {
        switch self {
        case .study: return CalendarLane.school.accentColor
        case .health: return CalendarLane.gym.accentColor
        case .wellbeing: return CalendarLane.food.accentColor
        case .home: return CalendarLane.hobbies.accentColor
        case .money: return CalendarLane.all.accentColor
        }
    }
}

extension LifeArea {
    var tint: Color {
        switch self {
        case .school: return CalendarLane.school.accentColor
        case .home: return CalendarLane.food.accentColor
        case .personal: return CalendarLane.gym.accentColor
        case .procedures: return CalendarLane.hobbies.accentColor
        case .money: return CalendarLane.all.accentColor
        }
    }

    var icon: String {
        switch self {
        case .school: return "graduationcap"
        case .home: return "house"
        case .money: return "banknote"
        case .procedures: return "doc.text"
        case .personal: return "heart"
        }
    }
}
