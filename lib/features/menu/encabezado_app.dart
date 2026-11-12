import 'package:flutter/material.dart';

const String kNombreApp = 'Ajedrez: Combinaciones y Problemas';
const String kContacto = 'acproblemas@gmail.com';

/// Link al código fuente (si la aplicación se publica como software libre). Vacío = no se muestra.
const String kCodigoFuente = '';

/// Logo y nombre de la aplicación (arriba de la tarjeta de progreso):
/// logo, debajo "Ajedrez" y debajo "Combinaciones y Problemas".
class EncabezadoApp extends StatelessWidget {
  const EncabezadoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 18),
      child: Column(
        children: [
          Semantics(
            label: 'Logo de Ajedrez: Combinaciones y Problemas',
            image: true,
            child: Image.asset('assets/images/logo.png', height: 104, filterQuality: FilterQuality.medium),
          ),
          const SizedBox(height: 10),
          Text('Ajedrez', style: tt.headlineMedium),
          const SizedBox(height: 2),
          Text('Combinaciones y Problemas', style: tt.bodyLarge),
        ],
      ),
    );
  }
}

/// Botón chico "Acerca de" (abajo a la izquierda de la pantalla principal).
class BotonAcercaDe extends StatelessWidget {
  const BotonAcercaDe({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
          child: TextButton.icon(
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: const Icon(Icons.info_outline, size: 18),
            label: const Text('Acerca de'),
            onPressed: () => _mostrarAcercaDe(context),
          ),
        ),
      ),
    );
  }
}

/// (componente, autor, licencia)
const List<(String, String, String)> _creditos = [
  ('chessground', 'Lichess', 'GPL-3.0'),
  ('dartchess', 'Lichess', 'GPL-3.0'),
  ('Flutter / Dart', 'Google', 'BSD-3-Clause'),
  ('flutter_riverpod', 'Remi Rousselet', 'MIT'),
  ('shared_preferences', 'Equipo de Flutter', 'BSD-3-Clause'),
  ('audioplayers', 'Blue Fire', 'MIT'),
  ('google_fonts', 'Equipo de Flutter', 'Apache-2.0'),
  ('Base de datos de Lichess', 'Lichess (lichess.org)', 'CC0'),
];

void _mostrarAcercaDe(BuildContext context) {
  final tt = Theme.of(context).textTheme;
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Acerca de'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(kNombreApp, style: tt.titleMedium),
            const SizedBox(height: 10),
            const Text('Aplicación de ejercicios de Ajedrez para jugadores principiantes e intermedios, desarrollada por Ajedrez Berisso, Buenos Aires.'),
            const SizedBox(height: 10),
            const SizedBox(height: 14),
            Text('Contacto', style: tt.titleSmall),
            const SizedBox(height: 2),
            const SelectableText(kContacto),
            const SizedBox(height: 14),
            Text('Créditos y licencias', style: tt.titleSmall),
            const SizedBox(height: 4),
            for (final c in _creditos)
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: c.$1, style: const TextStyle(fontWeight: FontWeight.w600)),
                      TextSpan(text: ' · ${c.$2} · ${c.$3}'),
                    ],
                  ),
                  style: tt.bodySmall,
                ),
              ),
            if (kCodigoFuente.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text('Código fuente', style: tt.titleSmall),
              const SizedBox(height: 2),
              const SelectableText(kCodigoFuente),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar')),
      ],
    ),
  );
}
