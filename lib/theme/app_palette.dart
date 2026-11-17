import 'package:flutter/material.dart';

/// Paleta de MediClara (Semana 4).
///
/// Cada par texto/fondo se ha medido con la fórmula de contraste de WCAG 2.2
/// (ver tabla de contrastes de la Memoria v4). Umbrales del proyecto:
///   · texto normal >= 4,5:1   · texto grande >= 3:1
///   · componentes / estados >= 3:1
///
/// Los colores de estado (tomado / pendiente / error) NUNCA se usan solos:
/// siempre van con icono y texto (RNF-A05).
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.background,
    required this.surface,
    required this.text,
    required this.textSecondary,
    required this.primary,
    required this.onPrimary,
    required this.success,
    required this.successContainer,
    required this.pending,
    required this.pendingContainer,
    required this.error,
    required this.errorContainer,
    required this.border,
    required this.divider,
    required this.disabledText,
    required this.disabledBackground,
    required this.banner,
    required this.onBanner,
    required this.bannerAction,
  });

  final Color background; // Fondo de pantalla
  final Color surface; // Tarjetas, barras, campos
  final Color text; // Texto principal
  final Color textSecondary; // Texto de apoyo (fechas, dosis)
  final Color primary; // Acciones principales
  final Color onPrimary;
  final Color success; // Estado «Tomado»
  final Color successContainer;
  final Color pending; // Estado «Pendiente»
  final Color pendingContainer;
  final Color error;
  final Color errorContainer;
  final Color border; // Bordes de campos y controles (>= 3:1)
  final Color divider; // Separadores decorativos (sin requisito)
  final Color disabledText;
  final Color disabledBackground;
  final Color banner; // Aviso superior «Deshacer»
  final Color onBanner;
  final Color bannerAction;

  /// Tema claro: fondo crema (#F6F4EF) en lugar de blanco puro para reducir
  /// el deslumbramiento (barrera visual situacional de la semana 1).
  static const light = AppPalette(
    background: Color(0xFFF6F4EF), // texto 15,35:1
    surface: Color(0xFFFFFFFF), // texto 16,88:1
    text: Color(0xFF1B1D21),
    textSecondary: Color(0xFF454B53), // 8,81:1 sobre tarjeta
    primary: Color(0xFF0B4F94), // 8,20:1 con blanco
    onPrimary: Color(0xFFFFFFFF),
    success: Color(0xFF1D6B35), // 6,55:1 / 5,65:1 sobre su contenedor
    successContainer: Color(0xFFE3F2E7),
    pending: Color(0xFF8A4500), // 7,16:1 / 6,14:1 sobre su contenedor
    pendingContainer: Color(0xFFFDEBD3),
    error: Color(0xFFB3261E), // 6,54:1 / 5,38:1 sobre su contenedor
    errorContainer: Color(0xFFFBE4E2),
    border: Color(0xFF6B717A), // 4,92:1 (componente, mínimo 3:1)
    divider: Color(0xFFD5D8DD),
    disabledText: Color(0xFF5F656D), // 4,71:1 sobre fondo deshabilitado
    disabledBackground: Color(0xFFE4E6EA),
    banner: Color(0xFF1B1D21),
    onBanner: Color(0xFFFFFFFF), // 16,88:1
    bannerAction: Color(0xFF9CC7FF), // 9,67:1
  );

  /// Tema oscuro: evita el deslumbramiento al usar la app desde la cama.
  static const dark = AppPalette(
    background: Color(0xFF121417), // texto 15,45:1
    surface: Color(0xFF1E2227), // texto 13,39:1
    text: Color(0xFFE9EBEE),
    textSecondary: Color(0xFFBAC1CA), // 8,81:1
    primary: Color(0xFF9CC7FF), // 8,90:1 con onPrimary
    onPrimary: Color(0xFF0A2540),
    success: Color(0xFF7FD89A), // 9,28:1 / 7,33:1
    successContainer: Color(0xFF163A22),
    pending: Color(0xFFF5B868), // 9,09:1 / 7,77:1
    pendingContainer: Color(0xFF3D2A10),
    error: Color(0xFFFFB4AB), // 9,42:1 / 8,53:1
    errorContainer: Color(0xFF4A1A16),
    border: Color(0xFF8E959E), // 5,29:1
    divider: Color(0xFF3A4048),
    disabledText: Color(0xFF9AA1AA), // 5,02:1
    disabledBackground: Color(0xFF2C3138),
    banner: Color(0xFFE9EBEE),
    onBanner: Color(0xFF1B1D21), // 14,13:1
    bannerAction: Color(0xFF0B4F94), // 6,87:1
  );

  static AppPalette of(BuildContext context) =>
      Theme.of(context).extension<AppPalette>()!;

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(covariant ThemeExtension<AppPalette>? other, double t) =>
      (other is AppPalette && t >= 0.5) ? other : this;
}

/// Espaciado en múltiplos de 8 px lógicos.
abstract final class Gap {
  static const double xs = 8;
  static const double s = 12;
  static const double m = 16;
  static const double l = 24;
  static const double xl = 32;

  /// RNF-A01: área táctil mínima 48×48 px lógicos.
  static const double minTarget = 48;
  static const double radius = 12;
}
