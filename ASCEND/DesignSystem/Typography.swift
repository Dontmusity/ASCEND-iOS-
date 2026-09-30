import SwiftUI
import UIKit

/// Solo fuentes del sistema: SF Rounded para títulos y números, SF Pro para el cuerpo.
/// Los tamaños son los del diseño y crecen con Dynamic Type relativos a un estilo de texto.
extension Font {
    // ponytail: la escala se calcula al pintar; si cambia Dynamic Type con la app abierta,
    // se aplica en el siguiente redibujado. Pasar a @ScaledMetric por vista si eso molesta.
    static func ascendRounded(_ size: CGFloat, _ weight: Font.Weight = .semibold,
                              relativeTo style: UIFont.TextStyle = .body) -> Font {
        .system(size: UIFontMetrics(forTextStyle: style).scaledValue(for: size), weight: weight, design: .rounded)
    }

    /// 52 / semibold: la cifra protagonista (18/30, timer).
    static var ascendDisplay: Font { ascendRounded(52, relativeTo: .largeTitle) }
    /// 30 / semibold: saludo en Hoy.
    static var ascendTitleXL: Font { ascendRounded(30, relativeTo: .largeTitle) }
    /// 26 / semibold: título de pantalla.
    static var ascendTitleL: Font { ascendRounded(26, relativeTo: .title) }
    /// 20 / semibold: título de la tarjeta destacada.
    static var ascendTitleM: Font { ascendRounded(20, relativeTo: .title3) }
    /// 18–34 / semibold: cifras en tarjetas y anillos.
    static func ascendNumber(_ size: CGFloat) -> Font { ascendRounded(size, relativeTo: .title2) }
    /// 11 / semibold: etiqueta sobre cada sección. Se usa con `.tracking(2)` y en mayúsculas (ver AscendKicker).
    static var ascendKicker: Font {
        .system(size: UIFontMetrics(forTextStyle: .caption2).scaledValue(for: 11), weight: .semibold)
    }
}
