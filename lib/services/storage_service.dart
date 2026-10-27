// Autor: Jhoel Percy Gonzales Herrera
// Funcion: persistencia local (favoritos, cache, PIN y preferencias).
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/noticia.dart';

/// Encargado de toda la persistencia local de la aplicacion:
/// noticias favoritas, cache de noticias por categoria (para el modo
/// sin conexion) y el codigo de bloqueo configurado.
///
/// Implementa la politica de almacenamiento offline definida en la
/// Semana 1 / Semana 3: maximo 20 noticias por categoria en cache,
/// con una antiguedad maxima de 7 dias; y un tope de 200 favoritos,
/// estos ultimos sin limite de tiempo ya que el usuario los guardo
/// a proposito.
class StorageService {
  static const _claveFavoritos = 'favoritos';
  static const _prefijoCache = 'cache_';
  static const _prefijoCacheFecha = 'cache_fecha_';
  static const _claveCodigo = 'codigo_bloqueo';
  static const _claveUsarBiometria = 'usar_biometria';
  static const _claveContadorCategorias = 'contador_categorias';
  static const _claveRegion = 'region';
  static const _claveTema = 'tema';
  static const _claveBloqueoHasta = 'bloqueo_hasta';

  static const int _maxPorCategoria = 20;
  static const int _maxFavoritos = 200;
  static const int _diasVigenciaCache = 7;

  // ---------- FAVORITOS ----------

  Future<List<Noticia>> cargarFavoritos() async {
    final prefs = await SharedPreferences.getInstance();
    final lista = prefs.getStringList(_claveFavoritos) ?? [];
    return lista
        .map((s) => Noticia.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  Future<void> guardarFavoritos(List<Noticia> favoritos) async {
    final prefs = await SharedPreferences.getInstance();
    final limitados = favoritos.length > _maxFavoritos
        ? favoritos.sublist(favoritos.length - _maxFavoritos)
        : favoritos;
    final lista = limitados.map((n) => jsonEncode(n.toJson())).toList();
    await prefs.setStringList(_claveFavoritos, lista);
  }

  // ---------- CACHE POR CATEGORIA (modo sin conexion) ----------

  Future<void> guardarCache(String categoriaId, List<Noticia> noticias) async {
    final prefs = await SharedPreferences.getInstance();
    final limitadas = noticias.take(_maxPorCategoria).toList();
    final lista = limitadas.map((n) => jsonEncode(n.toJson())).toList();
    await prefs.setStringList('$_prefijoCache$categoriaId', lista);
    await prefs.setString(
      '$_prefijoCacheFecha$categoriaId',
      DateTime.now().toIso8601String(),
    );
  }

  Future<List<Noticia>> cargarCache(String categoriaId) async {
    final prefs = await SharedPreferences.getInstance();
    final fechaGuardada = prefs.getString('$_prefijoCacheFecha$categoriaId');

    if (fechaGuardada != null) {
      final fecha = DateTime.tryParse(fechaGuardada);
      if (fecha != null &&
          DateTime.now().difference(fecha).inDays > _diasVigenciaCache) {
        // La cache de esta categoria ya supero los 7 dias de vigencia:
        // se descarta para no mostrar contenido demasiado antiguo.
        await prefs.remove('$_prefijoCache$categoriaId');
        await prefs.remove('$_prefijoCacheFecha$categoriaId');
        return [];
      }
    }

    final lista = prefs.getStringList('$_prefijoCache$categoriaId') ?? [];
    return lista
        .map((s) => Noticia.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  // ---------- CODIGO DE BLOQUEO ----------

  Future<String> cargarCodigo() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_claveCodigo) ?? '1234';
  }

  Future<void> guardarCodigo(String nuevoCodigo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_claveCodigo, nuevoCodigo);
  }

  // ---------- BIOMETRIA (HUELLA DIGITAL) ----------

  Future<bool> cargarUsarBiometria() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_claveUsarBiometria) ?? true;
  }

  Future<void> guardarUsarBiometria(bool usar) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_claveUsarBiometria, usar);
  }

  // ---------- CONTADOR DE CATEGORIAS (para sugerencias en Inicio) ----------

  Future<Map<String, int>> cargarContadorCategorias() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_claveContadorCategorias);
    if (json == null) return {};
    final mapa = jsonDecode(json) as Map<String, dynamic>;
    return mapa.map((k, v) => MapEntry(k, v as int));
  }

  Future<void> guardarContadorCategorias(Map<String, int> contador) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_claveContadorCategorias, jsonEncode(contador));
  }

  // ---------- REGION DE NOTICIAS ----------

  Future<String> cargarRegion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_claveRegion) ?? 'bo';
  }

  Future<void> guardarRegion(String regionId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_claveRegion, regionId);
  }

  // ---------- TEMA (claro / oscuro / sistema) ----------

  Future<String> cargarTema() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_claveTema) ?? 'system';
  }

  Future<void> guardarTema(String tema) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_claveTema, tema);
  }

  // ---------- BLOQUEO TEMPORAL POR INTENTOS FALLIDOS DE PIN ----------

  /// Momento (milisegundos desde 1970) hasta el cual el PIN esta bloqueado.
  Future<int> cargarBloqueoHasta() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_claveBloqueoHasta) ?? 0;
  }

  Future<void> guardarBloqueoHasta(int milisegundos) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_claveBloqueoHasta, milisegundos);
  }
}
