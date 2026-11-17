import 'package:flutter/material.dart';

import '../routes.dart';
import '../state/app_state.dart';
import '../theme/app_palette.dart';
import '../widgets/components.dart';

/// Contenedor con la navegación inferior: «Hoy» y «Mi botiquín».
/// Cada destino lleva icono + texto siempre visible.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.initialIndex = 0});
  final int initialIndex;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late int _index = widget.initialIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _index,
          children: const [TodayScreen(), CabinetScreen()],
        ),
      ),
      // Semana 5 (revisión cruzada T1): «Añadir medicamento» deja de ser un
      // botón flotante —tapaba el botón «Marcar como tomado» de las tarjetas—
      // y pasa a una barra fija sobre el menú. Mismo sitio (abajo), mismo
      // texto, y nunca se superpone a otro control.
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_index == 0) const _AddBar(),
          NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.today_outlined),
                selectedIcon: Icon(Icons.today),
                label: 'Hoy',
                tooltip: 'Medicación de hoy',
              ),
              NavigationDestination(
                icon: Icon(Icons.medical_services_outlined),
                selectedIcon: Icon(Icons.medical_services),
                label: 'Mi botiquín',
                tooltip: 'Todos mis tratamientos',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddBar extends StatelessWidget {
  const _AddBar();

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(top: BorderSide(color: p.divider)),
      ),
      padding: const EdgeInsets.fromLTRB(Gap.m, Gap.s, Gap.m, Gap.s),
      child: FilledButton.icon(
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
        onPressed: () => Navigator.pushNamed(context, Routes.add),
        icon: const Icon(Icons.add, size: 28),
        label: const Text('Añadir medicamento'),
      ),
    );
  }
}

// ============================================================
// Pantalla 1 · MEDICACIÓN DE HOY (recorrido 3: consultar resumen)
// ============================================================
class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final t = Theme.of(context).textTheme;
    final total = state.active.length;
    final done = state.takenCount;

    Future<void> take(Medication m) async {
      // Revisión cruzada T4: evitar marcar por error una toma lejana.
      final now = state.clock();
      final minutesLeft =
          (m.time.hour * 60 + m.time.minute) - (now.hour * 60 + now.minute);
      if (minutesLeft > 120) {
        final ok = await confirmEarly(context, m);
        if (ok != true || !context.mounted) return;
      }
      state.markTaken(m);
      showUndoBanner(context, state, m);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(Gap.m, Gap.m, Gap.m, Gap.l),
      children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: ScreenTitle('Medicación de hoy',
                subtitle: spanishDate(state.today())),
          ),
          IconButton.outlined(
            tooltip: 'Ajustes',
            onPressed: () => Navigator.pushNamed(context, Routes.settings),
            icon: const Icon(Icons.settings_outlined),
          ),
        ]),
        const SizedBox(height: Gap.m),
        // Progreso: el texto da la información; la barra es apoyo visual.
        Card(
          child: Padding(
            padding: const EdgeInsets.all(Gap.m),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$done de $total tomas hechas hoy', style: t.titleMedium),
                const SizedBox(height: Gap.xs),
                ExcludeSemantics(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                        value: total == 0 ? 0 : done / total),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: Gap.m),
        // Solo para demostrar el recorrido 2 sin esperar a la hora real.
        if (state.nextPending != null)
          OutlinedButton.icon(
            onPressed: () => Navigator.pushNamed(context, Routes.alert,
                arguments: state.nextPending!.id),
            icon: const Icon(Icons.notifications_active_outlined),
            label: const Text('Demostración: simular aviso de toma'),
          ),
        for (final moment in DayMoment.values) ...[
          const SizedBox(height: Gap.m),
          SectionHeader(icon: moment.icon, label: moment.label),
          const SizedBox(height: Gap.xs),
          if (state.todayAt(moment).isEmpty)
            _EmptyMoment(moment)
          else
            for (final m in state.todayAt(moment)) ...[
              MedicationCard(med: m, onTake: () => take(m)),
              const SizedBox(height: Gap.s),
            ],
        ],
      ],
    );
  }
}

class _EmptyMoment extends StatelessWidget {
  const _EmptyMoment(this.moment);
  final DayMoment moment;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Gap.m),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Gap.radius),
        border: Border.all(color: p.border, width: 1.5),
      ),
      child: Text(
        'No tienes tomas por la ${moment.label.toLowerCase()}',
        style: Theme.of(context)
            .textTheme
            .bodyLarge!
            .copyWith(color: p.textSecondary),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ============================================================
// Pantalla 5 · MI BOTIQUÍN (todos los tratamientos)
// ============================================================
class CabinetScreen extends StatelessWidget {
  const CabinetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final t = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(Gap.m),
      children: [
        const ScreenTitle('Mi botiquín',
            subtitle:
                'Todos tus tratamientos. Pulsa uno para editarlo o eliminarlo.'),
        const SizedBox(height: Gap.l),
        Semantics(
            header: true,
            child:
                Text('En uso (${state.active.length})', style: t.titleLarge)),
        const SizedBox(height: Gap.xs),
        for (final m in state.active) _CabinetTile(med: m),
        const SizedBox(height: Gap.m),
        Semantics(
            header: true,
            child: Text('Terminados (${state.finished.length})',
                style: t.titleLarge)),
        const SizedBox(height: Gap.xs),
        for (final m in state.finished) _CabinetTile(med: m),
      ],
    );
  }
}

class _CabinetTile extends StatelessWidget {
  const _CabinetTile({required this.med});
  final Medication med;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.xs),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: Gap.m, vertical: 4),
          leading: Pictogram(med.type),
          title: Text(med.name, style: Theme.of(context).textTheme.titleLarge),
          subtitle: med.active
              ? Text('${med.type.label} · cada día a las ${hhmm(med.time)}')
              : Row(children: [
                  Icon(Icons.task_alt, size: 20, color: p.textSecondary),
                  const SizedBox(width: 4),
                  const Flexible(child: Text('Tratamiento terminado')),
                ]),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showOptions(context, med),
        ),
      ),
    );
  }
}

/// Hoja de opciones. La acción destructiva va separada (zona inferior, 24 px
/// + divisor) y siempre pide confirmación.
void _showOptions(BuildContext context, Medication med) {
  final state = AppScope.of(context);
  final p = AppPalette.of(context);
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheet) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(Gap.m, 0, Gap.m, Gap.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(med.name,
                  style: Theme.of(sheet).textTheme.headlineSmall),
            ),
            const SizedBox(height: Gap.m),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(sheet);
                Navigator.pushNamed(context, Routes.add, arguments: med.id);
              },
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Editar horario o cantidad'),
            ),
            const SizedBox(height: Gap.xs),
            TextButton(
              onPressed: () => Navigator.pop(sheet),
              child: const Text('Cerrar'),
            ),
            const SizedBox(height: Gap.l),
            const Divider(),
            const SizedBox(height: Gap.m),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: p.error,
                iconColor: p.error,
                side: BorderSide(color: p.error, width: 2),
              ),
              onPressed: () async {
                Navigator.pop(sheet);
                final ok = await confirmDelete(context, med);
                if (ok == true) state.remove(med);
              },
              icon: const Icon(Icons.delete_outline),
              label: Text('Eliminar tratamiento',
                  semanticsLabel: 'Eliminar el tratamiento ${med.name}'),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Confirmación al marcar una toma con más de 2 horas de antelación.
/// La opción segura («No, esperar») es la principal.
Future<bool?> confirmEarly(BuildContext context, Medication med) {
  return showDialog<bool>(
    context: context,
    builder: (d) => AlertDialog(
      title: const Text('Aún no es la hora'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('${med.name} está programado a las ${hhmm(med.time)}. '
              '¿Quieres marcarlo como tomado igualmente?'),
          const SizedBox(height: Gap.l),
          FilledButton(
            onPressed: () => Navigator.pop(d, false),
            child: const Text('No, esperar'),
          ),
          const SizedBox(height: Gap.s),
          OutlinedButton(
            onPressed: () => Navigator.pop(d, true),
            child: const Text('Sí, ya lo he tomado'),
          ),
        ],
      ),
    ),
  );
}

/// Confirmación de borrado. La opción segura («No, mantener») va primero y
/// es la principal; la destructiva lleva icono de papelera y texto explícito.
Future<bool?> confirmDelete(BuildContext context, Medication med) {
  final p = AppPalette.of(context);
  return showDialog<bool>(
    context: context,
    builder: (d) => AlertDialog(
      title: Text('¿Eliminar ${med.name}?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
              'Se borrarán sus recordatorios. Esta acción no se puede deshacer.'),
          const SizedBox(height: Gap.l),
          FilledButton(
            onPressed: () => Navigator.pop(d, false),
            child: const Text('No, mantener'),
          ),
          const SizedBox(height: Gap.s),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: p.error,
              foregroundColor: p.surface,
            ),
            onPressed: () => Navigator.pop(d, true),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Sí, eliminar'),
          ),
        ],
      ),
    ),
  );
}
