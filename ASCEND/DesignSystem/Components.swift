import SwiftUI

// MARK: - Modificadores

extension View {
    /// Tarjeta normal: fondo ascendCard, borde ascendLine de 1 pt y sin sombra.
    func ascendCard(cornerRadius: CGFloat = 18) -> some View {
        background(Color.ascendCard)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(Color.ascendHairline, lineWidth: 1))
    }

    /// La única pieza destacada de cada pantalla. El texto encima va en `ascendOnSurface*`.
    func ascendSurfaceCard(cornerRadius: CGFloat = 22) -> some View {
        background(Color.ascendSurface)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    /// Tinte de área: relleno del color al `fill` encima de ascendCard + barra izquierda de 3 pt al 100 %.
    func areaTint(_ color: Color, fill: Double = 0.12, cornerRadius: CGFloat = 18, bordered: Bool = true) -> some View {
        background(ZStack { Color.ascendCard; color.opacity(fill) })
            .overlay(alignment: .leading) { color.frame(width: 3) }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(bordered ? Color.ascendHairline : .clear, lineWidth: 1))
    }

    /// Sombra dorada suave. Solo para el FAB y los CTAs dorados; las tarjetas no llevan sombra.
    func goldGlow() -> some View {
        shadow(color: Color.ascendGold.opacity(0.45), radius: 10, y: 8)
    }
}

// MARK: - Estilos de botón

/// Escala a 0.97 al presionar (sin animación con Reduce Motion).
struct AscendPressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// CTA principal: píldora dorada con texto oscuro y sombra dorada.
struct AscendPrimaryButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundColor(.ascendOnGold)
            .padding(.horizontal, 26)
            .frame(minHeight: 50)
            .background(Capsule().fill(Color.ascendGold))
            .goldGlow()
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// Acción secundaria en píldora con borde (Cerrar, Posponer, Desbloquear).
struct AscendPillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.footnote.weight(.medium))
            .foregroundColor(.ascendTextSecondary)
            .padding(.horizontal, 13)
            .padding(.vertical, 6)
            .overlay(Capsule().stroke(Color.ascendHairline, lineWidth: 1))
            .contentShape(Capsule())
            .opacity(configuration.isPressed ? 0.6 : 1)
            .frame(minHeight: 44)
    }
}

// MARK: - Kicker

/// Etiqueta en mayúsculas con tracking sobre cada sección (`HÁBITOS`, `AHORA`).
struct AscendKicker: View {
    let text: String
    var color: Color = .ascendGray

    var body: some View {
        Text(text.uppercased())
            .font(.ascendKicker)
            .tracking(2)
            .foregroundColor(color)
            .accessibilityAddTraits(.isHeader)
    }
}

/// Kicker de sección con el punto del color del área.
struct AscendAreaKicker: View {
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 7) {
            Circle().fill(color).frame(width: 7, height: 7).accessibilityHidden(true)
            AscendKicker(text: text)
        }
    }
}

// MARK: - Chip

/// Píldora con ícono y nombre. La activa se rellena con el color del área (Todo = dorado).
struct AscendChip: View {
    let icon: String?
    let title: String
    let color: Color
    let isActive: Bool
    let showsTitle: Bool
    let dashed: Bool
    let namespace: Namespace.ID?
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(icon: String?, title: String, color: Color = .ascendGold, isActive: Bool = false,
         showsTitle: Bool = true, dashed: Bool = false, namespace: Namespace.ID? = nil,
         action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.color = color
        self.isActive = isActive
        self.showsTitle = showsTitle
        self.dashed = dashed
        self.namespace = namespace
        self.action = action
    }

    var body: some View {
        Button {
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) { action() }
        } label: {
            HStack(spacing: 6) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(isActive ? .ascendOnGold : (dashed ? .ascendGray : color))
                }
                if showsTitle {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(isActive ? .ascendOnGold : .ascendTextSecondary)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, showsTitle ? 14 : 10)
            .frame(minWidth: 34, minHeight: 34)
            .background { chipBackground }
            .padding(.vertical, 5)
            .contentShape(Rectangle())
        }
        .buttonStyle(AscendPressStyle())
        .accessibilityLabel(title)
        .accessibilityAddTraits(isActive ? .isSelected : [])
    }

    @ViewBuilder private var chipBackground: some View {
        if isActive {
            if let namespace {
                Capsule().fill(color).matchedGeometryEffect(id: "ascend.chip", in: namespace)
            } else {
                Capsule().fill(color)
            }
        } else if dashed {
            Capsule().strokeBorder(Color.ascendLine.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
        } else {
            Capsule().fill(Color.ascendCard).overlay(Capsule().stroke(Color.ascendHairline, lineWidth: 1))
        }
    }
}

// MARK: - Segmented

/// Selector en píldora con el activo sobre ascendSurface (Día / Semana / Mes).
struct AscendSegmented<Option: Hashable>: View {
    let options: [Option]
    @Binding var selection: Option
    let label: (Option) -> String

    @Namespace private var namespace
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(options: [Option], selection: Binding<Option>, label: @escaping (Option) -> String) {
        self.options = options
        self._selection = selection
        self.label = label
    }

    var body: some View {
        HStack(spacing: 2) {
            ForEach(options, id: \.self) { option in
                let isActive = option == selection
                Button {
                    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) { selection = option }
                } label: {
                    Text(label(option))
                        .font(.footnote.weight(isActive ? .semibold : .medium))
                        .foregroundColor(isActive ? .ascendOnSurface : .ascendTextSecondary)
                        .padding(.horizontal, 13)
                        .padding(.vertical, 6)
                        .background {
                            if isActive {
                                Capsule().fill(Color.ascendSurface)
                                    .matchedGeometryEffect(id: "ascend.segment", in: namespace)
                            }
                        }
                        // Zona táctil de 44 pt sin agrandar la píldora visible.
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                        .padding(.vertical, -8)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isActive ? .isSelected : [])
            }
        }
        .padding(3)
        .background(Capsule().fill(Color.ascendCard))
        .overlay(Capsule().stroke(Color.ascendHairline, lineWidth: 1))
    }
}

// MARK: - Anillo y barra

/// Anillo con punta redondeada; anima al cambiar (sin animación con Reduce Motion).
/// Sin estado interno, así que también se dibuja bien dentro de un widget.
struct AscendRing<Label: View>: View {
    let progress: Double
    let color: Color
    let track: Color
    let lineWidth: CGFloat
    let label: Label

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(progress: Double, color: Color = .ascendGold, track: Color = .ascendHairline,
         lineWidth: CGFloat = 8, @ViewBuilder label: () -> Label) {
        self.progress = progress
        self.color = color
        self.track = track
        self.lineWidth = lineWidth
        self.label = label()
    }

    var body: some View {
        ZStack {
            Circle().stroke(track, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(reduceMotion ? nil : .easeOut(duration: 0.6), value: progress)
            label
        }
        .padding(lineWidth / 2)
    }
}

extension AscendRing where Label == EmptyView {
    init(progress: Double, color: Color = .ascendGold, track: Color = .ascendHairline, lineWidth: CGFloat = 8) {
        self.init(progress: progress, color: color, track: track, lineWidth: lineWidth) { EmptyView() }
    }
}

/// Barra de progreso redondeada de 4–6 pt.
struct AscendProgressBar: View {
    let progress: Double
    let color: Color
    let track: Color
    let height: CGFloat
    let rounded: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(progress: Double, color: Color = .ascendGold, track: Color = .ascendHairline,
         height: CGFloat = 5, rounded: Bool = true) {
        self.progress = progress
        self.color = color
        self.track = track
        self.height = height
        self.rounded = rounded
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: rounded ? height / 2 : 0).fill(track)
                RoundedRectangle(cornerRadius: rounded ? height / 2 : 0)
                    .fill(color)
                    .frame(width: geo.size.width * min(max(progress, 0), 1))
                    .animation(reduceMotion ? nil : .easeOut(duration: 0.6), value: progress)
            }
        }
        .frame(height: height)
        .accessibilityHidden(true)
    }
}

// MARK: - Check

/// Check circular. Al marcarse hace pop (1 → 1.28 → 1) y vibra con éxito.
struct AscendCheck: View {
    let isOn: Bool
    let size: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var popped = false

    init(isOn: Bool, size: CGFloat = 28) {
        self.isOn = isOn
        self.size = size
    }

    var body: some View {
        ZStack {
            if isOn {
                Circle().fill(Color.ascendGold)
                Image(systemName: "checkmark")
                    .font(.system(size: size * 0.42, weight: .bold))
                    .foregroundColor(.white)
            } else {
                Circle().strokeBorder(Color.ascendGray, lineWidth: 1.9)
            }
        }
        .frame(width: size, height: size)
        .scaleEffect(popped ? 1.28 : 1)
        .onChange(of: isOn) { _, isOn in
            guard isOn, !reduceMotion else { return }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) { popped = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) { popped = false }
            }
        }
        .sensoryFeedback(.success, trigger: isOn) { _, isOn in isOn }
        .accessibilityHidden(true)
    }
}

// MARK: - Heatmap

/// Rejilla de 10 columnas con 3 niveles: 0 vacío, 1 al 55 % dorado, 2 dorado completo.
struct AscendHeatmap: View {
    let levels: [Int]
    var cellHeight: CGFloat = 16
    var spacing: CGFloat = 5
    var emptyColor: Color = Color.ascendOnSurface.opacity(0.10)

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: spacing), count: 10), spacing: spacing) {
            ForEach(Array(levels.enumerated()), id: \.offset) { _, level in
                RoundedRectangle(cornerRadius: cellHeight * 0.32, style: .continuous)
                    .fill(Self.color(for: level, empty: emptyColor))
                    .frame(height: cellHeight)
            }
        }
    }

    static func color(for level: Int, empty: Color) -> Color {
        switch level {
        case 2: return .ascendGold
        case 1: return Color.ascendGold.opacity(0.55)
        default: return empty
        }
    }
}

/// Leyenda "menos … más" del heatmap.
struct AscendHeatmapLegend: View {
    var textColor: Color = .ascendOnSurfaceTertiary
    var emptyColor: Color = Color.ascendOnSurface.opacity(0.10)

    var body: some View {
        HStack(spacing: 6) {
            Text("menos").font(.caption2).foregroundColor(textColor)
            ForEach(0..<3, id: \.self) { level in
                RoundedRectangle(cornerRadius: 3)
                    .fill(AscendHeatmap.color(for: level, empty: emptyColor))
                    .frame(width: 10, height: 10)
            }
            Text("más").font(.caption2).foregroundColor(textColor)
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Fila de área

/// Fila con ícono en cuadro tintado, título, dato vivo opcional y chevron.
struct AscendAreaRow: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    var color: Color = .ascendGray

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(color.opacity(0.16))
                .frame(width: 30, height: 30)
                .overlay(Image(systemName: icon).font(.system(size: 14, weight: .medium)).foregroundColor(color))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.body.weight(.medium)).foregroundColor(.ascendTextPrimary)
                if let subtitle {
                    Text(subtitle).font(.caption).foregroundColor(.ascendTextSecondary)
                }
            }
            Spacer(minLength: 8)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundColor(.ascendGray)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .frame(minHeight: 44)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Estado vacío

/// Montaña vectorial con horizonte; la cima es el triángulo dorado del logo.
struct AscendEmptyState: View {
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 0) {
            MountainIllustration()
                .frame(width: 188, height: 112)
                .accessibilityHidden(true)
            Text(title)
                .font(.ascendRounded(21, relativeTo: .title3))
                .foregroundColor(.ascendTextPrimary)
                .multilineTextAlignment(.center)
                .padding(.top, 30)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.ascendTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.top, 10)
            if let actionTitle, let action {
                Button(action: action) {
                    Label(actionTitle, systemImage: "plus")
                }
                .buttonStyle(AscendPrimaryButtonStyle())
                .padding(.top, 26)
            }
        }
        .padding(.horizontal, 44)
        .frame(maxWidth: .infinity)
    }
}

/// Dibujo en coordenadas del lienzo de 188 × 112 del diseño.
private struct MountainIllustration: View {
    var body: some View {
        ZStack {
            Circle().fill(Color.ascendSurface).frame(width: 26, height: 26).position(x: 140, y: 26)
            Path { p in
                p.move(to: CGPoint(x: 4, y: 92))
                p.addLine(to: CGPoint(x: 52, y: 30))
                p.addLine(to: CGPoint(x: 86, y: 74))
                p.addLine(to: CGPoint(x: 108, y: 46))
                p.addLine(to: CGPoint(x: 152, y: 92))
                p.closeSubpath()
            }
            .stroke(Color.ascendGray.opacity(0.55), style: StrokeStyle(lineWidth: 2.4, lineJoin: .round))
            Path { p in
                p.move(to: CGPoint(x: 52, y: 30))
                p.addLine(to: CGPoint(x: 70, y: 53))
                p.addLine(to: CGPoint(x: 34, y: 53))
                p.closeSubpath()
            }
            .fill(Color.ascendGold.opacity(0.9))
            Path { p in
                p.move(to: CGPoint(x: 0, y: 99.5))
                p.addLine(to: CGPoint(x: 188, y: 99.5))
            }
            .stroke(Color.ascendGray.opacity(0.35), style: StrokeStyle(lineWidth: 2.4, lineCap: .round))
            Path { p in
                p.move(to: CGPoint(x: 164, y: 92))
                p.addLine(to: CGPoint(x: 176, y: 74))
                p.addLine(to: CGPoint(x: 188, y: 92))
            }
            .stroke(Color.ascendGray.opacity(0.3), style: StrokeStyle(lineWidth: 2.4, lineJoin: .round))
        }
        .frame(width: 188, height: 112)
    }
}
