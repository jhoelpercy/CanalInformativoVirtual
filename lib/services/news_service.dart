// Autor: Jhoel Percy Gonzales Herrera
// Funcion: conexion con NewsAPI.org para obtener noticias en español.
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/noticia.dart';
import '../models/region.dart';

/// Excepcion especifica para errores al consultar la API de noticias,
/// usada para poder mostrar mensajes claros al usuario (RF09 / manejo
/// de errores de conexion de la Semana 6).
class NewsServiceException implements Exception {
  final String mensaje;

  /// true cuando la API indica que ya no entrega mas resultados para
  /// esta busqueda (limite del plan gratuito: 100 resultados).
  final bool limiteResultados;

  NewsServiceException(this.mensaje, {this.limiteResultados = false});

  @override
  String toString() => mensaje;
}

/// Resultado de una consulta a la API: la pagina de noticias obtenida
/// y el total de resultados que existen para esa busqueda, necesario
/// para saber cuando ya no hay mas paginas que cargar.
class ResultadoNoticias {
  final List<Noticia> noticias;
  final int totalResultados;
  ResultadoNoticias({required this.noticias, required this.totalResultados});
}

/// Encargado de conectarse con NewsAPI.org (RF01) y devolver una lista
/// de objetos Noticia ya lista para usar en la interfaz.
///
/// Se usa el endpoint /v2/everything con language=es porque el endpoint
/// /v2/top-headlines no devuelve resultados para paises hispanohablantes
/// en el plan gratuito. La region y la categoria se convierten en una
/// consulta de palabras clave (ver [construirConsulta]).
class NewsService {
  NewsService({http.Client? cliente, String? apiKey})
      : _cliente = cliente ?? http.Client(),
        _apiKey = apiKey ?? ApiConfig.newsApiKey;

  final http.Client _cliente;
  final String _apiKey;

  static const String _baseUrl = 'https://newsapi.org/v2/everything';
  static const int _porPagina = 20;

  /// Arma la expresion de busqueda: si el usuario escribio un termino
  /// se busca ese termino; si no, se combinan la region y la categoria.
  static String construirConsulta(Categoria categoria, Region region, String busqueda) {
    final termino = busqueda.trim();
    if (termino.isNotEmpty) return termino;
    if (categoria.id == 'todas' || categoria.consulta.isEmpty) return region.consulta;
    return '${region.consulta} AND ${categoria.consulta}';
  }

  /// Obtiene una pagina de noticias en español. [pagina] empieza en 1.
  Future<ResultadoNoticias> obtenerNoticias(
    Categoria categoria, {
    Region region = Region.bolivia,
    String busqueda = '',
    int pagina = 1,
  }) async {
    if (_apiKey.isEmpty || _apiKey == 'TU_API_KEY_AQUI') {
      throw NewsServiceException(
        'Falta configurar la clave de la API (lib/config/api_config.dart).',
      );
    }

    final uri = Uri.parse(_baseUrl).replace(queryParameters: {
      'q': construirConsulta(categoria, region, busqueda),
      'language': 'es',
      'sortBy': 'publishedAt',
      'pageSize': _porPagina.toString(),
      'page': pagina.toString(),
      'apiKey': _apiKey,
    });

    http.Response respuesta;
    try {
      respuesta = await _cliente.get(uri).timeout(const Duration(seconds: 12));
    } catch (_) {
      // Sin internet, servidor caido, timeout, etc.
      throw NewsServiceException(
        'No se pudo conectar a internet. Mostrando noticias guardadas.',
      );
    }

    if (respuesta.statusCode == 401) {
      throw NewsServiceException('La clave de la API no es valida.');
    }
    if (respuesta.statusCode == 426) {
      throw NewsServiceException(
        'El plan gratuito solo permite ver los primeros 100 resultados.',
        limiteResultados: true,
      );
    }
    if (respuesta.statusCode == 429) {
      throw NewsServiceException(
        'Se alcanzo el limite diario de peticiones gratuitas de la API.',
      );
    }
    if (respuesta.statusCode != 200) {
      throw NewsServiceException(
        'La API respondio con un error (codigo ${respuesta.statusCode}).',
      );
    }

    final datos = jsonDecode(utf8.decode(respuesta.bodyBytes)) as Map<String, dynamic>;
    if (datos['status'] != 'ok') {
      throw NewsServiceException(
        datos['message'] as String? ?? 'Error desconocido al leer las noticias.',
      );
    }

    final articulos = (datos['articles'] as List).cast<Map<String, dynamic>>();
    final categoriaAsignada = categoria.id == 'todas' ? Categoria.general : categoria;

    // Se descartan articulos eliminados y se evitan duplicados por URL.
    final vistos = <String>{};
    final noticias = articulos
        .map((a) => Noticia.fromApi(a, categoriaAsignada))
        .where((n) => n.titulo != '[Removed]' && vistos.add(n.id))
        .toList();

    return ResultadoNoticias(
      noticias: noticias,
      totalResultados: datos['totalResults'] as int? ?? noticias.length,
    );
  }
}
