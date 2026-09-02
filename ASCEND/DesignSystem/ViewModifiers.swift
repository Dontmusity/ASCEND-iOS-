import SwiftUI

extension View {
    /// En iPad/pantallas grandes evita que las tarjetas se estiren de borde a borde: limita el
    /// ancho de contenido y lo centra, dejando que el fondo siga llenando toda la pantalla.
    func readableWidth() -> some View {
        self
            .frame(maxWidth: 700)
            .frame(maxWidth: .infinity, alignment: .center)
    }

    /// Quita el gris de sistema por defecto de List/Form para que respeten el fondo de marca.
    func ascendListStyle() -> some View {
        self
            .scrollContentBackground(.hidden)
            .background(Color.ascendBackground)
    }
}
