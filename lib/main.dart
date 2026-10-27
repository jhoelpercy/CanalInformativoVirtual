// Autor: Jhoel Percy Gonzales Herrera
// Funcion: punto de entrada de la app; define los temas claro/oscuro y crea el AppState.
import 'package:flutter/material.dart';
import 'screens/lock_screen.dart';
import 'state/app_state.dart';

void main() {
  runApp(const CanalInformativoVirtualApp());
}

/// Widget raiz de la aplicacion. Define los temas visuales (claro y
/// oscuro) y crea el AppState una sola vez para que viva durante toda
/// la sesion de la app.
class CanalInformativoVirtualApp extends StatefulWidget {
  const CanalInformativoVirtualApp({super.key});

  @override
  State<CanalInformativoVirtualApp> createState() => _CanalInformativoVirtualAppState();
}

class _CanalInformativoVirtualAppState extends State<CanalInformativoVirtualApp> {
  static const Color _colorBase = Color(0xFF1F6FB2);

  final AppState _appState = AppState();

  @override
  void initState() {
    super.initState();
    // Carga el tema y la region guardados antes de que el usuario entre.
    _appState.cargarPreferencias();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _appState,
      builder: (context, _) {
        return MaterialApp(
          title: 'Canal Informativo Virtual',
          debugShowCheckedModeBanner: false,
          themeMode: _appState.modoTema,
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: _colorBase,
            appBarTheme: const AppBarTheme(centerTitle: false),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: _colorBase,
            brightness: Brightness.dark,
            appBarTheme: const AppBarTheme(centerTitle: false),
          ),
          home: LockScreen(appState: _appState),
        );
      },
    );
  }
}
