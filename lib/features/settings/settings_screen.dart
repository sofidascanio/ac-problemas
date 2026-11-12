import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import 'apariencia_screen.dart';
import 'perfil_screen.dart';

/// Ajustes: Perfil y Apariencia, con el interruptor de Sonidos debajo.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ap = ref.watch(appearanceProvider);
    final notif = ref.read(appearanceProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _Modulo(
            icono: Icons.person_outline,
            titulo: 'Perfil',
            destino: PerfilScreen(),
          ),
          const _Modulo(
            icono: Icons.palette_outlined,
            titulo: 'Apariencia',
            destino: AparienciaScreen(),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Sonidos'),
            value: ap.sonido,
            onChanged: (v) => notif.actualizar(ap.copyWith(sonido: v)),
          ),
        ],
      ),
    );
  }
}

class _Modulo extends StatelessWidget {
  const _Modulo({required this.icono, required this.titulo, required this.destino});
  final IconData icono;
  final String titulo;
  final Widget destino;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () =>
            Navigator.push(context, MaterialPageRoute(builder: (_) => destino)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icono, size: 28),
              const SizedBox(width: 16),
              Expanded(child: Text(titulo, style: Theme.of(context).textTheme.titleMedium)),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
