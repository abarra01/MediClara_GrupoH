// Orden de lectura de TalkBack a partir del árbol semántico de Flutter.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// Devuelve una línea por cada elemento que TalkBack puede enfocar.
List<String> readingOrder(WidgetTester t) {
  var root = t.getSemantics(find.byType(Scaffold).first);
  while (root.parent != null) {
    root = root.parent!;
  }
  final out = <String>[];
  void visit(SemanticsNode n) {
    final d = n.getSemanticsData();
    final parts = <String>[];
    final text = [d.label, d.value, d.tooltip]
        .where((s) => s.trim().isNotEmpty)
        .map((s) => s.replaceAll('\n', ' '))
        .join(', ');
    if (text.isNotEmpty) {
      // ignore: deprecated_member_use
      bool f(SemanticsFlag x) => d.hasFlag(x);
      if (f(SemanticsFlag.isHeader)) parts.add('encabezado');
      if (f(SemanticsFlag.isButton)) parts.add('botón');
      if (f(SemanticsFlag.isTextField)) parts.add('campo de texto');
      if (f(SemanticsFlag.hasToggledState)) {
        parts.add(f(SemanticsFlag.isToggled) ? 'activado' : 'desactivado');
      }
      if (f(SemanticsFlag.hasSelectedState) && f(SemanticsFlag.isSelected)) {
        parts.add('seleccionado');
      }
      if (f(SemanticsFlag.hasEnabledState) && !f(SemanticsFlag.isEnabled)) {
        parts.add('desactivado (no disponible)');
      }
      if (f(SemanticsFlag.isLiveRegion)) parts.add('se anuncia al cambiar');
      if (d.hasAction(SemanticsAction.tap) &&
          !f(SemanticsFlag.isButton) &&
          !f(SemanticsFlag.isTextField)) {
        parts.add('pulsable');
      }
      if (d.hint.isNotEmpty) parts.add('pista: ${d.hint}');
      out.add('«$text»${parts.isEmpty ? '' : ' — ${parts.join(', ')}'}');
    }
    // Si este nodo fusiona a sus hijos, TalkBack los lee como uno solo.
    if (n.mergeAllDescendantsIntoThisNode) return;
    // ignore: invalid_use_of_visible_for_testing_member
    for (final c
        in n.debugListChildrenInOrder(DebugSemanticsDumpOrder.traversalOrder)) {
      visit(c);
    }
  }

  visit(root);
  return out;
}
