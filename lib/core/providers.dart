import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/actividad.dart';
import '../data/models/appearance_state.dart';
import '../data/models/leccion.dart';
import '../data/models/menu_node.dart';
import '../data/models/perfil_state.dart';
import '../data/repositories/appearance_repository.dart';
import '../data/repositories/content_repository.dart';
import '../data/repositories/perfil_repository.dart';
import '../data/repositories/progress_repository.dart';
import 'sound_service.dart';

/// Se sobrescribe en main() con la instancia ya inicializada.
final sharedPreferencesProvider =
    Provider<SharedPreferences>((_) => throw UnimplementedError());

final contentRepositoryProvider =
    Provider<ContentRepository>((_) => AssetContentRepository());

final progressRepositoryProvider = Provider<ProgressRepository>(
    (ref) => SharedPrefsProgressRepository(ref.watch(sharedPreferencesProvider)));

final appearanceRepositoryProvider = Provider<AppearanceRepository>(
    (ref) => SharedPrefsAppearanceRepository(ref.watch(sharedPreferencesProvider)));

final menuProvider = FutureProvider<List<MenuNode>>(
    (ref) => ref.watch(contentRepositoryProvider).cargarMenu());

final actividadesProvider = FutureProvider.family<List<Actividad>, String>(
    (ref, asset) => ref.watch(contentRepositoryProvider).cargarActividades(asset));

final leccionProvider = FutureProvider.family<Leccion?, String>(
    (ref, asset) => ref.watch(contentRepositoryProvider).cargarLeccion(asset));

/// IDs completados por categoría.
class CompletedNotifier extends FamilyNotifier<Set<String>, String> {
  @override
  Set<String> build(String arg) =>
      ref.watch(progressRepositoryProvider).completadas(arg);

  Future<void> marcar(String actividadId) async {
    final repo = ref.read(progressRepositoryProvider);
    final esNuevo = !state.contains(actividadId); // repetir un ejercicio no suma al día
    await repo.marcarCompletada(arg, actividadId);
    if (esNuevo) await repo.sumarResueltoHoy(arg);
    state = {...state, actividadId};
  }
}

final completedProvider =
    NotifierProvider.family<CompletedNotifier, Set<String>, String>(
        CompletedNotifier.new);

class AppearanceNotifier extends Notifier<AppearanceState> {
  @override
  AppearanceState build() => ref.watch(appearanceRepositoryProvider).cargar();

  void actualizar(AppearanceState nuevo) {
    state = nuevo;
    ref.read(appearanceRepositoryProvider).guardar(nuevo);
  }
}

final appearanceProvider =
    NotifierProvider<AppearanceNotifier, AppearanceState>(AppearanceNotifier.new);

final soundProvider = Provider<SoundService>((ref) {
  final servicio = SoundService(() => ref.read(appearanceProvider).sonido);
  ref.onDispose(servicio.dispose);
  return servicio;
});

// ------------------------------------------------- Perfil

final perfilRepositoryProvider = Provider<PerfilRepository>(
    (ref) => SharedPrefsPerfilRepository(ref.watch(sharedPreferencesProvider)));

class PerfilNotifier extends Notifier<PerfilState> {
  @override
  PerfilState build() => ref.watch(perfilRepositoryProvider).cargar();

  void _guardar(PerfilState nuevo) {
    state = nuevo;
    ref.read(perfilRepositoryProvider).guardar(nuevo);
  }

  void setNombre(String nombre) {
    final recortado = nombre.length > PerfilState.maxNombre
        ? nombre.substring(0, PerfilState.maxNombre)
        : nombre;
    _guardar(state.copyWith(nombre: recortado));
  }

  void setMostrarPromedio(bool v) => _guardar(state.copyWith(mostrarPromedio: v));

  void setIcono(String setNombre, String codigo) =>
      _guardar(state.copyWith(iconoSet: setNombre, simbolo: codigo));

  void setProgresoVisible(String seccionId, bool visible) {
    final o = {...state.ocultas};
    visible ? o.remove(seccionId) : o.add(seccionId);
    _guardar(state.copyWith(ocultas: o));
  }
}

final perfilProvider = NotifierProvider<PerfilNotifier, PerfilState>(PerfilNotifier.new);

// ------------------------------------------------- Estadísticas

/// Se incrementa cada vez que se guarda un tiempo, para refrescar las estadísticas.
final tiemposVersionProvider = StateProvider<int>((_) => 0);

class EstadisticaSeccion {
  const EstadisticaSeccion({
    required this.total,
    required this.resueltos,
    this.segundosPromedio,
  });
  final int total;
  final int resueltos;
  final int? segundosPromedio; // promedio de los ejercicios resueltos con tiempo registrado
}

Iterable<MenuNode> _hojasConContenido(MenuNode n) sync* {
  if (n.hijos.isEmpty) {
    if (n.asset != null) yield n;
  } else {
    for (final h in n.hijos) {
      yield* _hojasConContenido(h);
    }
  }
}

MenuNode? _buscarNodo(List<MenuNode> nodos, String id) {
  for (final n in nodos) {
    if (n.id == id) return n;
    final h = _buscarNodo(n.hijos, id);
    if (h != null) return h;
  }
  return null;
}

/// Progreso de un nodo del menú (sección o subsección): suma todas sus hojas.
final estadisticaNodoProvider =
    FutureProvider.family<EstadisticaSeccion, String>((ref, nodoId) async {
  final menu = await ref.watch(menuProvider.future);
  final nodo = _buscarNodo(menu, nodoId);
  if (nodo == null) return const EstadisticaSeccion(total: 0, resueltos: 0);

  // Todas las dependencias se leen ANTES de los await de carga.
  final hojas = _hojasConContenido(nodo).toList();
  final hechasPorHoja = {for (final h in hojas) h.id: ref.watch(completedProvider(h.id))};
  ref.watch(tiemposVersionProvider);
  final contenido = ref.watch(contentRepositoryProvider);
  final progreso = ref.watch(progressRepositoryProvider);

  var total = 0, resueltos = 0;
  final tiempos = <int>[];
  for (final h in hojas) {
    final Set<String> ids;
    if (h.leccion) {
      ids = (await contenido.cargarLeccion(h.asset!))?.idsProgreso ?? <String>{};
    } else {
      ids = (await contenido.cargarActividades(h.asset!)).map((a) => a.id).toSet();
    }
    total += ids.length;
    final hechas = hechasPorHoja[h.id]!.intersection(ids);
    resueltos += hechas.length;
    final seg = progreso.todosSegundos(h.id);
    for (final id in hechas) {
      final s = seg[id];
      if (s != null && s > 0) tiempos.add(s);
    }
  }
  return EstadisticaSeccion(
    total: total,
    resueltos: resueltos,
    segundosPromedio:
        tiempos.isEmpty ? null : (tiempos.reduce((a, b) => a + b) / tiempos.length).round(),
  );
});

class ResumenGeneral {
  const ResumenGeneral({required this.resueltos, required this.hoy, required this.semana});
  final int resueltos; // ejercicios resueltos (todo menos las lecciones)
  final int hoy;
  final int semana; // desde el lunes de esta semana
}

/// Resueltos / Hoy / Esta semana de todos los ejercicios (Práctica, Ejercicios,
/// Pájaro Carpintero y lo que se agregue): las hojas que no son lecciones.
final resumenGeneralProvider = FutureProvider<ResumenGeneral>((ref) async {
  final menu = await ref.watch(menuProvider.future);
  final hojas = [
    for (final n in menu) ..._hojasConContenido(n),
  ].where((h) => !h.leccion).toList();
  final hechasPorHoja = {for (final h in hojas) h.id: ref.watch(completedProvider(h.id))};
  final contenido = ref.watch(contentRepositoryProvider);
  final progreso = ref.watch(progressRepositoryProvider);

  final ahora = DateTime.now();
  final hoyClave = SharedPrefsProgressRepository.claveDia(ahora);
  final lunes = DateTime(ahora.year, ahora.month, ahora.day)
      .subtract(Duration(days: ahora.weekday - 1));
  final clavesSemana = {
    for (var d = lunes; !d.isAfter(ahora); d = d.add(const Duration(days: 1)))
      SharedPrefsProgressRepository.claveDia(d),
  };

  var resueltos = 0, hoy = 0, semana = 0;
  for (final h in hojas) {
    final ids = (await contenido.cargarActividades(h.asset!)).map((a) => a.id).toSet();
    resueltos += hechasPorHoja[h.id]!.intersection(ids).length;
    final dias = progreso.resueltosPorDia(h.id);
    hoy += dias[hoyClave] ?? 0;
    for (final c in clavesSemana) {
      semana += dias[c] ?? 0;
    }
  }
  return ResumenGeneral(resueltos: resueltos, hoy: hoy, semana: semana);
});

// ------------------------------------------------- Reinicio de progreso

/// Borra todo el progreso (de todas las secciones). No toca perfil ni apariencia.
Future<void> reiniciarProgresoTodo(WidgetRef ref) async {
  await ref.read(progressRepositoryProvider).reiniciarTodo();
  ref.invalidate(completedProvider); // todas las categorías
  ref.invalidate(resumenGeneralProvider);
  ref.invalidate(estadisticaNodoProvider);
  ref.read(tiemposVersionProvider.notifier).state++;
}

/// Borra el progreso de UNA categoría (una hoja del menú).
Future<void> reiniciarProgresoCategoria(WidgetRef ref, String categoriaId) async {
  await ref.read(progressRepositoryProvider).reiniciar(categoriaId);
  ref.invalidate(completedProvider(categoriaId));
  ref.invalidate(resumenGeneralProvider);
  ref.invalidate(estadisticaNodoProvider);
  ref.read(tiemposVersionProvider.notifier).state++;
}
