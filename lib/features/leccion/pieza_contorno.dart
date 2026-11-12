import 'package:flutter/material.dart';

/// Imagen de una pieza. Las piezas negras en modo oscuro se dibujan con un contorno
/// blanco (relleno negro) para que no se pierdan contra el fondo.
class PiezaContorno extends StatelessWidget {
  const PiezaContorno({super.key, required this.imagen, required this.size, required this.negra});
  final ImageProvider imagen;
  final double size;
  final bool negra;

  @override
  Widget build(BuildContext context) {
    final img = Image(image: imagen, width: size, height: size);
    if (!negra || Theme.of(context).brightness != Brightness.dark) return img;

    final g = (size * 0.05).clamp(1.0, 2.5);
    const dirs = [
      Offset(1, 0), Offset(-1, 0), Offset(0, 1), Offset(0, -1),
      Offset(0.7, 0.7), Offset(-0.7, 0.7), Offset(0.7, -0.7), Offset(-0.7, -0.7),
    ];
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (final d in dirs)
            Transform.translate(
              offset: d * g,
              child: ColorFiltered(
                colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                child: Image(image: imagen, width: size, height: size),
              ),
            ),
          img,
        ],
      ),
    );
  }
}
