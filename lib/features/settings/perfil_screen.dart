import 'package:chessground/chessground.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/dialogos.dart';
import '../../core/providers.dart';
import '../../data/models/perfil_state.dart';
import '../perfil/simbolo_pieza.dart';
import 'opcion_visual.dart';

class PerfilScreen extends ConsumerStatefulWidget {
  const PerfilScreen({super.key});

  @override
  ConsumerState<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends ConsumerState<PerfilScreen> {
  late final TextEditingController _nombre =
      TextEditingController(text: ref.read(perfilProvider).nombre);
  late int _pagina = _paginaInicial();

  /// El set que se muestra al abrir: el del ícono actual (o el de Apariencia).
  int _paginaInicial() {
    final perfil = ref.read(perfilProvider);
    final set = setDelPerfil(perfil.iconoSet) ?? ref.read(appearanceProvider).pieceSet;
    final i = PieceSet.values.indexOf(set);
    return i < 0 ? 0 : i;
  }

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  void _mover(int delta) {
    final n = PieceSet.values.length;
    setState(() => _pagina = (_pagina + delta + n) % n);
  }

  @override
  Widget build(BuildContext context) {
    final perfil = ref.watch(perfilProvider);
    final global = ref.watch(appearanceProvider.select((a) => a.pieceSet));
    final notif = ref.read(perfilProvider.notifier);
    final menu = ref.watch(menuProvider).valueOrNull ?? const [];
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    final set = PieceSet.values[_pagina];
    final setActual = setDelPerfil(perfil.iconoSet) ?? global;

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Nombre de usuario', style: tt.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _nombre,
            maxLength: PerfilState.maxNombre,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'Ajedrez',
              border: OutlineInputBorder(),
            ),
            onChanged: notif.setNombre,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text('Ícono', style: tt.titleMedium),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Set anterior',
                onPressed: () => _mover(-1),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 96),
                child: Text(set.label, textAlign: TextAlign.center, style: tt.bodyMedium),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Set siguiente',
                onPressed: () => _mover(1),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(spacing: 10, runSpacing: 10, children: [
            for (final c in kSimbolos)
              OpcionVisual(
                etiqueta: '${set.label} $c',
                seleccionada: perfil.simbolo == c && setActual == set,
                onTap: () => notif.setIcono(set.name, c),
                child: ColoredBox(
                  color: cs.surfaceContainerHighest,
                  child: Center(child: SimboloPieza(codigo: c, set: set, size: 44)),
                ),
              ),
          ]),
          const SizedBox(height: 24),
          Text('Progreso', style: tt.titleMedium),
          for (final seccion in menu)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(seccion.titulo),
              value: !perfil.ocultas.contains(seccion.id),
              onChanged: (v) => notif.setProgresoVisible(seccion.id, v),
            ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Promedio por ejercicio'),
            subtitle: const Text('Tiempo promedio en cada sección y nivel'),
            value: perfil.mostrarPromedio,
            onChanged: notif.setMostrarPromedio,
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          Text('Reiniciar progreso', style: tt.titleMedium),
          const SizedBox(height: 4),
          Text('Borra lo resuelto, los tiempos y los intentos de todas las secciones.',
              style: tt.bodySmall),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: cs.error,
              side: BorderSide(color: cs.error),
            ),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Reiniciar todo el progreso'),
            onPressed: () async {
              final ok = await confirmarAccion(
                context,
                titulo: 'Reiniciar todo el progreso',
                mensaje: 'Vas a borrar TODO tu progreso: ejercicios resueltos, tiempos, '
                    'intentos y estadísticas de todas las secciones. Esta acción no se '
                    'puede deshacer.',
                accion: 'Borrar todo',
              );
              if (!ok || !context.mounted) return;
              await reiniciarProgresoTodo(ref);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('Progreso reiniciado')));
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
