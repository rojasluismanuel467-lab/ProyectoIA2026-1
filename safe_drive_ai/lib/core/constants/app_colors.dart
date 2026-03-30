import 'package:flutter/material.dart';

/// Paleta de colores de Safe Drive AI basada en Material Design 3.
///
/// Colores empresariales profesionales para una app de transporte y seguridad.
/// Todos los valores son constantes estáticas para uso directo en widgets.
/// 
/// ## Sistema de Tonos MD3:
/// - Primary: Color principal de marca (azul corporativo)
/// - Secondary: Color secundario de soporte (azul grisáceo)
/// - Tertiary: Color de acento decorativo (verde azulado)
/// - Neutral: Grises para texto, fondos y bordes
/// - Error: Rojo para estados de error
abstract final class AppColors {
  // ═══════════════════════════════════════════════════════════════════════════
  // COLORES PRIMARIOS (Brand Blue - Corporativo)
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Color principal de la marca - Azul corporativo sólido
  /// Uso: Botones primarios, headers, elementos activos
  static const Color primary = Color(0xFF1976D2);
  
  /// Primary en estado hover/focus
  static const Color primaryHover = Color(0xFF1565C0);
  
  /// Primary en estado pressed
  static const Color primaryPressed = Color(0xFF0D47A1);
  
  /// Versión clara del primary para fondos sutiles
  /// Uso: Fondos de elementos seleccionados, badges
  static const Color primaryLight = Color(0xFFBBDEFB);
  
  /// Versión muy clara del primary para superficies
  /// Uso: Fondos de tarjetas seleccionadas, indicator backgrounds
  static const Color primarySurface = Color(0xFFE3F2FD);
  
  /// Primary container - tono intermedio para contenedores
  /// Uso: Cards destacadas, contenedores de iconos
  static const Color primaryContainer = Color(0xFF90CAF9);
  
  /// Color de texto sobre primary
  static const Color onPrimary = Color(0xFFFFFFFF);
  
  /// Color de texto sobre primary container
  static const Color onPrimaryContainer = Color(0xFF0D47A1);

  // ═══════════════════════════════════════════════════════════════════════════
  // COLORES SECUNDARIOS (Slate Blue - Soporte)
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Color secundario - Azul grisáceo profesional
  /// Uso: Botones secundarios, elementos de soporte
  static const Color secondary = Color(0xFF546E7A);
  
  /// Secondary en estado hover/focus
  static const Color secondaryHover = Color(0xFF455A64);
  
  /// Secondary en estado pressed
  static const Color secondaryPressed = Color(0xFF37474F);
  
  /// Versión clara del secondary
  static const Color secondaryLight = Color(0xFFCFD8DC);
  
  /// Secondary container para contenedores
  static const Color secondaryContainer = Color(0xFFB0BEC5);
  
  /// Color de texto sobre secondary
  static const Color onSecondary = Color(0xFFFFFFFF);
  
  /// Color de texto sobre secondary container
  static const Color onSecondaryContainer = Color(0xFF37474F);

  /// Color de acento - Azul cyan para elementos decorativos
  /// Uso: Elementos decorativos, iconos, highlights
  static const Color accent = Color(0xFF0288D1);
  
  /// Versión clara del accent
  static const Color accentLight = Color(0xFFB3E5FC);
  
  /// Accent container
  static const Color accentContainer = Color(0xFF4FC3F7);
  
  /// Color de texto sobre accent
  static const Color onAccent = Color(0xFFFFFFFF);
  
  /// Color de texto sobre accent container
  static const Color onAccentContainer = Color(0xFF01579B);

  // ═══════════════════════════════════════════════════════════════════════════
  // COLORES TERCIARIOS (Teal - Acento Decorativo)
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Color terciario - Verde azulado para acentos
  /// Uso: Elementos decorativos, highlights, iconos
  static const Color tertiary = Color(0xFF00897B);
  
  /// Versión clara del tertiary
  static const Color tertiaryLight = Color(0xFFB2DFDB);
  
  /// Tertiary container
  static const Color tertiaryContainer = Color(0xFF80CBC4);
  
  /// Color de texto sobre tertiary
  static const Color onTertiary = Color(0xFFFFFFFF);
  
  /// Color de texto sobre tertiary container
  static const Color onTertiaryContainer = Color(0xFF004D40);

  // ═══════════════════════════════════════════════════════════════════════════
  // COLORES NEUTROS (Gris - Estructura)
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Blanco puro
  static const Color white = Color(0xFFFFFFFF);
  
  /// Fondo principal de la aplicación - Gris muy claro con tono azulado
  /// Uso: Background general de pantallas
  static const Color background = Color(0xFFF5F7FB);
  
  /// Superficie base - Blanco limpio
  /// Uso: Cards, dialogs, sheets
  static const Color surface = Color(0xFFFFFFFF);
  
  /// Surface variant - Gris claro para variación
  /// Uso: Superficies secundarias, headers de listas
  static const Color surfaceVariant = Color(0xFFE8EAF6);
  
  /// Surface container - tono intermedio
  /// Uso: Contenedores dentro de superficies
  static const Color surfaceContainer = Color(0xFFF1F3F8);
  
  /// Surface container alto para mayor elevación
  static const Color surfaceContainerHigh = Color(0xFFE3E7F0);
  
  /// Divider - Líneas divisorias sutiles
  static const Color divider = Color(0xFFE0E3E8);
  
  /// Divider fuerte para mayor separación
  static const Color dividerStrong = Color(0xFFBDC3C7);

  // ═══════════════════════════════════════════════════════════════════════════
  // COLORES DE TEXTO (Jerarquía Tipográfica)
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Texto primario - Gris muy oscuro (casi negro)
  /// Uso: Títulos, contenido principal
  /// Contraste: 16.1:1 sobre blanco (WCAG AAA)
  static const Color textPrimary = Color(0xFF1C1E21);
  
  /// Texto secundario - Gris medio
  /// Uso: Subtítulos, descripciones, metadata
  /// Contraste: 5.9:1 sobre blanco (WCAG AA)
  static const Color textSecondary = Color(0xFF5C626B);
  
  /// Texto terciario - Gris claro
  /// Uso: Placeholders, texto deshabilitado
  static const Color textTertiary = Color(0xFF9AA0A6);
  
  /// Texto sobre primary
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  
  /// Texto sobre superficies oscuras
  static const Color textOnSurface = Color(0xFF1C1E21);

  // ═══════════════════════════════════════════════════════════════════════════
  // COLORES SEMÁNTICOS (Estados y Feedback)
  // ═══════════════════════════════════════════════════════════════════════════
  
  // ── Éxito (Verde Corporativo) ──────────────────────────────────────────────
  /// Color de éxito - Verde profesional
  /// Uso: Estados completados, aprobaciones, éxitos
  static const Color success = Color(0xFF2E7D32);
  
  /// Success surface - Fondo sutil para elementos de éxito
  static const Color successSurface = Color(0xFFE8F5E9);
  
  /// Success container - Contenedor de elementos de éxito
  static const Color successContainer = Color(0xFF81C784);
  
  /// Color de texto sobre success
  static const Color onSuccess = Color(0xFFFFFFFF);
  
  /// Color de texto sobre success container
  static const Color onSuccessContainer = Color(0xFF1B5E20);

  // ── Advertencia (Ámbar) ────────────────────────────────────────────────────
  /// Color de advertencia - Ámbar profesional
  /// Uso: Estados pendientes, precauciones
  static const Color warning = Color(0xFFF57F17);
  
  /// Warning surface - Fondo sutil para advertencias
  static const Color warningSurface = Color(0xFFFFF8E1);
  
  /// Warning container
  static const Color warningContainer = Color(0xFFFFB74D);
  
  /// Color de texto sobre warning
  static const Color onWarning = Color(0xFF000000);
  
  /// Color de texto sobre warning container
  static const Color onWarningContainer = Color(0xFFE65100);

  // ── Error (Rojo) ───────────────────────────────────────────────────────────
  /// Color de error - Rojo profesional
  /// Uso: Estados de error, cancelaciones, alertas críticas
  static const Color error = Color(0xFFC62828);
  
  /// Error surface - Fondo sutil para errores
  static const Color errorSurface = Color(0xFFFFEBEE);
  
  /// Error container
  static const Color errorContainer = Color(0xFFEF5350);
  
  /// Color de texto sobre error
  static const Color onError = Color(0xFFFFFFFF);
  
  /// Color de texto sobre error container
  static const Color onErrorContainer = Color(0xFFB71C1C);

  // ── Información (Azul) ─────────────────────────────────────────────────────
  /// Color de información - Azul informativo
  /// Uso: Estados informativos, tips, ayuda
  static const Color info = Color(0xFF0277BD);
  
  /// Info surface - Fondo sutil para información
  static const Color infoSurface = Color(0xFFE1F5FE);
  
  /// Info container
  static const Color infoContainer = Color(0xFF4FC3F7);
  
  /// Color de texto sobre info
  static const Color onInfo = Color(0xFFFFFFFF);
  
  /// Color de texto sobre info container
  static const Color onInfoContainer = Color(0xFF01579B);

  // ═══════════════════════════════════════════════════════════════════════════
  // SOMBRAS Y ELEVACIÓN (Material Design 3)
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Color de sombra - Gris azulado con transparencia
  /// Uso: Shadow para elevación de componentes
  static const Color shadow = Color(0xFF1A1F2E);
  
  /// Shadow con menor opacidad para elevaciones bajas
  static const Color shadowLight = Color(0x0D1A1F2E);
  
  /// Shadow con mayor opacidad para elevaciones altas
  static const Color shadowHeavy = Color(0x1A1A1F2E);

  // ═══════════════════════════════════════════════════════════════════════════
  // ESTADOS (Interacción)
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Overlay para estado hover (8% opacidad)
  static const Color hoverOverlay = Color(0x141C1E21);
  
  /// Overlay para estado focus (12% opacidad)
  static const Color focusOverlay = Color(0x1F1C1E21);
  
  /// Overlay para estado pressed (16% opacidad)
  static const Color pressedOverlay = Color(0x291C1E21);
  
  /// Overlay para estado seleccionado (8% primary)
  static const Color selectedOverlay = Color(0x141976D2);
  
  /// Overlay para estado deshabilitado (12% texto)
  static const Color disabledOverlay = Color(0x1F5C626B);

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS PARA OPACIDAD (Uso con .withOpacity)
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Primary con diferentes opacidades
  static Color primaryWithOpacity(double opacity) => primary.withOpacity(opacity);
  
  /// Success con diferentes opacidades
  static Color successWithOpacity(double opacity) => success.withOpacity(opacity);
  
  /// Error con diferentes opacidades
  static Color errorWithOpacity(double opacity) => error.withOpacity(opacity);
  
  /// Warning con diferentes opacidades
  static Color warningWithOpacity(double opacity) => warning.withOpacity(opacity);
}

// ═════════════════════════════════════════════════════════════════════════════
// EXTENSIONES DE COLOR (Utilidades MD3)
// ═════════════════════════════════════════════════════════════════════════════

/// Extensión para obtener variantes de color automáticamente
extension ColorVariants on Color {
  /// Versión más clara del color (80% más claro)
  Color get lighten {
    return Color.lerp(this, Colors.white, 0.8)!;
  }
  
  /// Versión más oscura del color (20% más oscuro)
  Color get darken {
    return Color.lerp(this, Colors.black, 0.2)!;
  }
  
  /// Color con opacidad para hover (8%)
  Color get hover => withOpacity(0.08);
  
  /// Color con opacidad para focus (12%)
  Color get focus => withOpacity(0.12);
  
  /// Color con opacidad para pressed (16%)
  Color get pressed => withOpacity(0.16);
  
  /// Color con opacidad para selected (8%)
  Color get selected => withOpacity(0.08);
}

// ═════════════════════════════════════════════════════════════════════════════
// TEMAS DE SOMBRA (Elevation Levels MD3)
// ═════════════════════════════════════════════════════════════════════════════

/// Niveles de elevación Material Design 3
/// 
/// MD3 usa sombras sutiles con tonalidad en lugar de negro puro.
/// Las elevaciones van de 0 a 5, donde:
/// - 0: Sin elevación (mismo plano que el fondo)
/// - 1: Elevación mínima (elementos ligeramente elevados)
/// - 2: Elevación baja (cards estándar)
/// - 3: Elevación media (FAB, dialogs)
/// - 4: Elevación alta (menús emergentes)
/// - 5: Elevación máxima (overlays críticos)
abstract final class AppElevation {
  /// Level 0 - Sin sombra
  /// Uso: Fondos planos, superficies base
  static const List<BoxShadow> level0 = [];
  
  /// Level 1 - Sombra pequeña (2dp)
  /// Uso: Elementos ligeramente elevados, focused states
  static const List<BoxShadow> level1 = [
    BoxShadow(
      color: Color(0x0D1A1F2E),
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
  ];
  
  /// Level 2 - Sombra mediana (4dp)
  /// Uso: Cards estándar, botones elevados
  static const List<BoxShadow> level2 = [
    BoxShadow(
      color: Color(0x141A1F2E),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];
  
  /// Level 3 - Sombra grande (8dp)
  /// Uso: FAB, dialogs, app bars elevados
  static const List<BoxShadow> level3 = [
    BoxShadow(
      color: Color(0x1A1A1F2E),
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ];
  
  /// Level 4 - Sombra extra grande (16dp)
  /// Uso: Menús emergentes, dropdowns
  static const List<BoxShadow> level4 = [
    BoxShadow(
      color: Color(0x1F1A1F2E),
      blurRadius: 16,
      offset: Offset(0, 8),
    ),
  ];
  
  /// Level 5 - Sombra máxima (24dp)
  /// Uso: Overlays críticos, modales importantes
  static const List<BoxShadow> level5 = [
    BoxShadow(
      color: Color(0x261A1F2E),
      blurRadius: 24,
      offset: Offset(0, 12),
    ),
  ];
}

// ═════════════════════════════════════════════════════════════════════════════
// ESPACIADO (8dp Grid System)
// ═════════════════════════════════════════════════════════════════════════════

/// Sistema de espaciado basado en la grilla de 8dp de Material Design
/// 
/// Todos los valores son múltiplos de 4dp para consistencia visual.
/// Uso recomendado:
/// - Espacio entre elementos relacionados: 8dp
/// - Espacio entre secciones: 16-24dp
/// - Padding interno de componentes: 16dp
/// - Márgenes de pantalla: 16-24dp
abstract final class AppSpacing {
  /// 4dp - Espacio mínimo
  static const double xs = 4.0;
  
  /// 8dp - Espacio pequeño (estándar entre elementos relacionados)
  static const double sm = 8.0;
  
  /// 12dp - Espacio medio-pequeño
  static const double md = 12.0;
  
  /// 16dp - Espacio medio (estándar para padding)
  static const double lg = 16.0;
  
  /// 24dp - Espacio grande (entre secciones)
  static const double xl = 24.0;
  
  /// 32dp - Espacio extra grande
  static const double xxl = 32.0;
  
  /// 48dp - Espacio monumental
  static const double massive = 48.0;
}

// ═════════════════════════════════════════════════════════════════════════════
// RADIO DE BORDE (Consistencia Visual)
// ═════════════════════════════════════════════════════════════════════════════

/// Sistema de radios de borde para consistencia visual
/// 
/// MD3 recomienda bordes redondeados para una apariencia más amigable.
abstract final class AppBorderRadius {
  /// 4dp - Radio pequeño (elementos compactos)
  static const double sm = 4.0;
  
  /// 8dp - Radio medio (botones pequeños, chips)
  static const double md = 8.0;
  
  /// 12dp - Radio estándar (cards, contenedores)
  static const double lg = 12.0;
  
  /// 16dp - Radio grande (dialogs, sheets)
  static const double xl = 16.0;
  
  /// 24dp - Radio extra grande (contenedores grandes)
  static const double xxl = 24.0;
  
  /// 28dp - Radio completo para botones (height/2)
  static const double full = 28.0;
}

// ═════════════════════════════════════════════════════════════════════════════
// TIPOGRAFÍA (Escala Tipográfica MD3)
// ═════════════════════════════════════════════════════════════════════════════

/// Escala tipográfica basada en Material Design 3
/// 
/// Todos los tamaños soportan escalado dinámico hasta 200%.
abstract final class AppTypography {
  /// Display - Títulos muy grandes (32-40pt)
  /// Uso: Encabezados de pantalla principal
  static const TextStyle displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    height: 1.25,
    letterSpacing: -0.5,
  );
  
  static const TextStyle displayMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    height: 1.25,
    letterSpacing: -0.25,
  );
  
  static const TextStyle displaySmall = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    height: 1.33,
  );
  
  /// Headline - Títulos de sección (20-24pt)
  /// Uso: Encabezados de sección, títulos de cards
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.33,
  );
  
  static const TextStyle headlineMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );
  
  static const TextStyle headlineSmall = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.44,
  );
  
  /// Title - Títulos de componentes (16-18pt)
  /// Uso: Títulos de cards, dialogs, lists
  static const TextStyle titleLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.44,
  );
  
  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.5,
    letterSpacing: 0.15,
  );
  
  static const TextStyle titleSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.43,
    letterSpacing: 0.1,
  );
  
  /// Body - Texto de contenido (14-16pt)
  /// Uso: Párrafos, descripciones, contenido principal
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    height: 1.5,
    letterSpacing: 0.5,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    height: 1.43,
    letterSpacing: 0.25,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    height: 1.33,
    letterSpacing: 0.4,
  );
  
  /// Label - Texto de etiquetas (11-14pt)
  /// Uso: Botones, tabs, chips, captions
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.43,
    letterSpacing: 0.1,
  );
  
  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.33,
    letterSpacing: 0.5,
  );
  
  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.45,
    letterSpacing: 0.5,
  );
}
