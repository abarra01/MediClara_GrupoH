import 'package:flutter/material.dart';

import 'screens/add_medication_screen.dart';
import 'screens/dose_alert_screen.dart';
import 'screens/home_shell.dart';
import 'screens/saved_screen.dart';
import 'screens/settings_screen.dart';
import 'state/app_state.dart';

/// Mapa de navegación (semana 3) convertido en rutas.
///
///   /            Medicación de hoy (pestaña «Hoy»)       ← recorrido 3
///   /botiquin    Mi botiquín (pestaña)
///   /anadir      Añadir / editar medicamento             ← recorrido 1
///   /guardado    Guardado con éxito
///   /alerta      Alerta de toma                          ← recorrido 2
///   /ajustes     Ajustes
abstract final class Routes {
  static const home = '/';
  static const cabinet = '/botiquin';
  static const add = '/anadir';
  static const addWithError = '/anadir-error'; // solo evidencias
  static const saved = '/guardado';
  static const alert = '/alerta';
  static const settings = '/ajustes';

  static Route<dynamic> onGenerate(RouteSettings s) {
    Widget page(BuildContext context) {
      final state = AppScope.of(context);
      final id = s.arguments as int?;
      switch (s.name) {
        case cabinet:
          return const HomeShell(initialIndex: 1);
        case add:
          return AddMedicationScreen(editId: id);
        case addWithError:
          return const AddMedicationScreen(showErrorsOnStart: true);
        case saved:
          return SavedScreen(medId: id ?? state.active.first.id);
        case alert:
          return DoseAlertScreen(
              medId: id ?? (state.nextPending ?? state.active.first).id);
        case settings:
          return const SettingsScreen();
        default:
          return const HomeShell();
      }
    }

    // La alerta se presenta como diálogo a pantalla completa.
    return MaterialPageRoute(
      settings: s,
      fullscreenDialog: s.name == alert,
      builder: page,
    );
  }
}
