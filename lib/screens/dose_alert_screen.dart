import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/app_palette.dart';
import '../widgets/components.dart';

// ============================================================
// Pantalla 4 · ALERTA DE TOMA (recorrido 2: confirmar una toma)
// En la app final se abre a pantalla completa desde la notificación local
// (sonido + vibración + aviso visual, RF-05).
// ============================================================
class DoseAlertScreen extends StatelessWidget {
  const DoseAlertScreen({super.key, required this.medId});
  final int medId;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final p = AppPalette.of(context);
    final t = Theme.of(context).textTheme;
    final m = state.byId(medId);

    void take() {
      state.markTaken(m);
      Navigator.pop(context);
      showUndoBanner(context, state, m);
    }

    void snooze() {
      // 15 minutos desde AHORA (antes se sumaban a la hora programada y, si
      // la alerta se abría tarde, el aviso indicaba una hora ya pasada).
      final now = state.clock();
      final total = now.hour * 60 + now.minute + 15;
      final h = TimeOfDay(hour: (total ~/ 60) % 24, minute: total % 60);
      Navigator.pop(context);
      showInfoBanner(context, 'Te lo recordaremos a las ${hhmm(h)}');
    }

    return Scaffold(
      backgroundColor: p.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Gap.l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ExcludeSemantics(
                  child: Center(
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: p.primary, width: 4),
                      ),
                      child: Icon(m.type.icon, size: 64, color: p.primary),
                    ),
                  ),
                ),
                const SizedBox(height: Gap.l),
                Semantics(
                  header: true,
                  child: Text('Es la hora de tu medicación',
                      style: t.displaySmall, textAlign: TextAlign.center),
                ),
                const SizedBox(height: Gap.s),
                Text('${m.name} · ${m.dose} · ${hhmm(m.time)}',
                    style: t.titleLarge!.copyWith(color: p.textSecondary),
                    textAlign: TextAlign.center),
                const SizedBox(height: Gap.xl),
                // Acción principal: un BOTÓN grande (RNF-A06). Deslizar a la
                // derecha es solo un atajo secundario (decisión S3).
                GestureDetector(
                  onHorizontalDragEnd: (d) {
                    if ((d.primaryVelocity ?? 0) > 300) take();
                  },
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(88),
                      textStyle: t.headlineSmall,
                    ),
                    onPressed: take,
                    icon: const Icon(Icons.check, size: 34),
                    label: Text('Ya me lo he tomado',
                        semanticsLabel: 'Ya me he tomado ${m.name}'),
                  ),
                ),
                // 24 px entre las dos acciones para evitar pulsaciones erróneas.
                const SizedBox(height: Gap.l),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(64)),
                  onPressed: snooze,
                  icon: const Icon(Icons.snooze),
                  label: const Text('Recordar en 15 min',
                      semanticsLabel: 'Recordármelo dentro de 15 minutos'),
                ),
                const SizedBox(height: Gap.m),
                Text(
                  'También puedes deslizar «Ya me lo he tomado» hacia la derecha.',
                  style: t.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
