// Autor: Jhoel Percy Gonzales Herrera
// Funcion: pantalla de bloqueo con PIN, huella digital y bloqueo por intentos.
import 'dart:async';
import 'package:flutter/material.dart';
import '../services/biometric_service.dart';
import '../services/storage_service.dart';
import '../state/app_state.dart';
import 'main_scaffold.dart';

/// Pantalla de bloqueo: primera pantalla que ve el usuario al abrir la app.
///
/// Soporta dos metodos de autenticacion de forma totalmente integrada:
/// 1. Huella digital / biometria nativa del celular (usando la huella ya
///    registrada en el dispositivo).
/// 2. Codigo PIN numerico de 4 digitos (por defecto "1234" o el configurado
///    por el usuario).
///
/// Maneja exhaustivamente los siguientes casos de biometria:
/// - Dispositivo SIN hardware biometrico -> Se oculta la opcion biometrica y
///   se ingresa exclusivamente por PIN sin generar errores.
/// - Dispositivo CON hardware pero SIN huellas registradas en los Ajustes ->
///   Se informa amigablemente al usuario que puede registrar su huella en
///   los Ajustes de su telefono o acceder con su PIN.
/// - Dispositivo CON huella registrada -> Solicita autenticacion con la huella
///   del celular de forma automatica y ofrece un boton en el teclado para
///   reintentar en cualquier momento si fue cancelada.
class LockScreen extends StatefulWidget {
  final AppState appState;
  const LockScreen({super.key, required this.appState});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  static const _azul = Color(0xFF1F6FB2);

  final StorageService _storageService = StorageService();
  final BiometricService _biometricService = BiometricService();

  String _codigoIngresado = '';
  String _codigoValido = '1234';
  bool _errorCodigo = false;
  bool _cargandoInicial = true;

  EstadoBiometria _estadoBiometria = EstadoBiometria.noSoportado;
  bool _usarBiometria = true;
  bool _autenticandoBiometria = false;
  String? _mensajeBiometria;

  // Bloqueo temporal tras varios intentos fallidos de PIN.
  static const int _maxIntentos = 5;
  static const int _segundosBloqueo = 30;
  int _intentosFallidos = 0;
  int _segundosRestantes = 0;
  Timer? _temporizadorBloqueo;

  @override
  void initState() {
    super.initState();
    _inicializarSeguridad();
  }

  /// Carga el codigo guardado, la preferencia de biometria y comprueba el
  /// estado del hardware/huellas del celular.
  @override
  void dispose() {
    _temporizadorBloqueo?.cancel();
    super.dispose();
  }

  /// Inicia (o reanuda) la cuenta regresiva del bloqueo temporal.
  void _iniciarBloqueo(int hastaMilisegundos) {
    _temporizadorBloqueo?.cancel();
    void actualizar() {
      final restante = ((hastaMilisegundos - DateTime.now().millisecondsSinceEpoch) / 1000).ceil();
      if (!mounted) return;
      setState(() => _segundosRestantes = restante > 0 ? restante : 0);
      if (restante <= 0) _temporizadorBloqueo?.cancel();
    }

    actualizar();
    _temporizadorBloqueo = Timer.periodic(const Duration(seconds: 1), (_) => actualizar());
  }

  Future<void> _inicializarSeguridad() async {
    final bloqueoHasta = await _storageService.cargarBloqueoHasta();
    if (bloqueoHasta > DateTime.now().millisecondsSinceEpoch) {
      _iniciarBloqueo(bloqueoHasta);
    }
    final codigo = await _storageService.cargarCodigo();
    final usarBio = await _storageService.cargarUsarBiometria();
    final estadoBio = await _biometricService.verificarEstado();

    if (!mounted) return;
    setState(() {
      _codigoValido = codigo;
      _usarBiometria = usarBio;
      _estadoBiometria = estadoBio;
      _cargandoInicial = false;
    });

    // Si el dispositivo cuenta con huella registrada y la opcion esta activa,
    // se solicita la huella automaticamente una vez mostrada la pantalla.
    if (_estadoBiometria == EstadoBiometria.disponible && _usarBiometria) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 350), () {
          if (mounted) _autenticarConHuella();
        });
      });
    }
  }

  Future<void> _entrarALaApp() async {
    await widget.appState.inicializar();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => MainScaffold(appState: widget.appState)),
    );
  }

  /// Ejecuta la autenticacion por huella nativa del telefono.
  Future<void> _autenticarConHuella() async {
    if (_autenticandoBiometria) return;

    setState(() {
      _autenticandoBiometria = true;
      _mensajeBiometria = null;
    });

    final resultado = await _biometricService.autenticar(
      mensaje: 'Usa tu huella digital registrada para ingresar a la aplicacion',
    );

    if (!mounted) return;

    setState(() {
      _autenticandoBiometria = false;
    });

    if (resultado.exitoso) {
      await _entrarALaApp();
    } else if (resultado.mensajeError != null) {
      setState(() {
        _mensajeBiometria = resultado.mensajeError;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resultado.mensajeError!),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Dialogo informativo para cuando el celular tiene lector de huella
  /// pero el usuario no ha registrado ninguna en los ajustes de Android/iOS.
  void _mostrarDialogoSinHuella() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.fingerprint, size: 48, color: Colors.orange),
        title: const Text('Sin huella registrada'),
        content: const Text(
          'Tu celular cuenta con lector biometrico, pero aun no tienes ninguna huella '
          'registrada en los Ajustes del sistema.\n\n'
          'Para habilitar esta opcion, ve a los Ajustes de tu telefono > Seguridad / Biometria '
          'y registra tu huella digital.\n\n'
          'Mientras tanto, puedes acceder ingresando tu codigo PIN.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  void _presionarTecla(String valor) {
    if (_segundosRestantes > 0) return; // PIN bloqueado temporalmente
    setState(() {
      _errorCodigo = false;
      _mensajeBiometria = null;

      if (valor == '<') {
        if (_codigoIngresado.isNotEmpty) {
          _codigoIngresado = _codigoIngresado.substring(0, _codigoIngresado.length - 1);
        }
      } else if (_codigoIngresado.length < 4) {
        _codigoIngresado += valor;
      }

      if (_codigoIngresado.length == 4) {
        if (_codigoIngresado == _codigoValido) {
          Future.delayed(const Duration(milliseconds: 150), _entrarALaApp);
        } else {
          _errorCodigo = true;
          _codigoIngresado = '';
          _intentosFallidos++;
          if (_intentosFallidos >= _maxIntentos) {
            _intentosFallidos = 0;
            final hasta = DateTime.now().millisecondsSinceEpoch + _segundosBloqueo * 1000;
            _storageService.guardarBloqueoHasta(hasta);
            _iniciarBloqueo(hasta);
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_cargandoInicial) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 50),
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFFDCEBF7),
                shape: BoxShape.circle,
                border: Border.all(color: _azul, width: 2),
              ),
              child: const Icon(Icons.newspaper, color: _azul, size: 40),
            ),
            const SizedBox(height: 18),
            const Text(
              'Canal Informativo Virtual',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _construirMensajeEstado(),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) {
                final lleno = i < _codigoIngresado.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: lleno ? _azul : Colors.transparent,
                    border: Border.all(color: _azul),
                  ),
                );
              }),
            ),
            const SizedBox(height: 14),
            _construirBotonRapidoHuella(),
            const Spacer(),
            _teclado(),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  Widget _construirMensajeEstado() {
    if (_segundosRestantes > 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          'Demasiados intentos. Espera $_segundosRestantes s para volver a intentar.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
        ),
      );
    }
    if (_errorCodigo) {
      return const Text(
        'Codigo incorrecto, intenta de nuevo',
        style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
      );
    }
    if (_mensajeBiometria != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          _mensajeBiometria!,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.red, fontSize: 13),
        ),
      );
    }

    if (_estadoBiometria == EstadoBiometria.disponible && _usarBiometria) {
      return Text(
        'Ingresa tu codigo PIN o usa tu huella',
        style: TextStyle(color: Theme.of(context).hintColor),
      );
    }

    return Text(
      'Ingresa tu codigo de acceso',
      style: TextStyle(color: Theme.of(context).hintColor),
    );
  }

  Widget _construirBotonRapidoHuella() {
    if (_estadoBiometria == EstadoBiometria.disponible && _usarBiometria) {
      return TextButton.icon(
        onPressed: _autenticandoBiometria ? null : _autenticarConHuella,
        icon: _autenticandoBiometria
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: _azul),
              )
            : const Icon(Icons.fingerprint, color: _azul, size: 22),
        label: Text(
          _autenticandoBiometria ? 'Verificando huella...' : 'Desbloquear con huella',
          style: const TextStyle(color: _azul, fontWeight: FontWeight.w600),
        ),
      );
    }

    if (_estadoBiometria == EstadoBiometria.sinRegistrar) {
      return TextButton.icon(
        onPressed: _mostrarDialogoSinHuella,
        icon: Icon(Icons.info_outline, size: 16, color: Colors.orange.shade800),
        label: Text(
          'Sensor disponible sin huella registrada',
          style: TextStyle(color: Colors.orange.shade800, fontSize: 12.5),
        ),
      );
    }

    return const SizedBox(height: 24);
  }

  Widget _teclado() {
    // Posicion 9 es 'bio': boton de huella digital si el celular la soporta
    final teclas = ['1', '2', '3', '4', '5', '6', '7', '8', '9', 'bio', '0', '<'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.5,
        children: teclas.map((t) {
          if (t == 'bio') {
            return _construirTeclaBiometria();
          }

          final esBorrar = t == '<';
          return OutlinedButton(
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => _presionarTecla(t),
            child: esBorrar
                ? const Icon(Icons.backspace_outlined, size: 20)
                : Text(t, style: const TextStyle(fontSize: 18)),
          );
        }).toList(),
      ),
    );
  }

  Widget _construirTeclaBiometria() {
    if (_estadoBiometria == EstadoBiometria.noSoportado) {
      return const SizedBox.shrink();
    }

    if (_estadoBiometria == EstadoBiometria.sinRegistrar) {
      return OutlinedButton(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          side: BorderSide(color: Colors.orange.shade300),
        ),
        onPressed: _mostrarDialogoSinHuella,
        child: Icon(Icons.fingerprint, color: Colors.orange.shade700, size: 26),
      );
    }

    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: const BorderSide(color: _azul, width: 1.5),
        backgroundColor: const Color(0xFFF0F6FC),
      ),
      onPressed: _autenticandoBiometria ? null : _autenticarConHuella,
      child: _autenticandoBiometria
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: _azul),
            )
          : const Icon(Icons.fingerprint, color: _azul, size: 28),
    );
  }
}
