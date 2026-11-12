import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';

class SonidosScreen extends ConsumerWidget {
  const SonidosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = ref.watch(appearanceProvider);
    final notif = ref.read(appearanceProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: const Text('Sonidos')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Efectos de sonido'),
            subtitle: const Text('Jugadas, capturas, aciertos y errores'),
            value: a.sonido,
            onChanged: (v) => notif.actualizar(a.copyWith(sonido: v)),
          ),
        ],
      ),
    );
  }
}
