// Autor: Jhoel Percy Gonzales Herrera
// Funcion: tarjeta de noticia reutilizable.
import 'package:flutter/material.dart';
import '../models/noticia.dart';
import '../utils/fecha_util.dart';

/// Tarjeta usada en el listado de Inicio y en Favoritos para mostrar
/// una vista resumida de cada noticia, ahora con su imagen real
/// (cuando la API la provee) y un indicador de si ya es favorita.
class NewsCard extends StatelessWidget {
  final Noticia noticia;
  final VoidCallback onTap;
  final VoidCallback? onRemove;
  final bool esFavorito;

  const NewsCard({
    super.key,
    required this.noticia,
    required this.onTap,
    this.onRemove,
    this.esFavorito = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 76,
                  height: 76,
                  child: _imagenNoticia(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: noticia.categoria.color,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            noticia.categoria.nombre,
                            style: const TextStyle(color: Colors.white, fontSize: 10.5),
                          ),
                        ),
                        if (esFavorito) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.favorite, size: 14, color: Colors.redAccent),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      noticia.titulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _fuenteYFecha(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.grey, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
              if (onRemove != null)
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.redAccent, size: 20),
                  onPressed: onRemove,
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Texto secundario de la tarjeta: fuente y antiguedad de la noticia.
  String _fuenteYFecha() {
    final fecha = fechaLegible(noticia.fecha);
    return fecha.isEmpty ? noticia.fuente : '${noticia.fuente}  •  $fecha';
  }

  Widget _imagenNoticia() {
    final url = noticia.imagenUrl;
    if (url == null || url.isEmpty) {
      return Container(
        color: const Color(0xFFEDEDED),
        child: const Icon(Icons.image_outlined, color: Colors.grey, size: 30),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        color: const Color(0xFFEDEDED),
        child: const Icon(Icons.image_outlined, color: Colors.grey, size: 30),
      ),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: const Color(0xFFEDEDED),
          child: const Center(
            child: SizedBox(
              width: 18, height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
    );
  }
}
