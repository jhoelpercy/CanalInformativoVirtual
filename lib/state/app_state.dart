// Autor: Jhoel Percy Gonzales Herrera
// Funcion: estado central de la app (ChangeNotifier).
import 'package:flutter/material.dart';
import '../models/noticia.dart';
import '../models/region.dart';
import '../services/biometric_service.dart';
import '../services/news_service.dart';
import '../services/storage_service.dart';

/// Estado centralizado de la aplicacion (gestion del estado - Semana 5).
///
/// En lugar de que cada pantalla maneje su propia copia de las noticias,
/// los favoritos o el estado de carga, todo eso vive aqui en un solo
/// lugar. Las pantallas escuchan los cambios con ListenableBuilder y
/// llaman a los metodos de esta clase para modificar el estado, que a
/// su vez se encarga de hablar con NewsService (API) y StorageService
/// (persistencia local).
class AppState extends ChangeNotifier {
  AppState({
    NewsService? newsService,
    StorageService? storageService,
    BiometricService? biometricService,
  })  : _newsService = newsService ?? NewsService(),
        _storageService = storageService ?? StorageService(),
        _biometricService = biometricService ?? BiometricService();

  static const String pinPorDefecto = '1234';

  final NewsService _newsService;
  final StorageService _storageService;
  final BiometricService _biometricService;

  BiometricService get biometricService => _biometricService;
  EstadoBiometria estadoBiometria = EstadoBiometria.noSoportado;
  bool usarBiometria = true;

  // ---------- Preferencias ----------
  Region region = Region.bolivia;
  ThemeMode modoTema = ThemeMode.system;

  /// true si el usuario todavia no cambio el PIN por defecto.
  bool usaPinPorDefecto = false;

  /// Evita repetir el aviso de "cambia tu PIN" mas de una vez por sesion.
  bool avisoPinMostrado = false;

  // ---------- Noticias ----------
  Categoria categoriaActiva = Categoria.todas;
  String terminoBusqueda = '';
  List<Noticia> noticias = [];
  List<Noticia> favoritos = [];
  Map<String, int> _contadorCategorias = {};

  bool cargando = false;
  bool cargandoMas = false;
  bool mostrandoCache = false;
  String? error;

  /// Mensaje breve pendiente de mostrar en un SnackBar (por ejemplo, si
  /// fallo la carga de mas noticias). Se lee con [consumirAviso].
  String? _avisoPendiente;

  int _paginaActual = 1;
  int _totalResultados = 0;

  bool get buscando => terminoBusqueda.isNotEmpty;

  /// true cuando ya se cargaron todas las noticias disponibles para
  /// la categoria actual y no tiene sentido seguir pidiendo mas.
  bool get hayMasNoticias =>
      !mostrandoCache && noticias.length < _totalResultados;

  /// Devuelve el aviso pendiente (si hay) y lo borra para no repetirlo.
  String? consumirAviso() {
    final aviso = _avisoPendiente;
    _avisoPendiente = null;
    return aviso;
  }

  /// Carga las preferencias guardadas (tema y region). Se llama al abrir
  /// la aplicacion, antes de mostrar la pantalla de bloqueo.
  Future<void> cargarPreferencias() async {
    region = Region.porId(await _storageService.cargarRegion());
    modoTema = _temaDesdeTexto(await _storageService.cargarTema());
    notifyListeners();
  }

  /// Se llama una sola vez, apenas el usuario desbloquea la aplicacion.
  Future<void> inicializar() async {
    favoritos = await _storageService.cargarFavoritos();
    _contadorCategorias = await _storageService.cargarContadorCategorias();
    usarBiometria = await _storageService.cargarUsarBiometria();
    usaPinPorDefecto = (await _storageService.cargarCodigo()) == pinPorDefecto;
    estadoBiometria = await _biometricService.verificarEstado();
    await cargarPreferencias();
    await cargarNoticias(Categoria.todas);
  }

  /// Categoria que el usuario consulta con mas frecuencia, usada para
  /// la seccion "Basado en tus intereses" de la pantalla de Inicio.
  /// Devuelve null si todavia no hay suficiente historial.
  Categoria? get categoriaSugerida {
    if (_contadorCategorias.isEmpty) return null;
    final entradaMax =
        _contadorCategorias.entries.reduce((a, b) => a.value >= b.value ? a : b);
    if (entradaMax.value < 2) return null;
    return Categoria.porId(entradaMax.key);
  }

  /// Clave con la que se guarda la cache: depende de la region y la
  /// categoria para no mezclar noticias de lugares distintos.
  String _claveCache(Categoria categoria) => '${region.id}_${categoria.id}';

  /// Cambia de categoria desde los chips o la pantalla de Categorias;
  /// al hacerlo se cancela cualquier busqueda por palabra.
  Future<void> seleccionarCategoria(Categoria categoria) {
    terminoBusqueda = '';
    return cargarNoticias(categoria);
  }

  /// Busca noticias por una palabra o frase escrita por el usuario.
  Future<void> buscar(String termino) {
    terminoBusqueda = termino.trim();
    return cargarNoticias(Categoria.todas);
  }

  /// Quita la busqueda y vuelve a mostrar las noticias de la categoria.
  Future<void> limpiarBusqueda() => seleccionarCategoria(Categoria.todas);

  /// Cambia la region de las noticias y recarga el listado.
  Future<void> cambiarRegion(Region nueva) async {
    region = nueva;
    await _storageService.guardarRegion(nueva.id);
    terminoBusqueda = '';
    await cargarNoticias(categoriaActiva);
  }

  /// Cambia el tema visual (claro, oscuro o el del sistema).
  Future<void> cambiarTema(ThemeMode modo) async {
    modoTema = modo;
    await _storageService.guardarTema(_temaATexto(modo));
    notifyListeners();
  }

  ThemeMode _temaDesdeTexto(String texto) {
    switch (texto) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  String _temaATexto(ThemeMode modo) {
    switch (modo) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  /// Carga la PRIMERA pagina de noticias para una categoria (o para la
  /// busqueda actual) desde la API (RF01/RF02) y, si falla la conexion,
  /// recurre a la cache local (RF07). Reemplaza el listado actual.
  Future<void> cargarNoticias(Categoria categoria) async {
    categoriaActiva = categoria;
    cargando = true;
    error = null;
    mostrandoCache = false;
    _paginaActual = 1;
    _totalResultados = 0;
    notifyListeners();

    if (!buscando && categoria.id != 'todas') {
      _contadorCategorias[categoria.id] = (_contadorCategorias[categoria.id] ?? 0) + 1;
      await _storageService.guardarContadorCategorias(_contadorCategorias);
    }

    try {
      final resultado = await _newsService.obtenerNoticias(
        categoria,
        region: region,
        busqueda: terminoBusqueda,
        pagina: 1,
      );
      noticias = resultado.noticias;
      _totalResultados = resultado.totalResultados;
      if (!buscando) {
        await _storageService.guardarCache(_claveCache(categoria), resultado.noticias);
      }
    } on NewsServiceException catch (e) {
      final cache = buscando
          ? <Noticia>[]
          : await _storageService.cargarCache(_claveCache(categoria));
      if (cache.isNotEmpty) {
        noticias = cache;
        mostrandoCache = true;
        error = e.mensaje;
      } else {
        noticias = [];
        error = buscando
            ? e.mensaje
            : '${e.mensaje} Tampoco hay noticias guardadas para esta categoria todavia.';
      }
    } catch (_) {
      noticias = [];
      error = 'Ocurrio un error inesperado al cargar las noticias.';
    }

    cargando = false;
    notifyListeners();
  }

  /// Pide la SIGUIENTE pagina de noticias y la agrega al final del
  /// listado actual (scroll infinito). No hace nada si ya se estan
  /// mostrando noticias de cache (sin conexion) o si ya no hay mas
  /// resultados disponibles.
  Future<void> cargarMas() async {
    if (cargandoMas || cargando || mostrandoCache || !hayMasNoticias) return;

    cargandoMas = true;
    notifyListeners();

    try {
      final siguientePagina = _paginaActual + 1;
      final resultado = await _newsService.obtenerNoticias(
        categoriaActiva,
        region: region,
        busqueda: terminoBusqueda,
        pagina: siguientePagina,
      );
      if (resultado.noticias.isNotEmpty) {
        final idsActuales = noticias.map((n) => n.id).toSet();
        final nuevas = resultado.noticias.where((n) => !idsActuales.contains(n.id));
        noticias = [...noticias, ...nuevas];
        _paginaActual = siguientePagina;
        _totalResultados = resultado.totalResultados;
      } else {
        _totalResultados = noticias.length; // no hay mas, dejar de intentar
      }
    } on NewsServiceException catch (e) {
      // Las noticias ya cargadas se mantienen visibles. Solo se avisa al
      // usuario si el fallo NO es simplemente el fin de los resultados.
      _totalResultados = noticias.length;
      if (!e.limiteResultados) {
        _avisoPendiente = 'No se pudieron cargar mas noticias: ${e.mensaje}';
      }
    } catch (_) {
      _totalResultados = noticias.length;
      _avisoPendiente = 'No se pudieron cargar mas noticias.';
    }

    cargandoMas = false;
    notifyListeners();
  }

  /// Vuelve a pedir desde la primera pagina de la categoria actual
  /// (boton de actualizar manual, RF10).
  Future<void> actualizar() => cargarNoticias(categoriaActiva);

  bool esFavorito(Noticia noticia) => favoritos.any((n) => n.id == noticia.id);

  /// Agrega o quita una noticia de favoritos (RF03/RF04) y persiste
  /// el cambio de inmediato.
  Future<void> alternarFavorito(Noticia noticia) async {
    if (esFavorito(noticia)) {
      favoritos.removeWhere((n) => n.id == noticia.id);
    } else {
      favoritos.add(noticia);
    }
    notifyListeners();
    await _storageService.guardarFavoritos(favoritos);
  }

  /// Cambia el codigo de bloqueo, validando que sean 4 digitos
  /// numericos antes de guardarlo (RF09 - validacion de formularios).
  Future<String?> cambiarCodigo(String nuevoCodigo, String confirmacion) async {
    if (nuevoCodigo.length != 4 || int.tryParse(nuevoCodigo) == null) {
      return 'El codigo debe tener exactamente 4 digitos numericos.';
    }
    if (nuevoCodigo != confirmacion) {
      return 'Los dos codigos ingresados no coinciden.';
    }
    await _storageService.guardarCodigo(nuevoCodigo);
    usaPinPorDefecto = nuevoCodigo == pinPorDefecto;
    notifyListeners();
    return null; // null significa que no hubo error
  }

  Future<String> obtenerCodigoActual() => _storageService.cargarCodigo();

  /// Actualiza y refresca el estado biometrico del dispositivo
  Future<void> actualizarEstadoBiometria() async {
    estadoBiometria = await _biometricService.verificarEstado();
    usarBiometria = await _storageService.cargarUsarBiometria();
    notifyListeners();
  }

  /// Activa o desactiva el uso de la huella digital para desbloquear la app
  Future<void> alternarUsarBiometria(bool valor) async {
    usarBiometria = valor;
    await _storageService.guardarUsarBiometria(valor);
    notifyListeners();
  }
}
