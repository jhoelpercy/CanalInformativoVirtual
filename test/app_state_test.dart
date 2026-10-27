// Autor: Jhoel Percy Gonzales Herrera
// Funcion: pruebas de AppState (favoritos, cambio de PIN, busqueda,
// region, tema, cache sin conexion) con un servicio de noticias simulado.
import 'dart:convert';

import 'package:canal_informativo_virtual/models/noticia.dart';
import 'package:canal_informativo_virtual/models/region.dart';
import 'package:canal_informativo_virtual/services/news_service.dart';
import 'package:canal_informativo_virtual/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

Noticia _noticia(String id) => Noticia(
      id: id,
      titulo: 'Titulo $id',
      resumen: 'Resumen',
      contenido: '',
      fuente: 'Fuente',
      fecha: '2026-10-13T21:47:36Z',
      categoria: Categoria.general,
      urlOriginal: id,
    );

/// Crea un AppState cuyo servicio responde siempre con [cuerpo], o lanza
/// un error de red si [sinRed] es true. Guarda las consultas recibidas.
AppState _crearEstado({bool sinRed = false, List<Uri>? consultas}) {
  final cliente = MockClient((peticion) async {
    consultas?.add(peticion.url);
    if (sinRed) throw http.ClientException('sin red');
    return http.Response(
      jsonEncode({
        'status': 'ok',
        'totalResults': 1,
        'articles': [
          {
            'source': {'name': 'La Razon'},
            'title': 'Noticia de prueba',
            'description': 'Resumen',
            'content': '',
            'url': 'https://a.com/1',
            'publishedAt': '2026-10-13T21:47:36Z',
          }
        ],
      }),
      200,
    );
  });
  return AppState(newsService: NewsService(cliente: cliente, apiKey: 'k'));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('AppState - favoritos', () {
    test('alternarFavorito agrega y quita una noticia y persiste el cambio', () async {
      final estado = _crearEstado();
      final noticia = _noticia('1');

      await estado.alternarFavorito(noticia);
      expect(estado.esFavorito(noticia), true);

      final otroEstado = _crearEstado();
      await otroEstado.inicializar();
      expect(otroEstado.favoritos.map((n) => n.id), ['1']);

      await estado.alternarFavorito(noticia);
      expect(estado.esFavorito(noticia), false);
    });
  });

  group('AppState - cambio de codigo (validacion de formulario)', () {
    test('rechaza codigos que no tienen 4 digitos numericos', () async {
      final estado = _crearEstado();
      expect(await estado.cambiarCodigo('12', '12'), isNotNull);
      expect(await estado.cambiarCodigo('abcd', 'abcd'), isNotNull);
      expect(await estado.cambiarCodigo('', ''), isNotNull);
    });

    test('rechaza codigos que no coinciden', () async {
      final estado = _crearEstado();
      expect(await estado.cambiarCodigo('1111', '2222'), contains('no coinciden'));
    });

    test('guarda un codigo valido y deja de usar el PIN por defecto', () async {
      final estado = _crearEstado();
      expect(await estado.cambiarCodigo('4321', '4321'), isNull);
      expect(await estado.obtenerCodigoActual(), '4321');
      expect(estado.usaPinPorDefecto, false);
    });
  });

  group('AppState - noticias', () {
    test('cargarNoticias llena el listado y guarda la cache', () async {
      final estado = _crearEstado();
      await estado.cargarNoticias(Categoria.deportes);
      expect(estado.noticias, hasLength(1));
      expect(estado.error, isNull);
      expect(estado.mostrandoCache, false);
    });

    test('sin internet usa la cache guardada y avisa con un banner', () async {
      final conRed = _crearEstado();
      await conRed.cargarNoticias(Categoria.deportes); // llena la cache

      final sinRed = _crearEstado(sinRed: true);
      await sinRed.cargarNoticias(Categoria.deportes);

      expect(sinRed.mostrandoCache, true);
      expect(sinRed.noticias, hasLength(1));
      expect(sinRed.error, isNotNull);
    });

    test('sin internet y sin cache muestra el mensaje de error', () async {
      final estado = _crearEstado(sinRed: true);
      await estado.cargarNoticias(Categoria.salud);
      expect(estado.noticias, isEmpty);
      expect(estado.error, contains('Tampoco hay noticias guardadas'));
    });

    test('buscar envia el termino a la API y limpiarBusqueda lo quita', () async {
      final consultas = <Uri>[];
      final estado = _crearEstado(consultas: consultas);

      await estado.buscar('  litio  ');
      expect(estado.buscando, true);
      expect(estado.terminoBusqueda, 'litio');
      expect(consultas.last.queryParameters['q'], 'litio');

      await estado.limpiarBusqueda();
      expect(estado.buscando, false);
      expect(consultas.last.queryParameters['q'], 'Bolivia');
    });
  });

  group('AppState - preferencias', () {
    test('cambiarRegion recarga las noticias con la nueva region y la guarda', () async {
      final consultas = <Uri>[];
      final estado = _crearEstado(consultas: consultas);

      await estado.cambiarRegion(Region.espana);
      expect(estado.region.id, 'es');
      expect(consultas.last.queryParameters['q'], 'España');

      final otro = _crearEstado();
      await otro.cargarPreferencias();
      expect(otro.region.id, 'es');
    });

    test('cambiarTema persiste el modo oscuro', () async {
      final estado = _crearEstado();
      await estado.cambiarTema(ThemeMode.dark);

      final otro = _crearEstado();
      await otro.cargarPreferencias();
      expect(otro.modoTema, ThemeMode.dark);
    });
  });
}
