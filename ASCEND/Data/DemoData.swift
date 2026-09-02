import Foundation

/// Contenido de la app (no datos inventados del usuario): guías de trámites, frases y
/// configuración de recompensas. La rutina del usuario siempre viene de lo que él configura.
enum DemoData {

    static let motivationalPhrases: [String] = [
        "Un mal día no borra tu camino.",
        "Vas a tu propio ritmo, y está bien.",
        "Pequeños pasos también cuentan como avance.",
        "Hoy puedes ir más despacio, mañana sigues aquí.",
        "Lo que ya lograste no desaparece.",
        "No se trata de hacer todo, se trata de seguir.",
        "Está bien pausar. Retomas cuando puedas.",
        "Tu esfuerzo de hoy también cuenta, aunque sea poco.",
        "Avanzar despacio sigue siendo avanzar.",
        "Mereces el mismo descanso que le das a los demás."
    ]

    /// Biblioteca de trámites: contenido informativo de la app, igual para todos.
    static let tramites: [TramiteGuide] = [
        TramiteGuide(title: "Solicitar beca",
                     steps: ["Reunir documentos", "Llenar formulario en línea", "Entregar en ventanilla", "Esperar resolución"]),
        TramiteGuide(title: "Credencial de estudiante",
                     steps: ["Tomarse foto oficial", "Pagar cuota", "Recoger credencial"]),
        TramiteGuide(title: "Abrir cuenta bancaria",
                     steps: ["Elegir banco", "Agendar cita", "Llevar INE y comprobante", "Activar app"]),
        TramiteGuide(title: "Credencial de transporte",
                     steps: ["Llenar solicitud", "Pagar", "Recoger tarjeta"])
    ]

    static let vitalApps: [String] = ["Teléfono", "Mensajes", "WhatsApp", "Cámara", "Mapas"]

    /// Paquetes cerrados, no acumulables: 1 → 1 semana, 10 → 5 meses, 20 → 1 año.
    static let referralTiers: [ReferralTier] = [
        ReferralTier(count: 1, rewardDays: 7, label: "1 semana Pro"),
        ReferralTier(count: 10, rewardDays: 150, label: "5 meses Pro"),
        ReferralTier(count: 20, rewardDays: 365, label: "1 año Pro")
    ]
}
