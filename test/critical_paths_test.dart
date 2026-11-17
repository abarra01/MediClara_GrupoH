// Pruebas de los tres recorridos críticos y de los requisitos funcionales
// vinculados (RF-01..RF-06).
//
//   flutter test test/critical_paths_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediclara/routes.dart';

import 'test_utils.dart';

void main() {
  setUpAll(loadAppFonts);

  testWidgets(
      'R3 · Consultar: la pantalla inicial muestra la medicación de hoy',
      (t) async {
    await pumpApp(t);
    expect(find.text('Medicación de hoy'), findsOneWidget);
    expect(find.text('1 de 3 tomas hechas hoy'), findsOneWidget);
    // RNF-A05: el estado se expresa con texto, no solo con color.
    expect(find.text('Tomado a las 08:05'), findsOneWidget);
    expect(find.text('Pendiente · 09:00'), findsOneWidget);
  });

  testWidgets(
      'R2 · Confirmar desde la alerta + aviso superior con Deshacer (RF-06)',
      (t) async {
    final s = await pumpApp(t, route: Routes.alert);
    await t.tap(find.text('Ya me lo he tomado'));
    await t.pumpAndSettle();

    expect(s.byId(2).isTaken, isTrue);
    expect(find.byType(MaterialBanner), findsOneWidget);
    expect(find.text('2 de 3 tomas hechas hoy'), findsOneWidget);

    await t.tap(find.text('Deshacer'));
    await t.pumpAndSettle();
    expect(s.byId(2).isTaken, isFalse);
    expect(find.text('1 de 3 tomas hechas hoy'), findsOneWidget);
    await t.pump(const Duration(seconds: 11)); // vacía el temporizador
  });

  testWidgets('R2 · El aviso Deshacer permanece al menos 5 s', (t) async {
    await pumpApp(t);
    await t.tap(find.text('Marcar como tomado').first);
    await t.pumpAndSettle();
    await t.pump(const Duration(seconds: 6));
    expect(find.text('Deshacer'), findsOneWidget);
    await t.pump(const Duration(seconds: 5));
    await t.pumpAndSettle();
    expect(find.text('Deshacer'), findsNothing);
  });

  testWidgets('RNF-A06 · El gesto de deslizar es solo una alternativa',
      (t) async {
    final s = await pumpApp(t, route: Routes.alert);
    await t.fling(find.text('Ya me lo he tomado'), const Offset(300, 0), 1000);
    await t.pumpAndSettle();
    expect(s.byId(2).isTaken, isTrue);
    await t.pump(const Duration(seconds: 11));
  });

  testWidgets('R1 · Añadir: un error no borra lo ya escrito (RF-02 / RNF-O04)',
      (t) async {
    final s = await pumpApp(t, route: Routes.add);
    await t.enterText(find.byType(TextField).last, '2 pastillas');
    await t.tap(find.text('Guardar medicamento'));
    await t.pumpAndSettle();

    expect(find.text('No se ha podido guardar'), findsOneWidget);
    expect(find.textContaining('Falta el nombre'), findsOneWidget);
    expect(find.text('2 pastillas'), findsOneWidget); // dato conservado

    await t.enterText(find.byType(TextField).first, 'Omeprazol');
    await t.tap(find.text('Guardar medicamento'));
    await t.pumpAndSettle();

    expect(find.text('Medicamento guardado'), findsOneWidget);
    expect(find.text('Omeprazol'), findsOneWidget);
    expect(
        s.active.any((m) => m.name == 'Omeprazol' && m.dose == '2 pastillas'),
        isTrue);
  });

  testWidgets('R1 · Cancelar con datos escritos pide confirmación', (t) async {
    await pumpApp(t, route: Routes.add);
    await t.enterText(find.byType(TextField).first, 'Ibuprofeno');
    await t.tap(find.text('Cancelar'));
    await t.pumpAndSettle();
    expect(find.text('¿Salir sin guardar?'), findsOneWidget);
    await t.tap(find.text('Seguir editando'));
    await t.pumpAndSettle();
    expect(find.text('Ibuprofeno'), findsOneWidget);
  });

  testWidgets('Eliminar un tratamiento exige confirmación explícita',
      (t) async {
    final s = await pumpApp(t, route: Routes.cabinet);
    await t.tap(find.text('Paracetamol'));
    await t.pumpAndSettle();
    await t.tap(find.text('Eliminar tratamiento'));
    await t.pumpAndSettle();
    expect(find.text('¿Eliminar Paracetamol?'), findsOneWidget);
    await t.tap(find.text('No, mantener'));
    await t.pumpAndSettle();
    expect(s.meds.any((m) => m.name == 'Paracetamol'), isTrue);
  });

  testWidgets('Ajustes · sin sonido, «Cambiar» queda deshabilitado y explicado',
      (t) async {
    await pumpApp(t, route: Routes.settings);
    await t.tap(find.text('Avisos con sonido'));
    await t.pumpAndSettle();
    expect(find.textContaining('No disponible'), findsOneWidget);
    final btn = t
        .widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Cambiar'));
    expect(btn.onPressed, isNull);
  });
}
