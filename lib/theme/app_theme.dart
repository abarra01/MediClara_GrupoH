import 'package:flutter/material.dart';

import 'app_palette.dart';

/// Sistema visual mínimo de MediClara convertido en `ThemeData`.
///
/// Decisiones clave (ver Memoria v4):
///  · Tipografía Atkinson Hyperlegible, cuerpo mínimo 18 sp (público +50 años
///    con presbicia). Ningún texto por debajo de 16 sp.
///  · Todos los botones con altura mínima 56 y ancho mínimo 48 (> 48×48).
///  · Campos con borde de 2 px (4,92:1); en error, borde de 3 px + texto + icono.
///  · Interruptores con icono ✓/✕ en el pulgar: el estado no depende del color.
abstract final class AppTheme {
  static const fontFamily = 'AtkinsonHyperlegible';

  static ThemeData get light => _build(AppPalette.light, Brightness.light);
  static ThemeData get dark => _build(AppPalette.dark, Brightness.dark);

  static TextTheme _textTheme(AppPalette p) {
    TextStyle s(double size, FontWeight w, {double h = 1.3, Color? c}) =>
        TextStyle(
          fontFamily: fontFamily,
          fontSize: size,
          fontWeight: w,
          height: h,
          color: c ?? p.text,
        );
    return TextTheme(
      displaySmall: s(32, FontWeight.w700, h: 1.15), // Alerta de toma
      headlineSmall: s(26, FontWeight.w700, h: 1.2), // Título de pantalla
      titleLarge:
          s(21, FontWeight.w700, h: 1.25), // Nombre medicamento, secciones
      titleMedium: s(18, FontWeight.w700), // Etiquetas de campo
      bodyLarge: s(18, FontWeight.w400, h: 1.45), // Texto corrido
      bodyMedium: s(18, FontWeight.w400, h: 1.45),
      bodySmall: s(16, FontWeight.w400, h: 1.35, c: p.textSecondary), // Apoyo
      labelLarge: s(18, FontWeight.w700), // Botones
      labelMedium: s(16, FontWeight.w700),
      labelSmall: s(16, FontWeight.w700),
    );
  }

  static ThemeData _build(AppPalette p, Brightness b) {
    final text = _textTheme(p);
    final scheme = ColorScheme(
      brightness: b,
      primary: p.primary,
      onPrimary: p.onPrimary,
      secondary: p.primary,
      onSecondary: p.onPrimary,
      error: p.error,
      onError: p.surface,
      surface: p.surface,
      onSurface: p.text,
      onSurfaceVariant: p.textSecondary,
      outline: p.border,
      outlineVariant: p.divider,
      surfaceContainerHighest: p.disabledBackground,
      secondaryContainer: p.primary.withValues(alpha: 0.16),
      onSecondaryContainer: p.text,
    );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Gap.radius),
    );
    const minButton = Size(Gap.minTarget, 56);

    OutlineInputBorder border(Color c, double w) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(Gap.radius),
          borderSide: BorderSide(color: c, width: w),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: b,
      colorScheme: scheme,
      fontFamily: fontFamily,
      textTheme: text,
      scaffoldBackgroundColor: p.background,
      extensions: [p],
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      appBarTheme: AppBarTheme(
        backgroundColor: p.surface,
        foregroundColor: p.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 72,
        titleTextStyle: text.titleLarge,
        shape: Border(bottom: BorderSide(color: p.divider)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: minButton,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: text.labelLarge,
          shape: shape,
          backgroundColor: p.primary,
          foregroundColor: p.onPrimary,
          disabledBackgroundColor: p.disabledBackground,
          disabledForegroundColor: p.disabledText,
          iconSize: 24,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(minButton),
          padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
          textStyle: WidgetStatePropertyAll(text.labelLarge),
          shape: WidgetStatePropertyAll(shape),
          iconSize: const WidgetStatePropertyAll(24),
          backgroundColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.disabled)
                  ? p.disabledBackground
                  : p.surface),
          foregroundColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.disabled) ? p.disabledText : p.primary),
          iconColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.disabled) ? p.disabledText : p.primary),
          side: WidgetStateProperty.resolveWith((s) => BorderSide(
                color: s.contains(WidgetState.disabled) ? p.border : p.primary,
                width: 2,
              )),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(Gap.minTarget, Gap.minTarget),
          textStyle: text.labelLarge,
          foregroundColor: p.primary,
          shape: shape,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(Gap.minTarget, Gap.minTarget),
          foregroundColor: p.text,
          iconSize: 26,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: p.primary,
        foregroundColor: p.onPrimary,
        extendedTextStyle: text.labelLarge,
        extendedSizeConstraints:
            const BoxConstraints(minHeight: 64, minWidth: 64),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: text.bodyLarge!.copyWith(color: p.textSecondary),
        border: border(p.border, 2),
        enabledBorder: border(p.border, 2),
        focusedBorder: border(p.primary, 3),
        errorBorder: border(p.error, 3),
        focusedErrorBorder: border(p.error, 3),
        errorStyle: text.labelMedium!.copyWith(color: p.error),
        errorMaxLines: 4,
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Gap.radius),
          side: BorderSide(color: p.divider),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.surface,
        indicatorColor: p.primary.withValues(alpha: 0.16),
        height: 80,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((s) => s
                .contains(WidgetState.selected)
            ? text.labelMedium!.copyWith(color: p.primary)
            : text.labelMedium!
                .copyWith(color: p.textSecondary, fontWeight: FontWeight.w400)),
        iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
              color: s.contains(WidgetState.selected)
                  ? p.primary
                  : p.textSecondary,
              size: 26,
            )),
      ),
      switchTheme: SwitchThemeData(
        // Icono en el pulgar: activado ✓ / desactivado ✕ (no depende del color).
        thumbIcon: WidgetStateProperty.resolveWith((s) => Icon(
              s.contains(WidgetState.selected) ? Icons.check : Icons.close,
              size: 18,
            )),
        trackOutlineColor: WidgetStatePropertyAll(p.border),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(48, 56)),
          textStyle: WidgetStatePropertyAll(text.labelMedium),
          side: WidgetStatePropertyAll(BorderSide(color: p.primary, width: 2)),
          backgroundColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.selected) ? p.primary : p.surface),
          foregroundColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected) ? p.onPrimary : p.primary),
          iconColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected) ? p.onPrimary : p.primary),
        ),
      ),
      listTileTheme: ListTileThemeData(
        minVerticalPadding: 12,
        titleTextStyle: text.titleMedium,
        subtitleTextStyle: text.bodySmall,
        iconColor: p.text,
      ),
      dividerTheme: DividerThemeData(color: p.divider, thickness: 1),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyLarge,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        showDragHandle: true,
      ),
      bannerTheme: MaterialBannerThemeData(
        backgroundColor: p.banner,
        contentTextStyle: text.titleMedium!.copyWith(color: p.onBanner),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.success,
        linearTrackColor: p.disabledBackground,
        linearMinHeight: 12,
      ),
      tooltipTheme: TooltipThemeData(
          textStyle: text.labelMedium!.copyWith(
              color: b == Brightness.light ? Colors.white : Colors.black)),
    );
  }
}
