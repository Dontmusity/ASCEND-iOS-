# ASCEND — iOS (SwiftUI)

Implementación completa del doc de prompts (Prompt 1 + Prompt 2), con datos demo, sin backend real.

- Login (email + Apple/Google/Microsoft simulados) → onboarding conversacional → app.
- Home: carrusel de calendario por hora (Todo/Escuela/Gimnasio/Comida/Hobbies) + hasta 3 carruseles
  personalizados, crear eventos y asignarlos a cualquier carrusel, recordatorios.
- Hábitos: tracking por área, racha resiliente (no se borra por fallar), heatmap del mes, mejor racha.
- Enfoque: temporizador de micro-bloques, bloqueo de apps simulado con "Desbloquear ahora", apps
  vitales no bloqueables, medidor de uso (dato demo), frases motivacionales.
- Vida: to-dos por área con posponer sin penalización, gastos privados (ocultar montos, PIN,
  exportar CSV, borrar todo), recomendaciones de comida según intensidad de la semana, guía de
  trámites con checklist, tablón de reventa.
- Ascender (chatbot flotante): sugerencia según intensidad de la semana, límites éticos visibles.
- Perfil: notificaciones (frecuencia/horario silencioso, por carrusel), privacidad, referidos con
  código/compartir/paquetes no acumulables, comparación de planes Gratis/Pro con contador de días.
- Racha global (🔥) visible en la esquina superior derecha en toda la app.

## Cómo abrirlo (requiere Xcode en macOS)

Este entorno no tiene Xcode, así que no se generó un `.xcodeproj` a mano (alto riesgo de que
quede corrupto sin poder probarlo). En su lugar:

1. Abre Xcode → File → New → Project → iOS → App.
2. Nombre: `ASCEND`, Interface: SwiftUI, Language: Swift. Minimum iOS: 16.
3. Borra el `ContentView.swift` y `ASCEND[App].swift` que genera la plantilla.
4. Arrastra toda la carpeta `ASCEND/` de este repo al proyecto en Xcode (con "Copy items if needed").
5. Run.

## Qué se simplificó a propósito (queda pendiente si lo quieres más real)

- No hay backend (Supabase) ni OAuth real — todo el login social y la IA son simulados con reglas,
  tal como el doc permite si Supabase no está conectado.
- No hay persistencia entre lanzamientos (todo vive en memoria vía `AppState`); se resetea a los
  datos demo cada vez que corres la app. Si lo quieres, se agrega con `UserDefaults`/`Codable` fácil.
- El widget dinámico de hábitos en Home, el banner de anuncios/intersticial simulado, y el avatar
  evolutivo no están implementados todavía.
- Fechas del tracker de hábitos usan un modelo simplificado (día 1–30), no calendario real.
