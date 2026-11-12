import 'package:flutter/material.dart';

const _iconos = <String, IconData>{
  'school': Icons.school_outlined,
  'menu_book': Icons.menu_book_outlined,
  'fitness_center': Icons.fitness_center_outlined,
  'extension': Icons.extension_outlined,
  'looks_one': Icons.looks_one_outlined,
  'looks_two': Icons.looks_two_outlined,
  'looks_3': Icons.looks_3_outlined,
  'flag': Icons.flag_outlined,
  'shield': Icons.shield_outlined,
  'bolt': Icons.bolt_outlined,
  'grid': Icons.grid_view_outlined,
  'crown': Icons.emoji_events_outlined,
  'pause': Icons.pause_circle_outline,
  'swap': Icons.swap_horiz,
  'repeat': Icons.repeat,
  'rocket': Icons.rocket_launch_outlined,
  'auto_awesome': Icons.auto_awesome_outlined,
  'call_split': Icons.call_split,
  'emoji_events': Icons.emoji_events_outlined,
  'palette': Icons.palette_outlined,
  'push_pin': Icons.push_pin_outlined,
  'visibility': Icons.visibility_outlined,
};

IconData iconoDe(String nombre) => _iconos[nombre] ?? Icons.circle_outlined;

/// Ícono de un nodo: nombre de la tabla de arriba o, si es un símbolo suelto
/// (ej. "♞"), se dibuja como texto.
Widget iconoWidget(String nombre, {double size = 28, Color? color}) {
  final icono = _iconos[nombre];
  if (icono != null) return Icon(icono, size: size, color: color);
  if (nombre.runes.length <= 2) {
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Text(nombre, style: TextStyle(fontSize: size * 0.9, height: 1, color: color)),
      ),
    );
  }
  return Icon(Icons.circle_outlined, size: size, color: color);
}
