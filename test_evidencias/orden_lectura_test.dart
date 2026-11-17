// Vuelca el árbol semántico de cada pantalla EN ORDEN DE RECORRIDO, es decir,
// la secuencia de elementos que TalkBack anuncia al deslizar a la derecha.
// Es la evidencia de «orden de lectura» de la semana 5.
//
//   flutter test test_evidencias/orden_lectura_test.dart
//
// Resultado: test_evidencias/orden_lectura/<pantalla>.txt

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediclara/routes.dart';

import '../test/semantics_utils.dart';
import '../test/test_utils.dart';

void main() {
  setUpAll(loadAppFonts);

  const screens = {
    '1_medicacion_de_hoy': Routes.home,
    '2_anadir_medicamento': Routes.add,
    '2b_anadir_con_error': Routes.addWithError,
    '3_guardado': Routes.saved,
    '4_alerta_de_toma': Routes.alert,
    '5_mi_botiquin': Routes.cabinet,
    '6_ajustes': Routes.settings,
  };

  for (final e in screens.entries) {
    testWidgets('orden de lectura ${e.key}', (t) async {
      final h = t.ensureSemantics();
      await pumpApp(t, route: e.value);
      final lines = readingOrder(t);
      final dir = Directory('test_evidencias/orden_lectura')
        ..createSync(recursive: true);
      File('${dir.path}/${e.key}.txt').writeAsStringSync([
        for (var i = 0; i < lines.length; i++) '${i + 1}. ${lines[i]}'
      ].join('\n'));
      h.dispose();
    });
  }
}
