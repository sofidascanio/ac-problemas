import 'package:flutter/foundation.dart';

/// Suma al listado de la pantalla "Licencias" de Flutter los avisos que no vienen de paquetes de Dart.
/// (Flutter ya incluye solo la licencia de cada paquete: chessground, dartchess, etc.)
/// Llamar una vez en main(), antes de runApp().
void registrarLicencias() {
  LicenseRegistry.addLicense(() async* {
    yield const LicenseEntryWithLineBreaks(
      ['Problemas de la base de datos de Lichess'],
      'Los problemas y partidas provenientes de la base de datos abierta de Lichess '
      '(https://database.lichess.org) están publicados por Lichess bajo licencia CC0 (dominio público).',
    );
    yield const LicenseEntryWithLineBreaks(
      ['Fuentes Inter y Nunito'],
      'Copyright The Inter Project Authors. Copyright The Nunito Project Authors.\n\n'
      'Licenciadas bajo la SIL Open Font License, Versión 1.1: https://openfontlicense.org',
    );
    yield const LicenseEntryWithLineBreaks(
      ['Sonidos'],
      'Los efectos de sonido fueron generados especialmente para esta aplicación.',
    );
  });
}
