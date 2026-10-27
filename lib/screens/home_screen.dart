// Autor: Jhoel Percy Gonzales Herrera
// Funcion: pantalla de Inicio: busqueda, categorias y listado de noticias.
import 'package:flutter/material.dart';
import '../models/noticia.dart';
import '../state/app_state.dart';
import '../widgets/news_card.dart';
import '../widgets/category_chip.dart';
import 'categories_screen.dart';
import 'detail_screen.dart';

/// Pantalla de Inicio: muestra la seccion "Basado en tus intereses",
/// el filtro rapido por categoria y el listado general de noticias.
/// Las noticias vienen de NewsAPI.org a traves del AppState, con
/// manejo de carga, error, modo sin conexion y scroll infinito
/// (se piden mas noticias automaticamente al llegar casi al final).
class HomeScreen extends StatefulWidget {
  final AppState appState;
  const HomeScreen({super.key, required this.appState});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _controladorScroll = ScrollController();
  final TextEditingController _controladorBusqueda = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controladorScroll.addListener(_alDesplazar);
  }

  @override
  void dispose() {
    _controladorScroll.removeListener(_alDesplazar);
    _controladorScroll.dispose();
    _controladorBusqueda.dispose();
    super.dispose();
  }

  void _alDesplazar() {
    if (!_controladorScroll.hasClients) return;
    final posicion = _controladorScroll.position;
    // Cuando falten menos de 300 pixeles para llegar al final de la
    // lista, se pide la siguiente pagina de noticias a la API.
    if (posicion.pixels >= posicion.maxScrollExtent - 300) {
      widget.appState.cargarMas();
    }
  }

  void _abrirDetalle(BuildContext context, Noticia noticia) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DetailScreen(appState: widget.appState, noticia: noticia),
      ),
    );
  }

  /// Valida el texto escrito y lanza la busqueda (minimo 2 caracteres).
  void _enviarBusqueda(String texto) {
    final termino = texto.trim();
    if (termino.isEmpty) {
      _limpiarBusqueda();
      return;
    }
    if (termino.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe al menos 2 letras para buscar.')),
      );
      return;
    }
    widget.appState.buscar(termino);
  }

  void _limpiarBusqueda() {
    _controladorBusqueda.clear();
    if (widget.appState.buscando) widget.appState.limpiarBusqueda();
  }

  void _seleccionarCategoria(Categoria categoria) {
    _controladorBusqueda.clear();
    widget.appState.seleccionarCategoria(categoria);
  }

  @override
  Widget build(BuildContext context) {
    final appState = widget.appState;
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        // Si hubo un fallo al cargar mas noticias, se avisa con un SnackBar.
        final aviso = appState.consumirAviso();
        if (aviso != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(aviso)));
          });
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Canal Informativo'),
            actions: [
              IconButton(
                icon: appState.cargando
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                tooltip: 'Actualizar noticias',
                onPressed: appState.cargando ? null : () => appState.actualizar(),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () => appState.actualizar(),
            child: ListView(
              controller: _controladorScroll,
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _controladorBusqueda,
                  textInputAction: TextInputAction.search,
                  onSubmitted: _enviarBusqueda,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Buscar noticias...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _controladorBusqueda.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            tooltip: 'Borrar busqueda',
                            onPressed: _limpiarBusqueda,
                          ),
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                ),
                const SizedBox(height: 14),
                if (!appState.buscando &&
                    appState.categoriaActiva.id == 'todas' &&
                    appState.categoriaSugerida != null &&
                    appState.noticias.isNotEmpty)
                  _bloqueSugerido(context, appState.categoriaSugerida!),

                if (appState.mostrandoCache)
                  _bannerAviso(
                    icono: Icons.cloud_off,
                    color: Colors.orange,
                    mensaje: appState.error ??
                        'Sin conexion: mostrando noticias guardadas anteriormente.',
                  ),

                if (!appState.mostrandoCache && appState.error != null)
                  _bannerAviso(
                    icono: Icons.error_outline,
                    color: Colors.red,
                    mensaje: appState.error!,
                  ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        appState.buscando
                            ? 'Resultados para “${appState.terminoBusqueda}”'
                            : 'Noticias • ${appState.region.nombre}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CategoriesScreen(
                              onCategoriaSeleccionada: _seleccionarCategoria,
                            ),
                          ),
                        );
                      },
                      child: const Text('Ver todas'),
                    ),
                  ],
                ),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      CategoryChip(
                        categoria: Categoria.todas,
                        activo: appState.categoriaActiva.id == 'todas',
                        onTap: () => _seleccionarCategoria(Categoria.todas),
                      ),
                      ...Categoria.lista.map((c) => CategoryChip(
                            categoria: c,
                            activo: appState.categoriaActiva.id == c.id,
                            onTap: () => _seleccionarCategoria(c),
                          )),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                if (appState.cargando && appState.noticias.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (appState.noticias.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Center(
                      child: Text(
                        appState.buscando
                            ? 'No se encontraron noticias para esa busqueda.'
                            : 'No hay noticias para mostrar en esta categoria.',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                  )
                else ...[
                  ...appState.noticias.map(
                    (n) => NewsCard(
                      noticia: n,
                      esFavorito: appState.esFavorito(n),
                      onTap: () => _abrirDetalle(context, n),
                    ),
                  ),
                  _piePaginacion(appState),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _piePaginacion(AppState appState) {
    if (appState.cargandoMas) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: SizedBox(
            width: 22, height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
        ),
      );
    }
    if (!appState.hayMasNoticias && !appState.mostrandoCache) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            'Ya viste todas las noticias disponibles de esta categoria',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 11.5),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _bloqueSugerido(BuildContext context, Categoria sugerida) {
    final appState = widget.appState;
    final destacadas = appState.noticias.where((n) => n.categoria.id == sugerida.id).toList();
    if (destacadas.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF3E4),
        border: Border.all(color: const Color(0xFFE8A33D)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '\u2605 Basado en tus intereses: ${sugerida.nombre}',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8A5A10)),
          ),
          const SizedBox(height: 8),
          NewsCard(
            noticia: destacadas.first,
            esFavorito: appState.esFavorito(destacadas.first),
            onTap: () => _abrirDetalle(context, destacadas.first),
          ),
        ],
      ),
    );
  }

  Widget _bannerAviso({required IconData icono, required Color color, required String mensaje}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icono, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(mensaje, style: TextStyle(color: color.withValues(alpha: 0.9), fontSize: 12.5)),
          ),
        ],
      ),
    );
  }
}
