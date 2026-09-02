import SwiftUI

/// La "A" ascendente de ASCEND, dibujada como vector: nunca se estira ni se pixelea,
/// se ve igual en cualquier tamaño y respeta dark mode.
struct AscendMark: View {
    var strokeColor: Color = .ascendGold
    var innerColor: Color = .ascendCream

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            ZStack {
                // Montaña / "A": dos trazos que suben a un pico redondeado.
                Path { path in
                    path.move(to: CGPoint(x: side * 0.13, y: side * 0.87))
                    path.addQuadCurve(
                        to: CGPoint(x: side * 0.50, y: side * 0.15),
                        control: CGPoint(x: side * 0.33, y: side * 0.52))
                    path.addQuadCurve(
                        to: CGPoint(x: side * 0.87, y: side * 0.87),
                        control: CGPoint(x: side * 0.67, y: side * 0.52))
                }
                .stroke(strokeColor, style: StrokeStyle(lineWidth: side * 0.15, lineCap: .round, lineJoin: .round))

                // Triángulo interior en la base.
                Path { path in
                    path.move(to: CGPoint(x: side * 0.50, y: side * 0.53))
                    path.addLine(to: CGPoint(x: side * 0.645, y: side * 0.85))
                    path.addLine(to: CGPoint(x: side * 0.355, y: side * 0.85))
                    path.closeSubpath()
                }
                .fill(innerColor)
            }
            .frame(width: side, height: side)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit) // proporción bloqueada: no se deforma nunca
        .accessibilityHidden(true)
    }
}

/// Versión en mosaico dorado, como el ícono de la app.
struct AscendLogoTile: View {
    var size: CGFloat = 72

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
            .fill(Color.ascendGold)
            .frame(width: size, height: size)
            .overlay(
                AscendMark(strokeColor: .white, innerColor: .ascendCream)
                    .padding(size * 0.18)
            )
            .accessibilityLabel("ASCEND")
    }
}

/// Logo horizontal completo: marca + nombre + tagline.
struct AscendWordmark: View {
    var markSize: CGFloat = 44
    var showTagline: Bool = true

    var body: some View {
        HStack(spacing: 12) {
            AscendMark(strokeColor: .ascendGray, innerColor: .ascendGold)
                .frame(width: markSize, height: markSize)

            VStack(alignment: .leading, spacing: 2) {
                Text("ASCEND")
                    .font(.system(size: markSize * 0.52, weight: .light))
                    .tracking(markSize * 0.14)
                    .foregroundColor(.ascendTextPrimary)
                if showTagline {
                    Text("PLAN. FOCUS. ACHIEVE.")
                        .font(.system(size: markSize * 0.19, weight: .semibold))
                        .tracking(markSize * 0.05)
                        .foregroundColor(.ascendGold)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("ASCEND. Plan, focus, achieve.")
    }
}
