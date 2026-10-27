// Autor: Jhoel Percy Gonzales Herrera
// Funcion: pruebas de NewsService con respuestas simuladas de la API
// (no usa internet): consulta en español, errores y duplicados.
import 'dart:convert';

import 'package:canal_informativo_virtual/models/noticia.dart';
import 'package:canal_informativo_virtual/models/region.dart';
import 'package:canal_informativo_virtual/services/news_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

String _respuestaOk(List<Map<String, dynamic>> articulos, {int total = 2}) => jsonEncode({
      'status': 'ok',
      'totalResults': total,
      'articles': articulos,
    });

Map<String, dynamic> _articulo(String titulo, String url) => {
      'source': {'name': 'La Razon'},
      'title': titulo,
      'description': 'Resumen de $titulo',
      'content': 'Contenido',
      'url': url,
      'urlToImage': null,
      'publishedAt': '2026-10-13T21:47:36Z',
    };

void main() {
  group('NewsService - consulta en español', () {
    test('construirConsulta combina region y categoria', () {
      expect(
        NewsService.construirConsulta(Categoria.deportes, Region.bolivia, ''),
        contains('Bolivia AND'),
      );
      expect(
        NewsService.construirConsulta(Categoria.todas, Region.espana, ''),
        'España',
      );
    });

    test('construirConsulta da prioridad al termino de busqueda', () {
      expect(
        NewsService.construirConsulta(Categoria.deportes, Region.bolivia, '  litio  '),
        'litio',
      );
    });

    test('la peticion pide language=es, orden por fecha y la pagina indicada', () async {
      late Uri uriRecibida;
      final cliente = MockClient((peticion) async {
        uriRecibida = peticion.url;
        return http.Response(_respuestaOk([_articulo('Noticia 1', 'https://a.com/1')]), 200);
      });
      final servicio = NewsService(cliente: cliente, apiKey: 'clave-de-prueba');

      await servicio.obtenerNoticias(Categoria.economia, region: Region.bolivia, pagina: 2);

      expect(uriRecibida.host, 'newsapi.org');
      expect(uriRecibida.path, '/v2/everything');
      expect(uriRecibida.queryParameters['language'], 'es');
      expect(uriRecibida.queryParameters['sortBy'], 'publishedAt');
      expect(uriRecibida.queryParameters['page'], '2');
      expect(uriRecibida.queryParameters['apiKey'], 'clave-de-prueba');
    });
  });

  group('NewsService - lectura de datos', () {
    test('convierte los articulos en objetos Noticia y evita duplicados', () async {
      final cliente = MockClient((_) async => http.Response(
            _respuestaOk([
              _articulo('Primera', 'https://a.com/1'),
              _articulo('Primera repetida', 'https://a.com/1'),
              _articulo('[Removed]', 'https://a.com/2'),
              _articulo('Segunda', 'https://a.com/3'),
            ], total: 4),
            200,
          ));
      final servicio = NewsService(cliente: cliente, apiKey: 'k');

      final resultado = await servicio.obtenerNoticias(Categoria.todas);

      expect(resultado.noticias.map((n) => n.titulo), ['Primera', 'Segunda']);
      expect(resultado.totalResultados, 4);
      expect(resultado.noticias.first.fuente, 'La Razon');
    });

    test('decodifica correctamente tildes y la letra ñ (UTF-8)', () async {
      final cliente = MockClient.streaming((peticion, _) async {
        final bytes = utf8.encode(_respuestaOk([_articulo('Año nuevo en Bolivia: éxito', 'https://a.com/9')]));
        return http.StreamedResponse(Stream.value(bytes), 200);
      });
      final servicio = NewsService(cliente: cliente, apiKey: 'k');

      final resultado = await servicio.obtenerNoticias(Categoria.todas);

      expect(resultado.noticias.single.titulo, 'Año nuevo en Bolivia: éxito');
    });
  });

  group('NewsService - manejo de errores', () {
    Future<NewsServiceException> fallo(int codigo) async {
      final cliente = MockClient((_) async => http.Response('{}', codigo));
      final servicio = NewsService(cliente: cliente, apiKey: 'k');
      try {
        await servicio.obtenerNoticias(Categoria.todas);
      } on NewsServiceException catch (e) {
        return e;
      }
      fail('Se esperaba una NewsServiceException');
    }

    test('401 informa clave invalida', () async {
      expect((await fallo(401)).mensaje, contains('clave'));
    });

    test('429 informa limite de peticiones', () async {
      expect((await fallo(429)).mensaje, contains('limite'));
    });

    test('426 marca el fin de resultados del plan gratuito', () async {
      expect((await fallo(426)).limiteResultados, true);
    });

    test('sin internet lanza un mensaje claro', () async {
      final cliente = MockClient((_) async => throw http.ClientException('sin red'));
      final servicio = NewsService(cliente: cliente, apiKey: 'k');
      expect(
        () => servicio.obtenerNoticias(Categoria.todas),
        throwsA(isA<NewsServiceException>()
            .having((e) => e.mensaje, 'mensaje', contains('internet'))),
      );
    });

    test('sin clave configurada se avisa al usuario', () async {
      final servicio = NewsService(cliente: MockClient((_) async => http.Response('{}', 200)), apiKey: '');
      expect(() => servicio.obtenerNoticias(Categoria.todas), throwsA(isA<NewsServiceException>()));
    });
  });
}
