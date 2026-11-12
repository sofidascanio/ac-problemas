import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/formato.dart';
import '../../core/providers.dart';
import '../../data/models/actividad.dart';
import '../../data/models/menu_node.dart';
import '../../data/repositories/progress_repository.dart';
import 'actividad_view.dart';
import 'exercise_strip.dart';
import 'problem_list_screen.dart';

/// En categorías SIN listado, hasta esta cantidad de ejercicios se muestra la
/// barrita numerada; con más, se pasa de uno a otro deslizando.
const int kMaxEjerciciosEnTira = 15;

/// Pantalla de problemas de una categoría. Abre en el último problema visitado
/// (o en el primero sin resolver), con un cronómetro por ejercicio y, en las
/// categorías con listado, un botón arriba a la derecha para abrirlo.
class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({
    super.key,
    required this.categoria,
    this.tituloPadre,
    this.indiceInicial,
  });
  final MenuNode categoria;
  final String? tituloPadre; // ej. "Mate en 2" (título del listado)

  /// Fuerza el ejercicio con el que abrir (si es null: último visitado / primero sin resolver).
  final int? indiceInicial;

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> with WidgetsBindingObserver {
  int? _indice;
  PageController? _pages;

  /// true mientras el dedo está sobre el tablero: ahí no se desliza de página,
  /// para que arrastrar una pieza no cambie de ejercicio.
  final _tocandoTablero = ValueNotifier<bool>(false);

  // ---- Cronómetro por ejercicio
  late final ProgressRepository _repo;
  late final StateController<int> _version;
  final _segundos = ValueNotifier<int>(0);
  Timer? _ticker;
  String? _idCrono; // ejercicio al que corresponde el cronómetro
  bool _resueltoCrono = false;
  bool _enLista = false; // el listado está abierto encima
  bool _enSegundoPlano = false;
  int _ticks = 0;

  @override
  void initState() {
    super.initState();
    _repo = ref.read(progressRepositoryProvider);
    _version = ref.read(tiemposVersionProvider.notifier);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _guardarTiempo();
    _pages?.dispose();
    _tocandoTablero.dispose();
    _segundos.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _enSegundoPlano = state != AppLifecycleState.resumed;
    if (_enSegundoPlano) _guardarTiempo(avisar: false);
  }

  /// Guarda los segundos del ejercicio actual. Solo se escribe al salir, al
  /// cambiar de ejercicio, al resolver, al pasar a segundo plano y cada 30 s.
  void _guardarTiempo({bool avisar = true}) {
    final id = _idCrono;
    if (id == null) return;
    _repo.guardarSegundos(widget.categoria.id, id, _segundos.value);
    if (avisar) Future.microtask(() => _version.state++); // refresca las estadísticas
  }

  void _abrirCronometro(Actividad a, bool resuelto) {
    if (_idCrono == a.id) return;
    _guardarTiempo(); // el del ejercicio anterior
    _idCrono = a.id;
    _resueltoCrono = resuelto;
    _segundos.value = _repo.segundos(widget.categoria.id, a.id);
    _repo.guardarUltimoVisitado(widget.categoria.id, a.id);
    _ticker?.cancel();
    if (resuelto) return; // un ejercicio resuelto conserva su tiempo y no corre
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_enLista || _enSegundoPlano) return;
      _segundos.value++;
      if (++_ticks % 30 == 0) _guardarTiempo(avisar: false);
    });
  }

  void _alResolver() {
    _resueltoCrono = true;
    _ticker?.cancel();
    _guardarTiempo();
  }

  // ---- Navegación

  /// Retoma donde se dejó: el último visitado; si ya está resuelto, el siguiente
  /// sin resolver. Si nunca se abrió, el primero sin resolver.
  int _indiceAlAbrir(List<Actividad> acts, Set<String> hechas) {
    final ultimo = _repo.ultimoVisitado(widget.categoria.id);
    final k = ultimo == null ? -1 : acts.indexWhere((a) => a.id == ultimo);
    if (k >= 0) {
      if (!hechas.contains(acts[k].id)) return k;
      final sig = acts.indexWhere((a) => !hechas.contains(a.id), k);
      return sig >= 0 ? sig : k;
    }
    final primera = acts.indexWhere((a) => !hechas.contains(a.id));
    return primera < 0 ? 0 : primera;
  }

  Future<void> _abrirLista() async {
    _enLista = true;
    final elegido = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (_) => ProblemListScreen(
          categoria: widget.categoria,
          tituloPadre: widget.tituloPadre,
          indiceActual: _indice,
        ),
      ),
    );
    _enLista = false;
    if (elegido == kIndiceReiniciado && mounted) {
      // La sección se reinició: se descarta el cronómetro en curso y se vuelve al primero.
      _ticker?.cancel();
      _idCrono = null;
      _resueltoCrono = false;
      _segundos.value = 0;
      _pages?.jumpToPage(0);
      setState(() => _indice = 0);
      return;
    }
    if (elegido != null && mounted) {
      _pages?.jumpToPage(elegido);
      setState(() => _indice = elegido);
    }
  }

  /// Título a mostrar sobre el tablero: número y nombre del problema. Si no tiene nombre,
  /// en categorías con listado se usa "Problema N"; si no, la consigna por defecto.
  String? _titulo(List<Actividad> acts, int i) {
    final a = acts[i];
    if (a.nombre != null && a.nombre!.trim().isNotEmpty) {
      return '${a.numero ?? i + 1}. ${a.nombre!.trim()}'; // ej. "14. mate1: Chapter 18 2025"
    }
    if (widget.categoria.lista && a is SecuenciaExacta) return 'Problema ${a.numero ?? i + 1}';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final cat = widget.categoria;
    final lista = ref.watch(actividadesProvider(cat.asset!));
    final hechas = ref.watch(completedProvider(cat.id));

    ref.listen<Set<String>>(completedProvider(cat.id), (prev, next) {
      final id = _idCrono;
      if (id != null && !_resueltoCrono && next.contains(id)) _alResolver();
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.tituloPadre == null ? cat.titulo : '${widget.tituloPadre} - ${cat.titulo}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        actions: [
          if (cat.lista)
            IconButton(
              icon: const Icon(Icons.format_list_numbered),
              tooltip: 'Lista de problemas',
              onPressed: _abrirLista,
            ),
        ],
      ),
      body: SafeArea(
        top: false, // el AppBar ya cubre la parte de arriba
        child: lista.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => const Center(child: Text('No se pudo cargar el contenido.')),
          data: (acts) {
            if (acts.isEmpty) return const Center(child: Text('Próximamente'));
            final i = _indice ??=
                (widget.indiceInicial ?? _indiceAlAbrir(acts, hechas)).clamp(0, acts.length - 1);
            final usaPaginas = cat.lista || acts.length > kMaxEjerciciosEnTira;
            final marcas = usaPaginas
                ? const <bool>[]
                : [for (final a in acts) hechas.contains(a.id)];
            final resueltos = usaPaginas
                ? acts.where((a) => hechas.contains(a.id)).length
                : marcas.where((m) => m).length;

            if (_idCrono != acts[i].id) {
              final a = acts[i];
              final resuelto = hechas.contains(a.id);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _abrirCronometro(a, resuelto);
              });
            }

            final tt = Theme.of(context).textTheme;
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LinearProgressIndicator(value: resueltos / acts.length),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(child: Text('$resueltos de ${acts.length} resueltos')),
                      Icon(Icons.timer_outlined, size: 15, color: tt.bodySmall?.color),
                      const SizedBox(width: 3),
                      ValueListenableBuilder<int>(
                        valueListenable: _segundos,
                        builder: (_, s, __) => Text(formatoTiempo(s), style: tt.bodySmall),
                      ),
                      if (usaPaginas) ...[
                        const SizedBox(width: 14),
                        Text('${i + 1} / ${acts.length}', style: tt.bodySmall),
                      ],
                    ],
                  ),
                  if (!usaPaginas) ...[
                    const SizedBox(height: 8),
                    ExerciseStrip(
                      completadas: marcas,
                      actual: i,
                      onTap: (n) => setState(() => _indice = n),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Expanded(
                    child: usaPaginas
                        ? _paginas(acts, hechas, cat.id)
                        : ActividadView(
                            key: ValueKey(acts[i].id),
                            actividad: acts[i],
                            categoriaId: cat.id,
                            titulo: _titulo(acts, i),
                            yaResuelto: hechas.contains(acts[i].id),
                            registrarIntentos: true,
                            onAnterior: i > 0 ? () => setState(() => _indice = i - 1) : null,
                            onProximo: i + 1 < acts.length
                                ? () => setState(() => _indice = i + 1)
                                : null,
                            onSiguiente: i + 1 < acts.length
                                ? () => setState(() => _indice = i + 1)
                                : null,
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _paginas(List<Actividad> acts, Set<String> hechas, String categoriaId) {
    final controller = _pages ??= PageController(initialPage: _indice ?? 0);
    return ValueListenableBuilder<bool>(
      valueListenable: _tocandoTablero,
      builder: (context, bloqueado, _) => PageView.builder(
        controller: controller,
        physics: bloqueado
            ? const NeverScrollableScrollPhysics()
            : const PageScrollPhysics(),
        itemCount: acts.length,
        onPageChanged: (p) => setState(() => _indice = p),
        itemBuilder: (context, p) => ActividadView(
          key: ValueKey(acts[p].id),
          actividad: acts[p],
          categoriaId: categoriaId,
          titulo: _titulo(acts, p),
          yaResuelto: hechas.contains(acts[p].id),
          registrarIntentos: true,
          onAnterior: p > 0
              ? () => controller.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  )
              : null,
          onProximo: p + 1 < acts.length
              ? () => controller.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  )
              : null,
          onTocarTablero: (v) => _tocandoTablero.value = v,
          onSiguiente: p + 1 < acts.length
              ? () => controller.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  )
              : null,
        ),
      ),
    );
  }
}
