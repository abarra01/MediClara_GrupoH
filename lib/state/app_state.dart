import 'package:flutter/material.dart';

import '../widgets/vision_simulator.dart';

/// Tipos de medicamento con pictograma estándar + nombre visible (RF-01).
enum MedType {
  pastilla('Pastilla', Icons.medication),
  jarabe('Jarabe', Icons.water_drop_outlined),
  inyeccion('Inyección', Icons.vaccines_outlined);

  const MedType(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// Momento del día en el que se agrupa una toma en «Medicación de hoy».
enum DayMoment {
  manana('Mañana', Icons.wb_sunny_outlined),
  tarde('Tarde', Icons.wb_twilight),
  noche('Noche', Icons.bedtime_outlined);

  const DayMoment(this.label, this.icon);
  final String label;
  final IconData icon;

  static DayMoment of(TimeOfDay t) => t.hour < 14
      ? DayMoment.manana
      : t.hour < 20
          ? DayMoment.tarde
          : DayMoment.noche;
}

class Medication {
  Medication({
    required this.id,
    required this.name,
    required this.type,
    required this.time,
    required this.dose,
    this.note,
    this.active = true,
    this.takenAt,
  });

  final int id;
  String name;
  MedType type;
  TimeOfDay time;
  String dose;
  String? note;
  bool active;

  /// Hora a la que se marcó como tomada hoy (null = pendiente).
  TimeOfDay? takenAt;

  bool get isTaken => takenAt != null;
}

String hhmm(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

/// Estado local de la aplicación. Todo se guarda en el dispositivo
/// (RNF-O03: sin llamadas a servicios externos).
class AppState extends ChangeNotifier {
  AppState({
    List<Medication>? meds,
    TimeOfDay Function()? clock,
    DateTime Function()? today,
  })  : meds = meds ?? [],
        clock = clock ?? TimeOfDay.now,
        today = today ?? DateTime.now;

  /// Datos de demostración usados en el prototipo y en las pruebas.
  factory AppState.demo(
          {TimeOfDay Function()? clock, DateTime Function()? today}) =>
      AppState(
        clock: clock,
        today: today,
        meds: [
          Medication(
              id: 1,
              name: 'Enalapril',
              type: MedType.pastilla,
              time: const TimeOfDay(hour: 8, minute: 0),
              dose: '1 pastilla',
              note: 'para la tensión',
              takenAt: const TimeOfDay(hour: 8, minute: 5)),
          Medication(
              id: 2,
              name: 'Paracetamol',
              type: MedType.pastilla,
              time: const TimeOfDay(hour: 9, minute: 0),
              dose: '1 pastilla'),
          Medication(
              id: 3,
              name: 'Atorvastatina',
              type: MedType.pastilla,
              time: const TimeOfDay(hour: 22, minute: 0),
              dose: '1 pastilla',
              note: 'para el colesterol'),
          Medication(
              id: 4,
              name: 'Amoxicilina',
              type: MedType.jarabe,
              time: const TimeOfDay(hour: 13, minute: 0),
              dose: '5 ml',
              active: false),
        ],
      );

  final List<Medication> meds;
  final TimeOfDay Function() clock;
  final DateTime Function() today;

  // ---- Ajustes ----
  bool soundOn = true;
  String alarmSound = 'Campana suave';
  ThemeMode themeMode = ThemeMode.system;

  /// Factor de letra interno; se MULTIPLICA por el del sistema (RNF-A03).
  double textScale = 1.0;

  /// Solo para el equipo: simulación de visión cromática (evidencias S4).
  VisionSim simulation = VisionSim.none;

  List<Medication> get active =>
      meds.where((m) => m.active).toList()..sort(_byTime);
  List<Medication> get finished => meds.where((m) => !m.active).toList();
  List<Medication> todayAt(DayMoment moment) =>
      active.where((m) => DayMoment.of(m.time) == moment).toList();
  int get takenCount => active.where((m) => m.isTaken).length;
  Medication? get nextPending => active.where((m) => !m.isTaken).firstOrNull;
  Medication byId(int id) => meds.firstWhere((m) => m.id == id);

  static int _byTime(Medication a, Medication b) =>
      (a.time.hour * 60 + a.time.minute) - (b.time.hour * 60 + b.time.minute);

  // ---- Recorrido 2: confirmar una toma ----
  void markTaken(Medication m) {
    m.takenAt = clock();
    notifyListeners();
  }

  /// RF-06: deshacer la confirmación.
  void undoTaken(Medication m) {
    m.takenAt = null;
    notifyListeners();
  }

  // ---- Recorrido 1: añadir medicamento ----
  Medication add({
    required String name,
    required MedType type,
    required TimeOfDay time,
    required String dose,
  }) {
    final next = meds.isEmpty
        ? 1
        : meds.map((m) => m.id).reduce((a, b) => a > b ? a : b) + 1;
    final m =
        Medication(id: next, name: name, type: type, time: time, dose: dose);
    meds.add(m);
    notifyListeners();
    return m;
  }

  void update(Medication m,
      {required String name,
      required MedType type,
      required TimeOfDay time,
      required String dose}) {
    m
      ..name = name
      ..type = type
      ..time = time
      ..dose = dose;
    notifyListeners();
  }

  void remove(Medication m) {
    meds.remove(m);
    notifyListeners();
  }

  // ---- Ajustes ----
  void setSound(bool v) {
    soundOn = v;
    notifyListeners();
  }

  void cycleAlarmSound() {
    const sounds = ['Campana suave', 'Timbre', 'Melodía'];
    alarmSound = sounds[(sounds.indexOf(alarmSound) + 1) % sounds.length];
    notifyListeners();
  }

  void setDark(bool v) {
    themeMode = v ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void setTextScale(double v) {
    textScale = v;
    notifyListeners();
  }

  void setSimulation(VisionSim v) {
    simulation = v;
    notifyListeners();
  }
}

/// Da acceso al estado desde cualquier widget sin paquetes externos.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
      : super(notifier: state);

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
}

/// Fecha en español sin dependencias («Martes, 10 de noviembre»).
String spanishDate(DateTime d) {
  const days = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo'
  ];
  const months = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre'
  ];
  return '${days[d.weekday - 1]}, ${d.day} de ${months[d.month - 1]}';
}
