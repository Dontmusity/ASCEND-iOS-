import SwiftUI

extension Color {
    static let ascendGold = Color(hex: "E8BC75")
    static let ascendCream = Color(hex: "FCE4CA")
    static let ascendGray = Color(hex: "9EA196") // solo para bordes/inactivo, no pasa contraste como texto
    static let ascendBackground = Color(hex: "FFFCF8")
    static let ascendCard = Color.white
    static let ascendTextPrimary = Color(hex: "2B2A26")
    static let ascendTextSecondary = Color(hex: "6B6E63") // mismo tono que ascendGray pero AA-legible como texto

    init(hex: String) {
        var hexValue: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&hexValue)
        let r = Double((hexValue >> 16) & 0xFF) / 255
        let g = Double((hexValue >> 8) & 0xFF) / 255
        let b = Double(hexValue & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
