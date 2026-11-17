import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'routes.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';
import 'widgets/vision_simulator.dart';

void main() {
  runApp(MediClaraApp(state: AppState.demo()));
}

class MediClaraApp extends StatelessWidget {
  const MediClaraApp(
      {super.key, required this.state, this.initialRoute = Routes.home});

  final AppState state;
  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      child: ListenableBuilder(
        listenable: state,
        builder: (context, _) => MaterialApp(
          title: 'MediClara',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          // Por defecto sigue el modo oscuro del sistema; Ajustes lo puede forzar.
          themeMode: state.themeMode,
          locale: const Locale('es', 'ES'),
          supportedLocales: const [Locale('es', 'ES')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          initialRoute: initialRoute,
          onGenerateRoute: Routes.onGenerate,
          builder: (context, child) {
            // RNF-A03: se respeta SIEMPRE la escala de texto del sistema y se
            // multiplica por la elegida en Ajustes (máximo 3×).
            final mq = MediaQuery.of(context);
            final scale =
                (mq.textScaler.scale(1) * state.textScale).clamp(1.0, 3.0);
            return MediaQuery(
              data: mq.copyWith(textScaler: TextScaler.linear(scale)),
              child: VisionSimulator(mode: state.simulation, child: child!),
            );
          },
        ),
      ),
    );
  }
}
