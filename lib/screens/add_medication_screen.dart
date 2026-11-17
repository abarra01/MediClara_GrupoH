import 'package:flutter/material.dart';

import '../routes.dart';
import '../state/app_state.dart';
import '../theme/app_palette.dart';

// ============================================================
// Pantalla 2 · AÑADIR / EDITAR MEDICAMENTO (recorrido 1)
// ============================================================
class AddMedicationScreen extends StatefulWidget {
  const AddMedicationScreen(
      {super.key, this.editId, this.showErrorsOnStart = false});

  /// Si no es null, se edita un medicamento existente.
  final int? editId;

  /// Solo para generar la evidencia del estado de error.
  final bool showErrorsOnStart;

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _name = TextEditingController();
  final _dose = TextEditingController(text: '1 pastilla');
  final _nameFocus = FocusNode();
  final _doseFocus = FocusNode();
  MedType _type = MedType.pastilla;
  TimeOfDay _time = const TimeOfDay(hour: 9, minute: 0);
  String? _nameError;
  String? _doseError;
  bool _dirty = false;
  Medication? _editing;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.editId != null && _editing == null) {
      _editing = AppScope.of(context).byId(widget.editId!);
      _name.text = _editing!.name;
      _dose.text = _editing!.dose;
      _type = _editing!.type;
      _time = _editing!.time;
    }
    if (widget.showErrorsOnStart && _nameError == null) _validate();
  }

  @override
  void dispose() {
    _name.dispose();
    _dose.dispose();
    _nameFocus.dispose();
    _doseFocus.dispose();
    super.dispose();
  }

  /// Mensajes de error: qué ha pasado + cómo corregirlo (sin jerga).
  bool _validate() {
    final n = _name.text.trim();
    final d = _dose.text.trim();
    _nameError = n.isEmpty
        ? 'Falta el nombre. Escríbelo como aparece en la caja, por ejemplo «Paracetamol».'
        : n.length > 60
            ? 'El nombre es demasiado largo. Usa como máximo 60 letras.'
            : null;
    _doseError = d.isEmpty
        ? 'Falta la cantidad. Escribe cuánto tomas cada vez, por ejemplo «1 pastilla».'
        : null;
    return _nameError == null && _doseError == null;
  }

  void _save() {
    final state = AppScope.of(context);
    if (!_validate()) {
      // Los datos escritos NO se borran (RF-02 / RNF-O04); el foco va al
      // primer campo con error para TalkBack y teclado.
      setState(() {});
      (_nameError != null ? _nameFocus : _doseFocus).requestFocus();
      return;
    }
    final Medication m;
    if (_editing != null) {
      state.update(_editing!,
          name: _name.text.trim(),
          type: _type,
          time: _time,
          dose: _dose.text.trim());
      m = _editing!;
    } else {
      m = state.add(
          name: _name.text.trim(),
          type: _type,
          time: _time,
          dose: _dose.text.trim());
    }
    _dirty = false;
    Navigator.pushReplacementNamed(context, Routes.saved, arguments: m.id);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _time,
      // Entrada por teclado: evita el gesto de arrastre preciso del reloj.
      initialEntryMode: TimePickerEntryMode.input,
      helpText: 'Hora de la toma',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
      builder: (c, child) => MediaQuery(
        data: MediaQuery.of(c).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (t != null)
      setState(() {
        _time = t;
        _dirty = true;
      });
  }

  /// Salir sin guardar: si hay datos escritos se pide confirmación.
  Future<bool> _confirmDiscard() async {
    if (!_dirty) return true;
    final r = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('¿Salir sin guardar?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Lo que has escrito se perderá.'),
            const SizedBox(height: Gap.l),
            FilledButton(
                onPressed: () => Navigator.pop(d, false),
                child: const Text('Seguir editando')),
            const SizedBox(height: Gap.s),
            OutlinedButton(
                onPressed: () => Navigator.pop(d, true),
                child: const Text('Salir sin guardar')),
          ],
        ),
      ),
    );
    return r ?? false;
  }

  Future<void> _leave() async {
    if (await _confirmDiscard() && mounted) {
      _dirty = false;
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final t = Theme.of(context).textTheme;
    final hasErrors = _nameError != null || _doseError != null;
    final errorCount = [_nameError, _doseError].whereType<String>().length;

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        appBar: AppBar(
          // Decisión S3: «Atrás» + «Cancelar» visible con texto.
          leading: IconButton(
            tooltip: 'Atrás',
            icon: const Icon(Icons.arrow_back),
            onPressed: _leave,
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: Gap.m),
              child: OutlinedButton.icon(
                onPressed: _leave,
                icon: const Icon(Icons.close),
                label: const Text('Cancelar'),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(Gap.m),
            children: [
              Semantics(
                header: true,
                child: Text(
                  _editing == null
                      ? 'Añadir medicamento'
                      : 'Editar ${_editing!.name}',
                  style: t.headlineSmall,
                ),
              ),
              const SizedBox(height: Gap.m),
              if (hasErrors) ...[
                _ErrorSummary(count: errorCount),
                const SizedBox(height: Gap.m),
              ],
              _Field(
                label: 'Nombre del medicamento',
                requiredField: true,
                child: TextField(
                  controller: _name,
                  focusNode: _nameFocus,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  style: t.bodyLarge,
                  onChanged: (_) => setState(() {
                    _dirty = true;
                    if (_nameError != null) _validate();
                  }),
                  decoration: InputDecoration(
                    hintText: 'Ej.: Paracetamol',
                    // `error` (widget) en lugar de `errorText`: con errorText
                    // Flutter añade además el mensaje como «pista» y, al
                    // fusionar etiqueta y campo, TalkBack lo leía dos veces.
                    error: _nameError == null ? null : Text(_nameError!),
                    suffixIcon: _nameError != null
                        ? Icon(Icons.error_outline, color: p.error)
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: Gap.l),
              _TypeSelector(
                value: _type,
                onChanged: (v) => setState(() {
                  _type = v;
                  _dirty = true;
                }),
              ),
              const SizedBox(height: Gap.l),
              _Field(
                label: 'Hora de la toma',
                helper:
                    'Te avisaremos con sonido, vibración y un mensaje en pantalla.',
                child: _TimeButton(time: _time, onPressed: _pickTime),
              ),
              const SizedBox(height: Gap.l),
              _Field(
                label: 'Cantidad en cada toma',
                requiredField: true,
                child: TextField(
                  controller: _dose,
                  focusNode: _doseFocus,
                  style: t.bodyLarge,
                  onChanged: (_) => setState(() {
                    _dirty = true;
                    if (_doseError != null) _validate();
                  }),
                  decoration: InputDecoration(
                    hintText: 'Ej.: 1 pastilla',
                    // `error` (widget) en lugar de `errorText`: con errorText
                    // Flutter añade además el mensaje como «pista» y, al
                    // fusionar etiqueta y campo, TalkBack lo leía dos veces.
                    error: _doseError == null ? null : Text(_doseError!),
                    suffixIcon: _doseError != null
                        ? Icon(Icons.error_outline, color: p.error)
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: Gap.xl),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Container(
            decoration: BoxDecoration(
              color: p.surface,
              border: Border(top: BorderSide(color: p.divider)),
            ),
            padding: const EdgeInsets.all(Gap.m),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(64)),
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: Text(
                  _editing == null ? 'Guardar medicamento' : 'Guardar cambios'),
            ),
          ),
        ),
      ),
    );
  }
}

/// Resumen de errores arriba del formulario: icono + título + explicación.
class _ErrorSummary extends StatelessWidget {
  const _ErrorSummary({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final t = Theme.of(context).textTheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(Gap.m),
        decoration: BoxDecoration(
          color: p.errorContainer,
          borderRadius: BorderRadius.circular(Gap.radius),
          border: Border.all(color: p.error, width: 2),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.warning_amber_rounded, color: p.error, size: 28),
          const SizedBox(width: Gap.s),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('No se ha podido guardar',
                  style: t.titleMedium!.copyWith(color: p.error)),
              const SizedBox(height: 4),
              Text(
                count == 1
                    ? 'Revisa el campo marcado abajo. Lo demás que has escrito se ha conservado.'
                    : 'Revisa los $count campos marcados abajo. Lo demás que has escrito se ha conservado.',
                style: t.bodyLarge!.copyWith(color: p.error),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// Campo con etiqueta VISIBLE y persistente encima (no un placeholder que
/// desaparece). MergeSemantics une la etiqueta con el campo para TalkBack.
class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.child,
    this.helper,
    this.requiredField = false,
  });
  final String label;
  final String? helper;
  final bool requiredField;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(TextSpan(children: [
            TextSpan(text: label, style: t.titleMedium),
            if (requiredField)
              TextSpan(text: ' (obligatorio)', style: t.bodySmall),
          ])),
          const SizedBox(height: Gap.xs),
          child,
          if (helper != null) ...[
            const SizedBox(height: 6),
            Text(helper!, style: t.bodySmall),
          ],
        ],
      ),
    );
  }
}

class _TimeButton extends StatelessWidget {
  const _TimeButton({required this.time, required this.onPressed});
  final TimeOfDay time;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final t = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: '${hhmm(time)}. Pulsa para cambiar la hora',
      excludeSemantics: true,
      child: Material(
        color: p.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Gap.radius),
          side: BorderSide(color: p.border, width: 2),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(Gap.radius),
          onTap: onPressed,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: Gap.m, vertical: Gap.s),
              child: Row(children: [
                Icon(Icons.schedule, color: p.text),
                const SizedBox(width: Gap.s),
                Expanded(child: Text(hhmm(time), style: t.titleLarge)),
                Text('Cambiar',
                    style: t.labelLarge!.copyWith(color: p.primary)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// Selector del tipo: tarjetas con pictograma + nombre. La opción elegida
/// se distingue por borde grueso, marca ✓ y negrita, no solo por el color.
class _TypeSelector extends StatelessWidget {
  const _TypeSelector({required this.value, required this.onChanged});
  final MedType value;
  final ValueChanged<MedType> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final t = Theme.of(context).textTheme;
    final big = MediaQuery.textScalerOf(context).scale(1) > 1.4;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
            header: false,
            child: Text('Tipo de medicamento', style: t.titleMedium)),
        const SizedBox(height: Gap.xs),
        LayoutBuilder(builder: (context, c) {
          // Con letra muy grande, una opción por fila para no cortar el texto.
          final w = big ? c.maxWidth : (c.maxWidth - 2 * Gap.xs) / 3;
          return Wrap(
            spacing: Gap.xs,
            runSpacing: Gap.xs,
            children: [
              for (final type in MedType.values)
                SizedBox(
                  width: w,
                  child: Semantics(
                    inMutuallyExclusiveGroup: true,
                    selected: type == value,
                    button: true,
                    label: 'Tipo: ${type.label}',
                    excludeSemantics: true,
                    child: Material(
                      color: p.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Gap.radius),
                        side: BorderSide(
                          color: type == value ? p.primary : p.border,
                          width: type == value ? 4 : 2,
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(Gap.radius),
                        onTap: () => onChanged(type),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 88),
                          child: Stack(children: [
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(Gap.xs),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(type.icon, size: 32, color: p.text),
                                    const SizedBox(height: 4),
                                    Text(type.label,
                                        textAlign: TextAlign.center,
                                        style: type == value
                                            ? t.labelMedium
                                            : t.bodySmall!
                                                .copyWith(color: p.text)),
                                  ],
                                ),
                              ),
                            ),
                            if (type == value)
                              Positioned(
                                top: 6,
                                right: 6,
                                child: Container(
                                  decoration: BoxDecoration(
                                      color: p.primary, shape: BoxShape.circle),
                                  padding: const EdgeInsets.all(2),
                                  child: Icon(Icons.check,
                                      size: 18, color: p.onPrimary),
                                ),
                              ),
                          ]),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        }),
      ],
    );
  }
}
