// Verificación automática de los RNF de accesibilidad con la
// Flutter Accessibility Guideline API (criterio de aceptación de la semana 2).
//
//   flutter test test/accessibility_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediclara/routes.dart';

import 'test_utils.dart';

const screens = {
  'Medicación de hoy': Routes.home,
  'Mi botiquín': Routes.cabinet,
  'Añadir medicamento': Routes.add,
  'Añadir (con errores)': Routes.addWithError,
  'Guardado con éxito': Routes.saved,
  'Alerta de toma': Routes.alert,
  'Ajustes': Routes.settings,
};

void main() {
  setUpAll(loadAppFonts);

  for (final dark in [false, true]) {
    final theme = dark ? 'oscuro' : 'claro';
    for (final e in screens.entries) {
      testWidgets('${e.key} · tema $theme · guías de accesibilidad', (t) async {
        final handle = t.ensureSemantics();
        await pumpApp(t, route: e.value, dark: dark);

        // RNF-A01: área táctil mínima 48×48 en Android.
        await expectLater(t, meetsGuideline(androidTapTargetGuideline));
        // RNF-A04: todo control accionable tiene nombre accesible.
        await expectLater(t, meetsGuideline(labeledTapTargetGuideline));
        handle.dispose();
      });

      testWidgets('${e.key} · tema $theme · contraste de todos los textos', (t) async {
        final handle = t.ensureSemantics();
        // Pantalla alta para que ningún texto quede cortado por el borde de la
        // lista: la guía mide el rectángulo completo del texto y, si está
        // recortado, mezcla el color de lo que hay encima (falso positivo).
        await pumpApp(t, route: e.value, dark: dark, size: const Size(412, 1800));
        // RNF-A02: contraste de texto (4,5:1 normal, 3:1 grande).
        await expectLater(t, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });
    }
  }

  // RNF-A03: los recorridos siguen siendo utilizables con texto al 200 %.
  // Si algún contenido se corta o desborda, Flutter lanza un error y la
  // prueba falla.
  for (final e in screens.entries) {
    testWidgets('${e.key} · texto del sistema al 200 % sin desbordes',
        (t) async {
      await pumpApp(t, route: e.value, systemTextScale: 2.0);
      expect(t.takeException(), isNull);
      // Se recorre todo el contenido desplazable para comprobar el final.
      final scrollables = find.byType(Scrollable);
      if (scrollables.evaluate().isNotEmpty) {
        await t.drag(scrollables.first, const Offset(0, -3000));
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
      }
    });
  }
}
