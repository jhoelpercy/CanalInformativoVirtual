// Autor: Jhoel Percy Gonzales Herrera
// Funcion: pantalla de detalle de una noticia (favorito, compartir, leer completa).
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/noticia.dart';
import '../state/app_state.dart';
import '../utils/fecha_util.dart';

/// Pantalla de Detalle: muestra el contenido completo disponible de
/// una noticia y permite marcarla o desmarcarla como favorita.
///
/// NOTA: el plan gratuito de NewsAPI.org entrega el campo "content"
/// cortado (termina en algo como "...[+2684 chars]"); eso no se puede
/// evitar desde el codigo de la app. Por eso aqui se muestra primero
/// el resumen completo (que si viene entero) y se ofrece un boton
/// para abrir la noticia original en el navegador y leerla completa.
class DetailScreen extends StatelessWidget {
  final AppState appState;
  final Noticia noticia;

  const DetailScreen({super.key, required this.appState, required this.noticia});

  Future<void> _abrirNoticiaCompleta(BuildContext context) async {
    if (noticia.urlOriginal.isEmpty) return;
    final uri = Uri.parse(noticia.urlOriginal);
    final seAbrio = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!seAbrio && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el enlace de la noticia.')),
      );
    }
  }

  /// Comparte el titulo y el enlace de la noticia con otras aplicaciones.
  Future<void> _compartir() async {
    final texto = noticia.urlOriginal.isEmpty
        ? noticia.titulo
        : '${noticia.titulo}\n${noticia.urlOriginal}';
    await SharePlus.instance.share(ShareParams(text: texto, subject: noticia.titulo));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final esFavorito = appState.esFavorito(noticia);
        final hayFragmentoExtra = noticia.contenido.isNotEmpty &&
            noticia.contenido.trim() != noticia.resumen.trim();

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 200,
                backgroundColor: const Color(0xFFE3ECF3),
                flexibleSpace: FlexibleSpaceBar(
                  background: noticia.imagenUrl != null && noticia.imagenUrl!.isNotEmpty
                      ? Image.network(
                          noticia.imagenUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Center(child: Icon(Icons.image_outlined, size: 60, color: Colors.grey)),
                        )
                      : const Center(child: Icon(Icons.image_outlined, size: 60, color: Colors.grey)),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: noticia.categoria.color,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(noticia.categoria.nombre,
                                style: const TextStyle(color: Colors.white, fontSize: 11)),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.share_outlined),
                                tooltip: 'Compartir',
                                onPressed: _compartir,
                              ),
                              IconButton(
                                icon: Icon(
                                  esFavorito ? Icons.favorite : Icons.favorite_border,
                                  color: Colors.redAccent,
                                ),
                                tooltip: esFavorito ? 'Quitar de favoritos' : 'Guardar en favoritos',
                                onPressed: () => appState.alternarFavorito(noticia),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(noticia.titulo,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('${noticia.fuente}  \u2022  ${fechaLegible(noticia.fecha)}',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5)),
                      const SizedBox(height: 20),

                      Text(
                        noticia.resumen.isNotEmpty
                            ? noticia.resumen
                            : 'Esta noticia no tiene un resumen disponible.',
                        style: const TextStyle(fontSize: 15, height: 1.5),
                      ),

                      if (hayFragmentoExtra) ...[
                        const SizedBox(height: 16),
                        Text(
                          noticia.contenido,
                          style: TextStyle(fontSize: 13.5, height: 1.5, color: Colors.grey.shade700),
                        ),
                      ],

                      const SizedBox(height: 10),
                      Text(
                        'El contenido completo solo esta disponible en el sitio original '
                        '(el plan gratuito de la API solo entrega un fragmento).',
                        style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: 20),

                      if (noticia.urlOriginal.isNotEmpty)
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () => _abrirNoticiaCompleta(context),
                            icon: const Icon(Icons.open_in_new, size: 18),
                            label: const Text('Leer noticia completa'),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
