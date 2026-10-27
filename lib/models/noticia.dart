// Autor: Jhoel Percy Gonzales Herrera
// Funcion: modelos Noticia y Categoria con conversion desde la API y JSON local.
import 'package:flutter/material.dart';

/// Representa una noticia dentro de la aplicacion.
/// Incluye conversion desde la respuesta de NewsAPI.org (fromApi) y
/// conversion hacia/desde JSON simple para guardarla en el dispositivo
/// (toJson / fromJson), usada tanto para favoritos como para la cache.
class Noticia {
  final String id;
  final String titulo;
  final String resumen;
  final String contenido;
  final String fuente;
  final String fecha;
  final String? imagenUrl;
  final String urlOriginal;
  final Categoria categoria;

  const Noticia({
    required this.id,
    required this.titulo,
    required this.resumen,
    required this.contenido,
    required this.fuente,
    required this.fecha,
    required this.categoria,
    required this.urlOriginal,
    this.imagenUrl,
  });

  /// Construye una Noticia a partir de un articulo devuelto por NewsAPI.org.
  ///
  /// NOTA sobre el campo "contenido": el plan gratuito de NewsAPI.org
  /// siempre entrega el contenido cortado (termina en algo como
  /// "...[+2684 chars]"), sin importar lo que haga la aplicacion; es
  /// una restriccion del plan, no un error del codigo. Por eso el
  /// "resumen" (description) se usa como texto principal, ya que ese
  /// campo si viene completo, y se ofrece un boton para abrir la
  /// noticia original en el navegador y leerla entera.
  factory Noticia.fromApi(Map<String, dynamic> json, Categoria categoria) {
    final fuenteMapa = json['source'] as Map<String, dynamic>?;
    final url = json['url'] as String? ?? '';
    return Noticia(
      id: url.isNotEmpty ? url : DateTime.now().microsecondsSinceEpoch.toString(),
      titulo: (json['title'] as String?)?.trim().isNotEmpty == true
          ? json['title'] as String
          : 'Sin titulo',
      resumen: (json['description'] as String?) ?? '',
      contenido: (json['content'] as String?) ?? '',
      fuente: (fuenteMapa?['name'] as String?) ?? 'Fuente desconocida',
      fecha: (json['publishedAt'] as String?) ?? '',
      imagenUrl: json['urlToImage'] as String?,
      urlOriginal: url,
      categoria: categoria,
    );
  }

  /// Convierte la noticia a un mapa simple para guardarla localmente
  /// (favoritos o cache), incluyendo el id de categoria para poder
  /// reconstruirla despues.
  Map<String, dynamic> toJson() => {
        'id': id,
        'titulo': titulo,
        'resumen': resumen,
        'contenido': contenido,
        'fuente': fuente,
        'fecha': fecha,
        'imagenUrl': imagenUrl,
        'urlOriginal': urlOriginal,
        'categoriaId': categoria.id,
      };

  factory Noticia.fromJson(Map<String, dynamic> json) {
    return Noticia(
      id: json['id'] as String,
      titulo: json['titulo'] as String,
      resumen: json['resumen'] as String,
      contenido: json['contenido'] as String,
      fuente: json['fuente'] as String,
      fecha: json['fecha'] as String,
      imagenUrl: json['imagenUrl'] as String?,
      urlOriginal: json['urlOriginal'] as String? ?? '',
      categoria: Categoria.porId(json['categoriaId'] as String),
    );
  }
}

/// Representa una categoria de noticias, con su nombre y color asociado
/// para mantener la misma identidad visual definida en los wireframes.
/// El id de cada categoria (salvo "todas") corresponde directamente al
/// parametro "category" que espera NewsAPI.org.
class Categoria {
  final String id;
  final String nombre;
  final Color color;

  /// Palabras clave en español usadas para buscar esta categoria en la API.
  final String consulta;

  const Categoria({
    required this.id,
    required this.nombre,
    required this.color,
    this.consulta = '',
  });

  static const todas = Categoria(id: 'todas', nombre: 'Todas', color: Color(0xFF1F6FB2));
  static const deportes = Categoria(id: 'sports', nombre: 'Deportes', color: Color(0xFFE8A33D), consulta: '(futbol OR deporte OR deportes OR campeonato)');
  static const farandula = Categoria(id: 'entertainment', nombre: 'Farandula', color: Color(0xFFB24D8F), consulta: '(farandula OR espectaculos OR cine OR musica OR famosos)');
  static const tecnologia = Categoria(id: 'technology', nombre: 'Tecnologia', color: Color(0xFF1F6FB2), consulta: '(tecnologia OR celulares OR "inteligencia artificial" OR internet)');
  static const economia = Categoria(id: 'business', nombre: 'Economia', color: Color(0xFF4C9A6A), consulta: '(economia OR negocios OR empresas OR finanzas)');
  static const salud = Categoria(id: 'health', nombre: 'Salud', color: Color(0xFFD9534F), consulta: '(salud OR medicina OR hospital OR enfermedad)');
  static const ciencia = Categoria(id: 'science', nombre: 'Ciencia', color: Color(0xFF6B4FA0), consulta: '(ciencia OR investigacion OR cientificos OR espacio)');
  static const general = Categoria(id: 'general', nombre: 'General', color: Color(0xFF4A4A4A), consulta: '(noticias OR actualidad OR sociedad)');

  static const List<Categoria> lista = [
    deportes, farandula, tecnologia, economia, salud, ciencia, general,
  ];

  static Categoria porId(String id) {
    return [todas, ...lista].firstWhere(
      (c) => c.id == id,
      orElse: () => general,
    );
  }
}
