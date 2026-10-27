// Autor: Jhoel Percy Gonzales Herrera
// Funcion: pantalla de favoritos con eliminacion por gesto.
import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../widgets/news_card.dart';
import 'detail_screen.dart';

/// Pantalla de Favoritos: muestra las noticias que el usuario marco.
/// Ya funciona con persistencia real: si cierras la app y la vuelves
/// a abrir, los favoritos siguen ahi (StorageService).
class FavoritesScreen extends StatelessWidget {
  final AppState appState;
  const FavoritesScreen({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final favoritos = appState.favoritos;
        return Scaffold(
          appBar: AppBar(title: const Text('Mis favoritos')),
          body: favoritos.isEmpty
              ? Center(
                  child: Text(
                    'Todavia no guardaste ninguna noticia',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text('${favoritos.length} noticias guardadas',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5)),
                    const SizedBox(height: 10),
                    ...favoritos.map(
                      (n) => Dismissible(
                        key: ValueKey(n.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.delete_outline, color: Colors.white),
                        ),
                        onDismissed: (_) {
                          appState.alternarFavorito(n);
                          ScaffoldMessenger.of(context)
                            ..clearSnackBars()
                            ..showSnackBar(
                              SnackBar(
                                content: const Text('Noticia quitada de favoritos'),
                                action: SnackBarAction(
                                  label: 'Deshacer',
                                  onPressed: () => appState.alternarFavorito(n),
                                ),
                              ),
                            );
                        },
                        child: NewsCard(
                          noticia: n,
                          esFavorito: true,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => DetailScreen(appState: appState, noticia: n),
                            ),
                          ),
                          onRemove: () => appState.alternarFavorito(n),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: Text('Desliza una noticia hacia la izquierda para quitarla. Disponibles sin conexion.',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 11.5)),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
