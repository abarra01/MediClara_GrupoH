import 'package:flutter/widgets.dart';

/// Simulación de escala de grises y deficiencias de visión cromática.
///
/// Herramienta del EQUIPO (no del usuario final) para generar las evidencias
/// de la semana 4. Matrices de aproximación Viénot/Brettel habituales en
/// simuladores (aproximación; conviene contrastarla con el simulador de TPGi CCA).
enum VisionSim {
  none('Visión normal', null),
  grayscale('Escala de grises', [
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0, 0, 0, 1, 0,
  ]),
  protanopia('Protanopía (sin rojo)', [
    0.567, 0.433, 0, 0, 0, //
    0.558, 0.442, 0, 0, 0, //
    0, 0.242, 0.758, 0, 0, //
    0, 0, 0, 1, 0,
  ]),
  deuteranopia('Deuteranopía (sin verde)', [
    0.625, 0.375, 0, 0, 0, //
    0.7, 0.3, 0, 0, 0, //
    0, 0.3, 0.7, 0, 0, //
    0, 0, 0, 1, 0,
  ]),
  tritanopia('Tritanopía (sin azul)', [
    0.95, 0.05, 0, 0, 0, //
    0, 0.433, 0.567, 0, 0, //
    0, 0.475, 0.525, 0, 0, //
    0, 0, 0, 1, 0,
  ]);

  const VisionSim(this.label, this.matrix);
  final String label;
  final List<double>? matrix;
}

class VisionSimulator extends StatelessWidget {
  const VisionSimulator({super.key, required this.mode, required this.child});

  final VisionSim mode;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final m = mode.matrix;
    if (m == null) return child;
    return ColorFiltered(colorFilter: ColorFilter.matrix(m), child: child);
  }
}
