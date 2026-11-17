import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediclara/main.dart';
import 'package:mediclara/state/app_state.dart';
import 'package:mediclara/widgets/vision_simulator.dart';

/// Tamaño lógico de un móvil Android de gama media (p. ej. Pixel 7: 412×915).
const phone = Size(412, 915);

/// Reloj fijo para que las pruebas y capturas sean reproducibles.
AppState demoState() => AppState.demo(
      clock: () => const TimeOfDay(hour: 9, minute: 0),
      today: () => DateTime(2026, 11, 10),
    );

/// Carga las fuentes reales (Atkinson Hyperlegible + iconos Material) para
/// que las capturas muestren el texto de verdad y no cajas de prueba.
Future<void> loadAppFonts() async {
  final manifest =
      json.decode(await rootBundle.loadString('FontManifest.json')) as List;
  for (final f in manifest) {
    final family = (f as Map)['family'] as String;
    final loader = FontLoader(family.replaceFirst('packages/', ''));
    for (final a in f['fonts'] as List) {
      loader.addFont(rootBundle.load((a as Map)['asset'] as String));
    }
    await loader.load();
  }
}

Future<AppState> pumpApp(
  WidgetTester tester, {
  String route = '/',
  bool dark = false,
  VisionSim sim = VisionSim.none,
  double systemTextScale = 1.0,
  AppState? state,
  Size size = phone,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  tester.platformDispatcher.textScaleFactorTestValue = systemTextScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  final s = state ?? demoState();
  if (dark) s.themeMode = ThemeMode.dark;
  if (!dark) s.themeMode = ThemeMode.light;
  s.simulation = sim;
  await tester.pumpWidget(MediClaraApp(state: s, initialRoute: route));
  await tester.pumpAndSettle();
  return s;
}
