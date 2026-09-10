import SwiftUI

// LEGAL: Todos los textos de este archivo son un borrador honesto de lo que la app hace hoy,
// NO son un documento legal certificado. Deben pasar por revisión de un abogado (México: LFPDPPP;
// EUA: CCPA/CPRA y demás leyes estatales aplicables) antes de publicar la app.

/// Encabezado + pie compartido por los tres documentos legales.
private struct LegalDocumentScaffold<Content: View>: View {
    let title: String
    let updated: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(title).font(.title2.bold()).foregroundColor(.ascendTextPrimary)
                Text("Última actualización: \(updated)")
                    .font(.caption).foregroundColor(.ascendTextSecondary)

                content()

                Divider().padding(.vertical, 4)
                Text("Borrador pendiente de revisión legal. No sustituye asesoría de un abogado.")
                    .font(.caption2)
                    .foregroundColor(.ascendTextSecondary)
            }
            .padding(20)
            .readableWidth()
        }
        .background(Color.ascendBackground.ignoresSafeArea())
    }
}

private struct LegalSection: View {
    let title: String
    let body_: String
    init(_ title: String, _ body: String) { self.title = title; self.body_ = body }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.headline).foregroundColor(.ascendTextPrimary)
            Text(body_).font(.subheadline).foregroundColor(.ascendTextSecondary)
        }
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        LegalDocumentScaffold(title: "Aviso de Privacidad", updated: "2026") {
            LegalSection("¿Quién trata tus datos?",
                // LEGAL: sustituir por razón social real, RFC y domicilio antes de publicar.
                "ASCEND (proyecto en desarrollo). Contacto: soporte@ascendapp.mx")

            LegalSection("¿Qué datos recolectamos?",
                "Nombre, universidad, horario de clases y entrenamientos, hábitos, metas, gastos personales que tú registras, y preferencias de notificaciones. No pedimos ni usamos tu ubicación GPS.")

            LegalSection("¿Dónde se guardan?",
                "Todo se queda en este dispositivo (no hay servidor ni backend conectado). No compartimos, vendemos ni usamos tus datos para publicidad de terceros.")

            LegalSection("¿Con qué fin los usamos?",
                "Únicamente para que ASCEND te muestre tu propia rutina, tus hábitos y tu progreso. No hay analítica de terceros ni rastreo publicitario en esta versión de la app.")

            LegalSection("Datos sensibles (salud/dinero)",
                "Tus datos de actividad física y gastos se consideran sensibles bajo la ley mexicana (LFPDPPP). ASCEND no da diagnósticos ni recomendaciones médicas, y tus gastos nunca se comparten ni se usan para anuncios.")

            LegalSection("Tus derechos (ARCO / acceso y borrado)",
                "Puedes Acceder a una copia de tus datos, Rectificarlos, Cancelarlos (borrar tu cuenta) u Oponerte a su uso, todo desde Perfil → Privacidad, sin tener que escribirnos. Si resides en California u otro estado de EUA con su propia ley de privacidad (CCPA/CPRA y similares), tienes derechos equivalentes de acceso y eliminación.")

            LegalSection("Menores de edad",
                "ASCEND está dirigido a mayores de 18 años. No solicitamos ni recolectamos intencionalmente datos de menores de 13 años (COPPA).")

            LegalSection("Cambios a este aviso",
                "Si este aviso cambia de forma importante, te lo notificaremos dentro de la app antes de que sigas usándola.")
        }
        .navigationTitle("Privacidad")
    }
}

struct TermsOfServiceView: View {
    var body: some View {
        LegalDocumentScaffold(title: "Términos y Condiciones de Uso", updated: "2026") {
            LegalSection("Qué es ASCEND",
                "Una app de organización personal y hábitos para estudiantes. No es una app médica, financiera ni de asesoría profesional: no reemplaza a un doctor, nutriólogo ni asesor financiero.")

            LegalSection("Cuenta y edad mínima",
                "Debes tener 18 años o más para usar ASCEND. Al continuar confirmas que cumples este requisito.")

            LegalSection("Uso permitido",
                "Debes usar ASCEND solo para fines personales y lícitos. No está permitido usar el tablón de reventa para publicar artículos ilegales o defraudar a otros usuarios.")

            LegalSection("Reventa estudiantil",
                "ASCEND únicamente conecta a estudiantes entre sí. No procesa pagos, no verifica a compradores/vendedores ni es responsable de la calidad, entrega o legalidad de lo publicado.")

            LegalSection("Suscripción Pro",
                "El plan mensual y anual son de renovación automática hasta que canceles. El precio y la duración se muestran antes de comprar. Puedes cancelar en cualquier momento desde los ajustes de tu cuenta de App Store; seguirás teniendo acceso Pro hasta el final del periodo ya pagado.")

            LegalSection("Referidos",
                "Las recompensas de días Pro por referidos se otorgan solo al llegar exactamente a cada umbral publicado dentro de la app; no son acumulables de forma proporcional.")

            LegalSection("Propiedad intelectual",
                // LEGAL: confirmar titularidad real del código/marca antes de publicar.
                "El nombre, logo y diseño de ASCEND son propiedad de sus desarrolladores. Tu contenido (tus datos, tus publicaciones de reventa) sigue siendo tuyo.")

            LegalSection("Limitación de responsabilidad",
                "ASCEND se ofrece \"tal cual\". No garantizamos que esté libre de errores. No somos responsables de decisiones que tomes basándote en los resúmenes o sugerencias de la app.")

            LegalSection("Cancelación de cuenta",
                "Puedes eliminar tu cuenta y todos tus datos locales en cualquier momento desde Perfil → Cuenta.")

            LegalSection("Ley aplicable",
                "Estos términos se interpretan conforme a las leyes de México, sin perjuicio de los derechos de protección al consumidor que te correspondan si resides en Estados Unidos.")
        }
        .navigationTitle("Términos de Uso")
    }
}

/// Pantalla única para cuentas que ya habían pasado onboarding antes de que este consentimiento
/// existiera: se les pide una sola vez, no se les manda de vuelta a todo el onboarding.
struct LegalConsentGateView: View {
    @EnvironmentObject private var appState: AppState
    @State private var ageConfirmed = false
    @State private var consentChecked = false
    @State private var showPrivacyPolicy = false
    @State private var showTerms = false

    var body: some View {
        VStack(spacing: 20) {
            AscendLogoTile(size: 52).padding(.top, 40)

            VStack(alignment: .leading, spacing: 14) {
                Text("Antes de seguir").font(.title2.bold()).foregroundColor(.ascendTextPrimary)
                Text("Actualizamos cómo te informamos sobre tus datos. Solo te lo pedimos una vez.")
                    .font(.subheadline).foregroundColor(.ascendTextSecondary)

                AscendOptionRow(label: "Confirmo que tengo 18 años o más", isSelected: ageConfirmed) {
                    ageConfirmed.toggle()
                }

                VStack(spacing: 8) {
                    Button("Leer Aviso de Privacidad") { showPrivacyPolicy = true }
                    Button("Leer Términos de Uso") { showTerms = true }
                }
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)

                Button { consentChecked.toggle() } label: {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: consentChecked ? "checkmark.square.fill" : "square")
                            .foregroundColor(consentChecked ? .ascendGold : .ascendGray)
                        Text("He leído y acepto el Aviso de Privacidad y los Términos de Uso.")
                            .font(.subheadline)
                            .foregroundColor(.ascendTextPrimary)
                            .multilineTextAlignment(.leading)
                    }
                }
                .buttonStyle(.plain)
                .padding(12)
                .background(Color.ascendCard)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 24)

            Spacer()

            Button("Continuar") {
                appState.ageConfirmed18Plus = true
                appState.legalAccepted = true
                appState.legalAcceptedDate = Date()
            }
            .font(.headline)
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(ageConfirmed && consentChecked ? Color.ascendGold : Color.ascendGray.opacity(0.4))
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .disabled(!(ageConfirmed && consentChecked))
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
        .background(Color.ascendBackground.ignoresSafeArea())
        .sheet(isPresented: $showPrivacyPolicy) { NavigationStack { PrivacyPolicyView() } }
        .sheet(isPresented: $showTerms) { NavigationStack { TermsOfServiceView() } }
    }
}

struct LegalNoticeView: View {
    var body: some View {
        LegalDocumentScaffold(title: "Aviso Legal", updated: "2026") {
            // LEGAL: completar con datos fiscales/domicilio reales antes de publicar en las tiendas.
            LegalSection("Responsable", "ASCEND (proyecto en desarrollo, sin razón social registrada todavía).")
            LegalSection("Contacto", "soporte@ascendapp.mx")
            LegalSection("Ubicación", "México")
            LegalSection("Librerías de terceros", "ASCEND no usa librerías, SDKs de analítica ni servicios de terceros en esta versión: es 100% SwiftUI y frameworks del sistema de Apple.")
        }
        .navigationTitle("Aviso Legal")
    }
}
