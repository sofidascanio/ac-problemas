# AC Problemas — Ajedrez: Combinaciones y Problemas

Aplicación de ejercicios de ajedrez para jugadores principiantes e intermedios, desarrollada por Ajedrez Berisso,
Buenos Aires. Hecha con Flutter. Todo el contenido está en la app y el progreso se guarda en el dispositivo.

Contacto: acproblemas@gmail.com

## Compilar
1. Instalar Flutter (canal estable) y Android Studio.
2. `flutter pub get`
3. `flutter run` (o `flutter build appbundle --release` con tu propio keystore; ver `android/`).

Los problemas están en `assets/data/` y el menú en `assets/data/menu.json`. Las carpetas de `assets/data/` se
declaran en `pubspec.yaml` con `python sincronizar_assets.py`.

## Licencia
Software libre bajo GNU GPL v3 o posterior (ver `LICENSE`). Usa `chessground` y `dartchess` (Lichess, GPL-3.0).
Las licencias de las demás dependencias y los créditos están en `AVISOS_DE_TERCEROS.md` y en la app
(Acerca de). El nombre y el logo de «AC Problemas» son de Ajedrez Berisso [COMPLETAR condiciones].

## Créditos
Base de datos de Lichess (lichess.org), CC0.
