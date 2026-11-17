// Pruebas añadidas en la semana 5: semántica para TalkBack y correcciones
// de la revisión cruzada.
//
//   flutter test test/semana5_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediclara/routes.dart';
import 'package:mediclara/state/app_state.dart';

import 'semantics_utils.dart';
import 'test_utils.dart';

void main() {
  setUpAll(loadAppFonts);

  testWidgets('TalkBack lee cada toma como una frase con su estado', (t) async {
    final h = t.ensureSemantics();
    await pumpApp(t);
    expect(
        find.bySemanticsLabel(
            'Paracetamol: 1 pastilla a las 09:00. Pendiente.'),
        findsOneWidget);
    expect(
        find.bySemanticsLabel(
            'Enalapril: 1 pastilla a las 08:00, para la tensión. Tomado a las 08:05.'),
        findsOneWidget);
    // El botón dice a qué medicamento afecta.
    expect(find.bySemanticsLabel('Marcar Paracetamol como tomado'),
        findsOneWidget);
    h.dispose();
  });

  testWidgets(
      'Orden de lectura de Hoy: título → progreso → mañana → tarde → noche',
      (t) async {
    final h = t.ensureSemantics();
    await pumpApp(t);
    final order = readingOrder(t).join('\n');
    int at(String s) => order.indexOf(s);
    expect(at('Medicación de hoy'), lessThan(at('tomas hechas hoy')));
    expect(at('tomas hechas hoy'), lessThan(at('«Mañana»')));
    expect(at('«Mañana»'), lessThan(at('Paracetamol:')));
    expect(at('Paracetamol:'), lessThan(at('Marcar Paracetamol')));
    expect(at('«Tarde»'), lessThan(at('«Noche»')));
    expect(at('«Noche»'), lessThan(at('Atorvastatina:')));
    h.dispose();
  });

  testWidgets(
      'Ajustes: «Avisos con sonido» se lee antes que lo que depende de él',
      (t) async {
    final h = t.ensureSemantics();
    await pumpApp(t, route: Routes.settings);
    final order = readingOrder(t).join('\n');
    expect(order.indexOf('Avisos con sonido'),
        lessThan(order.indexOf('Sonido de la alarma')));
    expect(find.bySemanticsLabel('Cambiar el sonido de la alarma'),
        findsOneWidget);
    h.dispose();
  });

  testWidgets('El error del formulario se anuncia una sola vez', (t) async {
    final h = t.ensureSemantics();
    await pumpApp(t, route: Routes.addWithError);
    final order = readingOrder(t);
    expect(order.where((l) => l.startsWith('«Falta el nombre')), isEmpty,
        reason: 'el mensaje va dentro del campo, no como elemento suelto');
    expect(order.where((l) => l.contains('Falta el nombre')).length, 1);
    h.dispose();
  });

  testWidgets(
      'T4: marcar una toma con más de 2 h de antelación pide confirmación',
      (t) async {
    final s = await pumpApp(t);
    await t.scrollUntilVisible(
        find.bySemanticsLabel('Marcar Atorvastatina como tomado'), 200);
    await t.pumpAndSettle();
    await t.tap(find.bySemanticsLabel('Marcar Atorvastatina como tomado'));
    await t.pumpAndSettle();
    expect(find.text('Aún no es la hora'), findsOneWidget);
    await t.tap(find.text('No, esperar'));
    await t.pumpAndSettle();
    expect(s.byId(3).isTaken, isFalse);

    await t.tap(find.bySemanticsLabel('Marcar Atorvastatina como tomado'));
    await t.pumpAndSettle();
    await t.tap(find.text('Sí, ya lo he tomado'));
    await t.pumpAndSettle();
    expect(s.byId(3).isTaken, isTrue);
    await t.pump(const Duration(seconds: 11));
  });

  testWidgets('T1: ningún botón de la lista queda tapado por otro control',
      (t) async {
    await pumpApp(t);
    final bars = t.getRect(find.byType(NavigationBar)).top -
        t
            .getSize(find.widgetWithText(FilledButton, 'Añadir medicamento'))
            .height;
    final list = t.getRect(find.byType(ListView).first);
    expect(list.bottom, lessThanOrEqualTo(bars),
        reason: 'la lista termina donde empieza la barra «Añadir medicamento»');
  });

  testWidgets('Una toma a su hora se marca sin preguntar', (t) async {
    final s = await pumpApp(t);
    await t.tap(find.bySemanticsLabel('Marcar Paracetamol como tomado'));
    await t.pumpAndSettle();
    expect(find.text('Aún no es la hora'), findsNothing);
    expect(s.byId(2).isTaken, isTrue);
    await t.pump(const Duration(seconds: 11));
  });

  testWidgets('Con TalkBack activo el aviso «Deshacer» no se cierra solo (T3)',
      (t) async {
    final h = t.ensureSemantics();
    t.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(accessibleNavigation: true);
    addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await pumpApp(t);
    await t.tap(find.bySemanticsLabel('Marcar Paracetamol como tomado'));
    await t.pumpAndSettle();
    await t.pump(const Duration(seconds: 30));
    expect(find.text('Deshacer'), findsOneWidget);
    expect(find.byType(MaterialBanner), findsOneWidget);
    h.dispose();
  });

  testWidgets('Diálogo de toma adelantada al 200 %, sin desbordes', (t) async {
    await pumpApp(t, systemTextScale: 2.0);
    await t.scrollUntilVisible(
        find.bySemanticsLabel('Marcar Atorvastatina como tomado'), 200);
    await t.pumpAndSettle();
    await t.tap(find.bySemanticsLabel('Marcar Atorvastatina como tomado'));
    await t.pumpAndSettle();
    expect(find.text('Aún no es la hora'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('Diálogo de eliminar al 200 %, sin desbordes', (t) async {
    await pumpApp(t, route: Routes.cabinet, systemTextScale: 2.0);
    await t.scrollUntilVisible(find.text('Paracetamol'), 200,
        scrollable: find.byType(Scrollable).last);
    await t.pumpAndSettle();
    await t.tap(find.text('Paracetamol'));
    await t.pumpAndSettle();
    await t.scrollUntilVisible(find.text('Eliminar tratamiento'), 100,
        scrollable: find.byType(Scrollable).last);
    await t.tap(find.text('Eliminar tratamiento'));
    await t.pumpAndSettle();
    expect(find.text('¿Eliminar Paracetamol?'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('Navegación predecible: cada acción lleva a donde dice', (t) async {
    await pumpApp(t);
    await t.tap(find.text('Añadir medicamento'));
    await t.pumpAndSettle();
    expect(find.text('Guardar medicamento'), findsOneWidget);
    await t.tap(find.text('Cancelar')); // sin datos: vuelve sin preguntar
    await t.pumpAndSettle();
    expect(find.text('Medicación de hoy'), findsOneWidget);
    await t.tap(find.byTooltip('Ajustes'));
    await t.pumpAndSettle();
    expect(find.text('Avisos con sonido'), findsOneWidget);
    await t.tap(find.byTooltip('Atrás'));
    await t.pumpAndSettle();
    expect(find.text('Medicación de hoy'), findsOneWidget);
  });

  // ---- Correcciones tras la revisión de la entrega ----

  testWidgets('El mensaje de error aparece una sola vez dentro del campo',
      (t) async {
    final h = t.ensureSemantics();
    await pumpApp(t, route: Routes.addWithError);
    final field = readingOrder(t)
        .firstWhere((l) => l.contains('Nombre del medicamento'));
    expect('Falta el nombre'.allMatches(field).length, 1,
        reason: 'ni repetido como «pista» ni como elemento suelto: $field');
    h.dispose();
  });

  testWidgets('Si solo falla la cantidad, el foco va a ese campo', (t) async {
    await pumpApp(t, route: Routes.add);
    await t.enterText(find.byType(TextField).first, 'Ibuprofeno');
    await t.enterText(find.byType(TextField).last, '');
    await t.tap(find.text('Guardar medicamento'));
    await t.pumpAndSettle();
    final dose = t.widget<TextField>(find.byType(TextField).last);
    expect(dose.focusNode!.hasFocus, isTrue);
    expect(find.text('Ibuprofeno'), findsOneWidget,
        reason: 'lo escrito se conserva');
  });

  testWidgets('Con TalkBack, el aviso «Deshacer» se puede cerrar sin deshacer',
      (t) async {
    final h = t.ensureSemantics();
    t.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(accessibleNavigation: true);
    addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final s = await pumpApp(t);
    await t.tap(find.bySemanticsLabel('Marcar Paracetamol como tomado'));
    await t.pumpAndSettle();
    await t.tap(find.bySemanticsLabel('Cerrar el aviso'));
    await t.pumpAndSettle();
    expect(find.byType(MaterialBanner), findsNothing);
    expect(s.byId(2).isTaken, isTrue, reason: 'cerrar no deshace la toma');
    h.dispose();
  });

  testWidgets('«Recordar en 15 min» calcula la hora desde ahora', (t) async {
    final s = AppState.demo(
      clock: () => const TimeOfDay(hour: 10, minute: 50),
      today: () => DateTime(2026, 11, 10),
    );
    await pumpApp(t, route: Routes.alert, state: s);
    await t.tap(find.text('Recordar en 15 min'));
    await t.pumpAndSettle();
    expect(find.text('Te lo recordaremos a las 11:05'), findsOneWidget);
    await t.pump(const Duration(seconds: 11));
  });

  testWidgets('El tamaño de letra dice qué ajusta (no solo «Normal»)',
      (t) async {
    final h = t.ensureSemantics();
    await pumpApp(t, route: Routes.settings);
    expect(find.bySemanticsLabel('Letra muy grande'), findsOneWidget);
    h.dispose();
  });

  testWidgets('El encabezado se lee solo y antes que su subtítulo', (t) async {
    final h = t.ensureSemantics();
    await pumpApp(t, route: Routes.cabinet);
    final order = readingOrder(t);
    expect(order[0], '«Mi botiquín» — encabezado');
    expect(order[1], startsWith('«Todos tus tratamientos'));
    h.dispose();
  });
}
