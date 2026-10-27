// Autor: Jhoel Percy Gonzales Herrera
// Funcion: contenedor con la barra de navegacion inferior.
import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'favorites_screen.dart';
import 'settings_screen.dart';
import '../state/app_state.dart';

/// Contenedor principal que agrupa las 3 pantallas accesibles desde la
/// barra de navegacion inferior, tal como se definio en el diagrama de
/// navegacion de la Semana 3. Ahora recibe el AppState compartido en
/// lugar de manejar favoritos por su cuenta.
class MainScaffold extends StatefulWidget {
  final AppState appState;
  const MainScaffold({super.key, required this.appState});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _indiceActual = 0;

  @override
  void initState() {
    super.initState();
    // Si el usuario sigue usando el PIN por defecto (1234), se le
    // recomienda cambiarlo una vez por sesion.
    if (widget.appState.usaPinPorDefecto && !widget.appState.avisoPinMostrado) {
      widget.appState.avisoPinMostrado = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _avisarPinPorDefecto());
    }
  }

  void _avisarPinPorDefecto() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.lock_outline, size: 40, color: Color(0xFF1F6FB2)),
        title: const Text('Cambia tu codigo de acceso'),
        content: const Text(
          'Estas usando el codigo por defecto (1234). Por seguridad, te recomendamos '
          'cambiarlo desde Configuracion.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Mas tarde'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() => _indiceActual = 2);
            },
            child: const Text('Ir a Configuracion'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pantallas = [
      HomeScreen(appState: widget.appState),
      FavoritesScreen(appState: widget.appState),
      SettingsScreen(appState: widget.appState),
    ];

    return Scaffold(
      body: IndexedStack(index: _indiceActual, children: pantallas),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indiceActual,
        onTap: (i) => setState(() => _indiceActual = i),
        selectedItemColor: const Color(0xFF1F6FB2),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.star_outline), label: 'Favoritos'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Config.'),
        ],
      ),
    );
  }
}
