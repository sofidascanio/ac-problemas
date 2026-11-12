import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/providers.dart';
import 'features/menu/encabezado_app.dart';
import 'features/menu/menu_screen.dart';
import 'theme/app_theme.dart';

class AjedrezApp extends ConsumerWidget {
  const AjedrezApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modo = ref.watch(appearanceProvider.select((a) => a.themeMode));
    return MaterialApp(
      title: kNombreApp,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: modo,
      home: const MenuScreen(),
    );
  }
}
