import 'package:flutter/material.dart';

import '../routes.dart';
import '../state/app_state.dart';
import '../theme/app_palette.dart';

// ============================================================
// Pantalla 3 · GUARDADO CON ÉXITO
// Confirma QUÉ se ha guardado (no solo «OK») para que el usuario
// pueda comprobarlo sin volver atrás.
// ============================================================
class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key, required this.medId});
  final int medId;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final t = Theme.of(context).textTheme;
    final m = AppScope.of(context).byId(medId);

    Widget row(String k, String v) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: MergeSemantics(
            child: Wrap(spacing: Gap.xs, children: [
              Text('$k:', style: t.bodyLarge!.copyWith(color: p.textSecondary)),
              Text(v, style: t.titleMedium),
            ]),
          ),
        );

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Gap.l),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(Gap.l),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: p.successContainer,
                          shape: BoxShape.circle,
                          border: Border.all(color: p.success, width: 3),
                        ),
                        child: Icon(Icons.check, size: 60, color: p.success),
                      ),
                    ),
                    const SizedBox(height: Gap.m),
                    Semantics(
                      header: true,
                      liveRegion: true,
                      child: Text('Medicamento guardado',
                          style: t.headlineSmall, textAlign: TextAlign.center),
                    ),
                    const SizedBox(height: Gap.m),
                    Container(
                      padding: const EdgeInsets.all(Gap.m),
                      decoration: BoxDecoration(
                        color: p.background,
                        borderRadius: BorderRadius.circular(Gap.radius),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          row('Nombre', m.name),
                          row('Tipo', m.type.label),
                          row('Hora', hhmm(m.time)),
                          row('Cantidad', m.dose),
                        ],
                      ),
                    ),
                    const SizedBox(height: Gap.l),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(64)),
                      onPressed: () =>
                          Navigator.popUntil(context, (r) => r.isFirst),
                      icon: const Icon(Icons.today),
                      label: const Text('Ver medicación de hoy'),
                    ),
                    const SizedBox(height: Gap.s),
                    OutlinedButton.icon(
                      onPressed: () =>
                          Navigator.pushReplacementNamed(context, Routes.add),
                      icon: const Icon(Icons.add),
                      label: const Text('Añadir otro'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
