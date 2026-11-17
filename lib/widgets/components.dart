import 'dart:async';

import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/app_palette.dart';

/// Título de pantalla dentro del contenido (no en la AppBar) para que pueda
/// crecer en varias líneas con texto al 200 % sin cortarse (RNF-A03).
/// Se marca como encabezado para la navegación por encabezados de TalkBack.
class ScreenTitle extends StatelessWidget {
  const ScreenTitle(this.text, {super.key, this.subtitle});
  final String text;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // container: el subtítulo (fecha o instrucciones) no se mezcla con el
        // encabezado; TalkBack lo lee como elemento aparte.
        Semantics(
            container: true,
            header: true,
            child: Text(text, style: t.headlineSmall)),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Semantics(
              container: true, child: Text(subtitle!, style: t.bodySmall)),
        ],
      ],
    );
  }
}

/// Encabezado de sección (Mañana / Tarde / Noche): icono + texto.
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: Gap.xs),
      child: Semantics(
        header: true,
        child: Row(children: [
          ExcludeSemantics(child: Icon(icon, size: 26)),
          const SizedBox(width: Gap.xs),
          Expanded(
              child:
                  Text(label, style: Theme.of(context).textTheme.titleLarge)),
        ]),
      ),
    );
  }
}

/// Estado de una toma. Color + ICONO + TEXTO: en escala de grises o con
/// daltonismo el estado se sigue leyendo (RNF-A05).
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.med});
  final Medication med;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final done = med.isTaken;
    final fg = done ? p.success : p.pending;
    final bg = done ? p.successContainer : p.pendingContainer;
    final label = done
        ? 'Tomado a las ${hhmm(med.takenAt!)}'
        : 'Pendiente · ${hhmm(med.time)}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(done ? Icons.check_circle : Icons.schedule, size: 22, color: fg),
        const SizedBox(width: 6),
        Flexible(
          child: Text(label,
              style:
                  Theme.of(context).textTheme.labelMedium!.copyWith(color: fg)),
        ),
      ]),
    );
  }
}

/// Pictograma circular del tipo de medicamento (decorativo para TalkBack:
/// el tipo se anuncia por texto).
class Pictogram extends StatelessWidget {
  const Pictogram(this.type, {super.key, this.size = 48});
  final MedType type;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: p.background,
          shape: BoxShape.circle,
          border: Border.all(color: p.divider),
        ),
        child: Icon(type.icon, color: p.text, size: size * 0.55),
      ),
    );
  }
}

/// Tarjeta de una toma del día. Lectura TalkBack agrupada:
/// «Paracetamol, 1 pastilla a las 09:00, Pendiente» + botón con nombre propio.
class MedicationCard extends StatelessWidget {
  const MedicationCard({super.key, required this.med, required this.onTake});
  final Medication med;
  final VoidCallback onTake;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final t = Theme.of(context).textTheme;
    final details =
        [med.dose, hhmm(med.time), if (med.note != null) med.note!].join(' · ');
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
                color: med.isTaken ? p.success : p.pending, width: 6),
          ),
        ),
        padding: const EdgeInsets.all(Gap.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TalkBack lee una frase natural en lugar de los fragmentos visuales
            // («Paracetamol 1 pastilla · 09:00 Pendiente · 09:00»).
            Semantics(
              label: _spoken(med),
              excludeSemantics: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Pictogram(med.type),
                    const SizedBox(width: Gap.s),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(med.name, style: t.titleLarge),
                          Text(details, style: t.bodySmall),
                        ],
                      ),
                    ),
                  ]),
                  const SizedBox(height: Gap.s),
                  StatusChip(med: med),
                ],
              ),
            ),
            if (!med.isTaken) ...[
              const SizedBox(height: Gap.s),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onTake,
                  icon: const Icon(Icons.check),
                  label: Text('Marcar como tomado',
                      semanticsLabel: 'Marcar ${med.name} como tomado'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Frase que anuncia TalkBack para una toma.
String _spoken(Medication m) {
  final note = m.note != null ? ', ${m.note}' : '';
  final state = m.isTaken ? 'Tomado a las ${hhmm(m.takenAt!)}' : 'Pendiente';
  return '${m.name}: ${m.dose} a las ${hhmm(m.time)}$note. $state.';
}

/// Aviso SUPERIOR con «Deshacer» (decisión de la semana 3: el aviso inferior
/// pasaba desapercibido). Permanece 10 s —más del doble de los 5 s fijados
/// en la semana 2— y se anuncia a TalkBack como región viva.
int _bannerToken = 0;

void showUndoBanner(BuildContext context, AppState state, Medication med) {
  final messenger = ScaffoldMessenger.of(context);
  final p = AppPalette.of(context);
  final token = ++_bannerToken;
  messenger.hideCurrentMaterialBanner();
  messenger.showMaterialBanner(MaterialBanner(
    backgroundColor: p.banner,
    leading: Icon(Icons.check_circle, color: p.onBanner, size: 28),
    padding: const EdgeInsets.fromLTRB(Gap.m, Gap.s, Gap.xs, Gap.xs),
    content: Semantics(
      liveRegion: true,
      child: Text('${med.name} marcado como tomado a las ${hhmm(med.takenAt!)}',
          style: Theme.of(context)
              .textTheme
              .titleMedium!
              .copyWith(color: p.onBanner)),
    ),
    actions: [
      OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.bannerAction,
          iconColor: p.bannerAction,
          backgroundColor: Colors.transparent,
          side: BorderSide(color: p.bannerAction, width: 2),
        ),
        onPressed: () {
          state.undoTaken(med);
          messenger.hideCurrentMaterialBanner();
        },
        icon: const Icon(Icons.undo),
        label: Text('Deshacer',
            semanticsLabel: 'Deshacer: ${med.name} vuelve a pendiente'),
      ),
      // Con TalkBack el aviso no se cierra solo: debe poder cerrarse sin
      // deshacer la toma (si no, quedaba fijo encima de todas las pantallas).
      TextButton(
        style: TextButton.styleFrom(foregroundColor: p.bannerAction),
        onPressed: messenger.hideCurrentMaterialBanner,
        child: const Text('Cerrar', semanticsLabel: 'Cerrar el aviso'),
      ),
    ],
  ));
  // Revisión cruzada (T3): con TalkBack activo el aviso NO se cierra solo,
  // para que dé tiempo a llegar al botón «Deshacer».
  if (MediaQuery.of(context).accessibleNavigation) return;
  Timer(const Duration(seconds: 10), () {
    if (token == _bannerToken) messenger.hideCurrentMaterialBanner();
  });
}

/// Aviso informativo superior sin acción de deshacer (p. ej. «Posponer»).
void showInfoBanner(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.of(context);
  final p = AppPalette.of(context);
  final token = ++_bannerToken;
  messenger.hideCurrentMaterialBanner();
  messenger.showMaterialBanner(MaterialBanner(
    backgroundColor: p.banner,
    leading: Icon(Icons.info_outline, color: p.onBanner, size: 28),
    content: Semantics(
      liveRegion: true,
      child: Text(message,
          style: Theme.of(context)
              .textTheme
              .titleMedium!
              .copyWith(color: p.onBanner)),
    ),
    actions: [
      TextButton(
        style: TextButton.styleFrom(foregroundColor: p.bannerAction),
        onPressed: messenger.hideCurrentMaterialBanner,
        child: const Text('Entendido'),
      ),
    ],
  ));
  Timer(const Duration(seconds: 10), () {
    if (token == _bannerToken) messenger.hideCurrentMaterialBanner();
  });
}
