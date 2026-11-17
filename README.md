# MediClara · Grupo H · Accesibilidad 2026/27

App Flutter para registrar, consultar y confirmar la medicación diaria, diseñada
para personas mayores con vista cansada y para usuarios de TalkBack.

## Recorridos críticos (semana 1)

1. **Añadir un medicamento**: «Añadir medicamento» → formulario → «Guardar medicamento».
2. **Confirmar una toma**: alerta «Es la hora de tu medicación» → «Ya me lo he tomado»
   (o «Marcar como tomado» en la tarjeta) → aviso superior con «Deshacer».
3. **Consultar el resumen del día**: pantalla «Medicación de hoy» (Mañana / Tarde / Noche).

Los datos son locales y simulados (sin servidor). La alerta se abre con
«Demostración: simular aviso de toma».

## Ejecutar

```bash
flutter pub get
flutter run                 # móvil/emulador Android (o -d chrome)
flutter build apk --release # APK instalable para la prueba con TalkBack
```

## Pruebas

```bash
flutter test                # 60 pruebas: 48×48, etiquetas, contraste, texto al 200 %,
                            # recorridos, orden de lectura y semántica
flutter test test_evidencias --update-goldens   # regenera capturas y orden de lectura
```

## Estructura

| Carpeta | Contenido |
|---|---|
| `lib/theme/` | Paleta medida (claro/oscuro) y tema: tipografía Atkinson Hyperlegible, botones ≥ 48×48 |
| `lib/screens/` | Las 6 pantallas del mapa de navegación de la semana 3 |
| `lib/widgets/components.dart` | Componentes reutilizables con su semántica (tarjeta de toma, estado, avisos) |
| `test/` | Pruebas automáticas de accesibilidad y de los recorridos |
| `test_evidencias/` | Generadores de capturas y del orden de lectura de TalkBack |
