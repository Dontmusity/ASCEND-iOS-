import SwiftUI

extension Color {
    // Paleta de marca (fija, no cambia entre modos)
    static let ascendGold = Color(hex: "E8BC75")
    static let ascendCream = Color(hex: "FCE4CA")
    static let ascendGray = Color(hex: "9EA196") // bordes/inactivo, no pasa contraste como texto

    // Superficies y texto: adaptativos para que dark mode funcione de verdad
    static let ascendBackground = Color.adaptive(light: "FFFCF8", dark: "141310")
    static let ascendCard = Color.adaptive(light: "FFFFFF", dark: "1F1D19")
    static let ascendSurface = Color.adaptive(light: "FCE4CA", dark: "2A241B")
    static let ascendTextPrimary = Color.adaptive(light: "2B2A26", dark: "F5F1EA")
    static let ascendTextSecondary = Color.adaptive(light: "6B6E63", dark: "B4B7AC")

    init(hex: String) {
        var hexValue: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&hexValue)
        let r = Double((hexValue >> 16) & 0xFF) / 255
        let g = Double((hexValue >> 8) & 0xFF) / 255
        let b = Double(hexValue & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }

    static func adaptive(light: String, dark: String) -> Color {
        Color(UIColor { traits in
            UIColor(Color(hex: traits.userInterfaceStyle == .dark ? dark : light))
        })
    }
}
