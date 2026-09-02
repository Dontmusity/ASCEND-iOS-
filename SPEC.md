# ASCEND — Spec original (resumen de los prompts del equipo)

Ver contexto completo en la conversación del repo; resumen funcional para revisión:

## Producto
ASCEND es un "acompañante, no un capataz" para estudiantes universitarios (18-25) que viven
fuera de casa. Filosofía innegociable: **nunca regaña, nunca culpa, nunca presiona**. Slogan:
"Plan. Focus. Conquer."

## Identidad visual (obligatoria)
- `#E8BC75` dorado cálido — CTAs, acentos, progreso
- `#FCE4CA` crema claro — fondos, tarjetas
- `#9EA196` gris — texto secundario, bordes, inactivo
- Tipografía limpia/minimalista, esquinas redondeadas, sombras sutiles, tono cálido de acompañante
- Logo: "A" ascendente minimalista

## Arquitectura de pantallas
Tab bar de 5: Hoy, Hábitos, Enfoque, Vida, Perfil. Botón flotante de chatbot "Ascender" en toda
la app. Racha global (🔥) siempre visible en la esquina superior derecha de TODAS las pantallas.

- **Hoy**: carrusel horizontal de calendario por hora (Todo/Escuela/Gimnasio/Comida/Hobbies) +
  hasta 3 carruseles personalizados (nombre, color, notificaciones propias, filtrado estricto).
  Saludo contextual, resumen del día por IA, recordatorios configurables.
- **Hábitos**: streaks resilientes (fallar un día NO borra el progreso acumulado), analítica,
  heatmap, widget dinámico en Home.
- **Enfoque**: sesiones con micro-bloques, bloqueo de apps simulado (botón permanente
  "Desbloquear ahora", apps vitales — Teléfono/Mensajes/WhatsApp/Cámara/Mapas — nunca bloqueables),
  medidor de uso (solo tiempo, nunca contenido), frases motivacionales.
- **Vida**: to-dos por área con posponer sin penalización; gastos privados (ocultar montos, PIN
  de 4 dígitos, exportar, borrar todo, nunca se comparten ni se usan para anuncios); comida según
  intensidad de semana (nunca dietas extremas/ayunos/metas de peso); guía de trámites; reventa
  estudiantil (solo conecta, no procesa pagos).
- **Perfil**: avatar evolutivo, metas, notificaciones (máx. configurable, horario silencioso),
  privacidad, plan Gratis (anuncios) vs Pro (contador de días).

## Reglas éticas inquebrantables
Nunca regañar/culpar/presionar; nunca borrar progreso por fallar un día; la racha nunca es el
centro; no premiar más horas en la app; todo pausable/posponible sin penalización; datos privados;
funciona sin permisos opcionales; notificaciones limitadas.

## Login / referidos / Pro (Prompt 2)
- Login con email + Apple/Google/Microsoft (simulado si no hay Supabase), pasa por onboarding.
- Referidos: código único, compartir, contador. Recompensas por **paquetes cerrados NO
  acumulables ni proporcionales**: 1 persona → 1 semana Pro; 10 → 5 meses; 20 → 1 año. 2 personas
  NO dan 2 semanas — solo se otorga al llegar exacto a cada umbral.
- Plan mensual acredita 1 mes por pago; anual = 12 pagos con 5% de descuento, mostrando el ahorro.
  Días de referidos y de pago se suman al mismo contador. Al llegar a 0, vuelve a Gratis sin
  dark patterns.

## Estado actual de la implementación
SwiftUI nativo (no Lovable/web), en `/data/ASCEND-iOS/ASCEND`. Construido en un entorno sin
macOS/Xcode — nunca se ha compilado ni corrido. Sin backend real (Supabase no conectado): login
social, IA "Ascender", y bloqueo de apps son simulados con datos y reglas locales. Sin
persistencia entre lanzamientos (todo vive en `AppState`, un `ObservableObject` en memoria).
Ver `README.md` en la misma carpeta para el detalle de qué se simplificó a propósito.
