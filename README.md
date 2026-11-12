# ajedrez_app

## Puesta en marcha (Windows / Android Studio)
1. `flutter create --project-name ajedrez_app --platforms=android,ios ajedrez_app`
2. Copiar encima `lib/`, `assets/`, `test/` y `pubspec.yaml` de este zip.
3. `flutter pub get` y luego `flutter analyze`.

## Verificar (escrito sin poder compilar)
- API de chessground/dartchess (`BoardTheme`, `PieceSet`, `ChessboardSettings`, `GameData`,
  `Chessboard.fixed`, `Square.rank`, `makeSan`, `normalizeMove`) según la versión resuelta.
  Si `flutter analyze` marca algo, ajustar en `appearance_state.dart`, `validators.dart`
  y `actividad_view.dart`.
- Algunos temas de tablero de chessground usan imagen de fondo: revisar en Ajustes.
- Los FEN/soluciones de ejemplo están hechos a mano: validarlos con python-chess.
- Categorías sin JSON (protección aparte, Mate en 3, Táctica avanzadas) muestran "Próximamente".

## TODOs
- Tests de validadores (`test/validators_test.dart`).
- Accesibilidad: `Semantics` en el tablero (ver `actividad_view.dart`).
- Pantalla "Disposición del tablero" (fuera del modelo Actividad).
- Consignas por categoría; `dejaPiezaDefendida` es una interpretación (ver validators.dart).
- Contenido real desde el pipeline PGN -> JSON (formato: `{"actividades":[...]}`).
