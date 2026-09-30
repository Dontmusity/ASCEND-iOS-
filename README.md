# ASCEND — iOS (SwiftUI)

Implementación completa del doc de prompts (Prompt 1 + Prompt 2) sin backend real, con el rediseño
visual del handoff "Pulido visual" (design system propio, SF Rounded, color por área, dark mode).

- Login (email + Apple/Google/Microsoft simulados) → onboarding conversacional → app.
- Hoy: chips de carriles (Todo/Escuela/Gimnasio/Comida/Hobbies + hasta 3 propios) sobre un solo
  timeline, vista Día/Semana/Mes, tarjeta AHORA con progreso, línea de hora actual, deslizar a los
  lados cambia de carril.
- Hábitos: el mes en primer plano (días con progreso + heatmap de 3 niveles), anillos por área,
  racha resiliente, compartir el mes como imagen.
- Enfoque: temporizador de micro-bloques, Live Activity en pantalla de bloqueo e isla dinámica,
  "Desbloquear" siempre disponible, apps vitales no bloqueables.
- Vida: pendientes de hoy agrupados por área (posponer sin penalización), Dinero, Trámites,
  Reventa y Metas.
- Ascender (chatbot flotante), Perfil, referidos, plan Gratis/Pro.
- Widgets: "Ahora" (mediano), "Tu mes" y "Hábitos de hoy" (pequeños, marcables desde el widget),
  y circulares de pantalla de bloqueo (mes, minutos restantes, atajo a Enfoque).

## Requisitos

- Xcode 15 o posterior, **iOS 17 mínimo** (el código ya usaba APIs de iOS 17 como `.topBarTrailing`;
  los widgets interactivos también lo piden).

## Cómo abrirlo

Este repo no trae `.xcodeproj` (se escribió sin macOS). En Xcode:

1. File → New → Project → iOS → App. Nombre `ASCEND`, Interface SwiftUI, Language Swift, iOS 17.
2. Borra el `ContentView.swift` y el `ASCENDApp.swift` de la plantilla.
3. Arrastra la carpeta `ASCEND/` de este repo al proyecto ("Copy items if needed", target ASCEND).
4. Run.

## Widgets, pantalla de bloqueo e isla dinámica

1. **Target:** File → New → Target → Widget Extension. Nombre `ASCENDWidgets`, marca
   "Include Live Activity", desmarca "Include Configuration App Intent". Borra los archivos de
   ejemplo que genera y arrastra los de `ASCENDWidgets/` de este repo a ese target.
2. **Archivos compartidos:** selecciona estos archivos de `ASCEND/` y en el inspector (Target
   Membership) marca **también** `ASCENDWidgets`:
   - `Models/Models.swift`, `Models/ScheduleModels.swift`
   - `Data/DemoData.swift`, `Data/Persistence.swift`
   - `ViewModels/AppState.swift`
   - `DesignSystem/Colors.swift`, `Typography.swift`, `Components.swift`, `AscendLogo.swift`, `AreaColors.swift`
   - `Views/Components/MonthProgress.swift`
   - `Shared/FocusActivityAttributes.swift`
3. **App Group:** en Signing & Capabilities de **los dos** targets agrega "App Groups" con
   `group.com.ascend.app`. Si usas otro, cámbialo en `Persistence.appGroupID`. Sin esto la app
   funciona igual, pero los widgets se ven vacíos.
4. **Info.plist de la app:**
   - `NSSupportsLiveActivities` = `YES` (Live Activity de enfoque).
   - URL Types → URL Schemes: `ascend` (los widgets abren `ascend://today`, `ascend://habits`,
     `ascend://focus` y `ascend://focus/unlock`).
5. Run el esquema de la app; agrega los widgets desde la pantalla de inicio/bloqueo.

Cómo fluyen los datos: la app guarda en el App Group; los widgets leen con el mismo `AppState`.
Al marcar un hábito desde el widget se guarda al instante y la app lo relee al volver a primer plano.

## Qué se simplificó a propósito (queda pendiente si lo quieres más real)

- No hay backend (Supabase) ni OAuth real: el login social y la IA son simulados con reglas.
- Los datos se guardan en el dispositivo (`Persistence`, JSON en UserDefaults del App Group).
- El cobro de Pro no está conectado (falta StoreKit + App Store Connect); comprar solo extiende
  los días localmente.
- Pendientes del rediseño, marcados con `// TODO(diseño)`: respuestas rápidas y campo de texto del
  chatbot (el bot aún no responde mensajes), lista "Ya se unieron" en referidos (sin backend no se
  sabe quién usó el código) y botón "Pausar" de la sesión de enfoque (no existe pausa en `AppState`).
