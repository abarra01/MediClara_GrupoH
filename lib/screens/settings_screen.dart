import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/app_palette.dart';
import '../widgets/components.dart';
import '../widgets/vision_simulator.dart';

// ============================================================
// Pantalla 6 · AJUSTES (accesibilidad y notificaciones)
// ============================================================
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final p = AppPalette.of(context);
    final t = Theme.of(context).textTheme;
    final isDark = s.themeMode == ThemeMode.dark ||
        (s.themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    // semanticContainer: false → cada fila es un elemento propio para TalkBack
    // y se lee en el orden visual (antes la tarjeta absorbía el texto de
    // «Sonido de la alarma» y lo anunciaba primero).
    Widget group(List<Widget> children) => Card(
          semanticContainer: false,
          clipBehavior: Clip.antiAlias,
          child: Column(children: children),
        );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Atrás',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Gap.m),
          children: [
            const ScreenTitle('Ajustes'),
            const SizedBox(height: Gap.m),
            group([
              SwitchListTile(
                value: s.soundOn,
                onChanged: s.setSound,
                title: const Text('Avisos con sonido'),
                subtitle: Text(
                    '${s.soundOn ? 'Activados' : 'Desactivados'}. La vibración y el aviso en pantalla siempre están activos.'),
              ),
              const Divider(height: 1),
              // Estado DESHABILITADO: se explica por qué y cómo activarlo.
              ListTile(
                title: Text('Sonido de la alarma',
                    style: t.titleMedium!
                        .copyWith(color: s.soundOn ? p.text : p.disabledText)),
                subtitle: Text(s.soundOn
                    ? s.alarmSound
                    : 'No disponible: activa «Avisos con sonido» para elegirlo.'),
                trailing: OutlinedButton(
                  onPressed: s.soundOn ? s.cycleAlarmSound : null,
                  child: const Text('Cambiar',
                      semanticsLabel: 'Cambiar el sonido de la alarma'),
                ),
              ),
            ]),
            const SizedBox(height: Gap.m),
            group([
              Padding(
                padding: const EdgeInsets.all(Gap.m),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                        header: true,
                        child: Text('Tamaño de la letra', style: t.titleMedium)),
                    const SizedBox(height: 4),
                    Text(
                        'Se suma al tamaño elegido en los ajustes del teléfono.',
                        style: t.bodySmall),
                    const SizedBox(height: Gap.s),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<double>(
                        segments: const [
                          ButtonSegment(value: 1.0, label: Text('Normal', semanticsLabel: 'Letra normal')),
                          ButtonSegment(value: 1.3, label: Text('Grande', semanticsLabel: 'Letra grande')),
                          ButtonSegment(value: 1.6, label: Text('Muy grande', semanticsLabel: 'Letra muy grande')),
                        ],
                        selected: {s.textScale},
                        onSelectionChanged: (v) => s.setTextScale(v.first),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              SwitchListTile(
                value: isDark,
                onChanged: s.setDark,
                title: const Text('Modo oscuro'),
                subtitle: Text(
                    '${isDark ? 'Activado' : 'Desactivado'}. Reduce el brillo por la noche.'),
              ),
            ]),
            // Herramienta del EQUIPO para las evidencias (no aparece en la
            // versión publicada: solo en modo depuración).
            if (kDebugMode) ...[
              const SizedBox(height: Gap.l),
              Semantics(
                header: true,
                child: Text('Revisión de accesibilidad (solo equipo)',
                    style: t.titleLarge),
              ),
              const SizedBox(height: Gap.xs),
              group([
                for (final v in VisionSim.values)
                  ListTile(
                    title: Text(v.label),
                    selected: s.simulation == v,
                    trailing: s.simulation == v
                        ? const Icon(Icons.check)
                        : const SizedBox.shrink(),
                    onTap: () => s.setSimulation(v),
                  ),
              ]),
            ],
          ],
        ),
      ),
    );
  }
}
