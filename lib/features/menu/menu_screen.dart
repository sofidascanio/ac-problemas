import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../data/models/menu_node.dart';
import '../activity/activity_screen.dart';
import '../leccion/leccion_screen.dart';
import '../settings/settings_screen.dart';
import '../perfil/simbolo_pieza.dart';
import 'encabezado_app.dart';
import 'menu_icons.dart';
import 'tarjeta_progreso.dart';

/// Pantalla de menú genérica: sin [nodo] muestra la raíz; con [nodo], sus hijos.
class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key, this.nodo});
  final MenuNode? nodo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final esRaiz = nodo == null;
    final perfil = ref.watch(perfilProvider);
    return Scaffold(
      appBar: AppBar(
        title: esRaiz
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SimboloPieza(codigo: perfil.simbolo, set: setDelPerfil(perfil.iconoSet), size: 30),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(perfil.nombreVisible, overflow: TextOverflow.ellipsis),
                  ),
                ],
              )
            : Text(nodo!.titulo),
        actions: [
          if (esRaiz)
            IconButton(
              icon: const Icon(Icons.tune),
              tooltip: 'Ajustes',
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen())),
            ),
        ],
      ),
      body: esRaiz
          ? Column(
              children: [
                Expanded(
                  child: ref.watch(menuProvider).when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => const Center(child: Text('No se pudo cargar el menú.')),
                        data: (nodos) => _Lista(
                          nodos: nodos,
                          encabezado: const Column(
                            children: [EncabezadoApp(), TarjetaProgreso()],
                          ),
                        ),
                      ),
                ),
                const BotonAcercaDe(), // abajo a la izquierda
              ],
            )
          : _Lista(nodos: nodo!.hijos, tituloPadre: nodo!.titulo),
    );
  }
}

class _Lista extends StatelessWidget {
  const _Lista({required this.nodos, this.tituloPadre, this.encabezado});
  final List<MenuNode> nodos;
  final String? tituloPadre;
  final Widget? encabezado; // ej. la tarjeta de progreso de la pantalla principal

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (encabezado != null) encabezado!,
          for (final n in nodos) _NodoTile(nodo: n, tituloPadre: tituloPadre, hermanos: nodos),
        ],
      );
}

class _NodoTile extends ConsumerWidget {
  const _NodoTile({required this.nodo, this.tituloPadre, this.hermanos = const []});
  final MenuNode nodo;
  final String? tituloPadre;
  final List<MenuNode> hermanos; // para pasar a la siguiente lección

  void _abrir(BuildContext context) {
    final Widget destino;
    if (!nodo.esHoja) {
      destino = MenuScreen(nodo: nodo);
    } else if (nodo.asset != null && nodo.leccion) {
      destino = LeccionScreen(categoria: nodo, hermanos: hermanos);
    } else if (nodo.asset != null) {
      // Va directo a los problemas; el listado se abre desde el botón de arriba a la derecha.
      destino = ActivityScreen(categoria: nodo, tituloPadre: tituloPadre);
    } else {
      // TODO: pantalla propia "Disposición del tablero" (fuera del modelo Actividad).
      destino = Scaffold(
        appBar: AppBar(title: Text(nodo.titulo)),
        body: const Center(child: Text('Próximamente')),
      );
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => destino));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _abrir(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              iconoWidget(nodo.icono),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nodo.titulo, style: tt.titleMedium),
                    if (nodo.esHoja && nodo.asset == null) ...[
                      const SizedBox(height: 4),
                      Text('Próximamente', style: tt.bodySmall),
                    ],
                    if (nodo.esHoja && nodo.asset != null) ...[
                      const SizedBox(height: 10),
                      nodo.leccion ? _ProgresoLeccion(nodo: nodo) : _Progreso(nodo: nodo),
                    ],
                  ],
                ),
              ),
              if (!nodo.esHoja) const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _Progreso extends ConsumerWidget {
  const _Progreso({required this.nodo});
  final MenuNode nodo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final acts = ref.watch(actividadesProvider(nodo.asset!)).valueOrNull;
    final hechas = ref.watch(completedProvider(nodo.id));
    if (acts == null) return const LinearProgressIndicator();
    if (acts.isEmpty) {
      return Text('Próximamente', style: Theme.of(context).textTheme.bodySmall);
    }
    final ids = acts.map((a) => a.id).toSet();
    final hechasValidas = hechas.intersection(ids).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(value: hechasValidas / acts.length),
        const SizedBox(height: 6),
        Text('$hechasValidas de ${acts.length} resueltos',
            style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _ProgresoLeccion extends ConsumerWidget {
  const _ProgresoLeccion({required this.nodo});
  final MenuNode nodo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lec = ref.watch(leccionProvider(nodo.asset!));
    final hechas = ref.watch(completedProvider(nodo.id));
    return lec.when(
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => const SizedBox.shrink(),
      data: (l) {
        final ids = l?.idsProgreso ?? const <String>{};
        if (l == null || ids.isEmpty) {
          return Text(l == null ? 'Próximamente' : 'Lección',
              style: Theme.of(context).textTheme.bodySmall);
        }
        final n = hechas.intersection(ids).length;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(value: n / ids.length),
            const SizedBox(height: 6),
            Text('$n de ${ids.length} actividades',
                style: Theme.of(context).textTheme.bodySmall),
          ],
        );
      },
    );
  }
}
