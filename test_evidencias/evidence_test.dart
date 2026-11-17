// Genera las capturas de evidencia de la semana 4 a partir de la app real
// (no de un mockup): escala de grises, simulaciones de visión cromática,
// estados de error / éxito / selección / deshabilitado y texto al 200 %.
//
//   flutter test test_evidencias --update-goldens
//
// Las imágenes quedan en test_evidencias/capturas/.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediclara/routes.dart';
import 'package:mediclara/widgets/vision_simulator.dart';

import '../test/test_utils.dart';

Future<void> shot(WidgetTester t, String name) => expectLater(
    find.byType(MaterialApp), matchesGoldenFile('capturas/$name.png'));

/// Igual que testWidgets pero con sombras reales (en los tests Flutter las
/// sustituye por un trazo negro). Se restauran antes de acabar la prueba.
void shotTest(String name, Future<void> Function(WidgetTester) body) =>
    testWidgets(name, (t) async {
      debugDisableShadows = false;
      try {
        await body(t);
      } finally {
        debugDisableShadows = true;
      }
    });

void main() {
  setUpAll(loadAppFonts);

  final views = <String, String>{
    '01_hoy': Routes.home,
    '02_anadir': Routes.add,
    '03_anadir_error': Routes.addWithError,
    '04_guardado': Routes.saved,
    '05_alerta': Routes.alert,
    '06_botiquin': Routes.cabinet,
    '07_ajustes': Routes.settings,
  };

  for (final v in views.entries) {
    shotTest('captura ${v.key} claro', (t) async {
      await pumpApp(t, route: v.value);
      await shot(t, '${v.key}_claro');
    });
    shotTest('captura ${v.key} oscuro', (t) async {
      await pumpApp(t, route: v.value, dark: true);
      await shot(t, '${v.key}_oscuro');
    });
  }

  // Escala de grises y daltonismo sobre las pantallas con estados de color.
  for (final sim in VisionSim.values.where((s) => s != VisionSim.none)) {
    shotTest('captura confirmación toma adelantada (T4)', (t) async {
    await pumpApp(t);
    await t.scrollUntilVisible(
        find.bySemanticsLabel('Marcar Atorvastatina como tomado'), 200);
    await t.pumpAndSettle();
    await t.tap(find.bySemanticsLabel('Marcar Atorvastatina como tomado'));
    await t.pumpAndSettle();
    await shot(t, '13_confirmar_toma_adelantada');
  });

  shotTest('captura error al 200 %', (t) async {
    await pumpApp(t, route: Routes.addWithError, systemTextScale: 2.0);
    await shot(t, '12_anadir_error_texto200');
  });

  for (final v in {
      '01_hoy': Routes.home,
      '03_anadir_error': Routes.addWithError
    }.entries) {
      shotTest('captura ${v.key} ${sim.name}', (t) async {
        await pumpApp(t, route: v.value, sim: sim);
        await shot(t, '${v.key}_${sim.name}');
      });
    }
  }

  shotTest('captura hoy tras confirmar (aviso Deshacer)', (t) async {
    await pumpApp(t);
    await t.tap(find.text('Marcar como tomado').first);
    await t.pumpAndSettle();
    await shot(t, '08_hoy_deshacer');
    await t.pump(const Duration(seconds: 11));
  });

  shotTest('captura hoy deshacer en grises', (t) async {
    await pumpApp(t, sim: VisionSim.grayscale);
    await t.tap(find.text('Marcar como tomado').first);
    await t.pumpAndSettle();
    await shot(t, '08_hoy_deshacer_grayscale');
    await t.pump(const Duration(seconds: 11));
  });

  shotTest('captura confirmación de borrado', (t) async {
    await pumpApp(t, route: Routes.cabinet);
    await t.tap(find.text('Paracetamol'));
    await t.pumpAndSettle();
    await shot(t, '09_botiquin_opciones');
    await t.tap(find.text('Eliminar tratamiento'));
    await t.pumpAndSettle();
    await shot(t, '10_eliminar_confirmar');
  });

  shotTest('captura ajustes con opción deshabilitada', (t) async {
    await pumpApp(t, route: Routes.settings);
    await t.tap(find.text('Avisos con sonido'));
    await t.pumpAndSettle();
    await shot(t, '11_ajustes_deshabilitado');
  });

  shotTest('captura ajustes deshabilitado en grises', (t) async {
    await pumpApp(t, route: Routes.settings, sim: VisionSim.grayscale);
    await t.tap(find.text('Avisos con sonido'));
    await t.pumpAndSettle();
    await shot(t, '11_ajustes_deshabilitado_grayscale');
  });

  for (final v in {
    '12_hoy_texto200': Routes.home,
    '12_anadir_texto200': Routes.add,
    '12_alerta_texto200': Routes.alert
  }.entries) {
    shotTest('captura ${v.key}', (t) async {
      await pumpApp(t, route: v.value, systemTextScale: 2.0);
      await shot(t, v.key);
    });
  }
}
