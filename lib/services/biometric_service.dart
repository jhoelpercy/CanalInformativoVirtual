// Autor: Jhoel Percy Gonzales Herrera
// Funcion: acceso a la biometria nativa del celular (local_auth).
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// Posibles estados del hardware y configuracion biometrica en el dispositivo.
enum EstadoBiometria {
  /// El dispositivo tiene hardware y el usuario ya tiene al menos una
  /// huella o dato biometrico registrado en los ajustes del celular.
  disponible,

  /// El dispositivo tiene sensor biometrico, pero el usuario no ha
  /// registrado ninguna huella en los ajustes de su telefono.
  sinRegistrar,

  /// El dispositivo no cuenta con hardware biometrico (o no es soportado).
  noSoportado,
}

/// Resultado detallado de un intento de autenticacion biometrica.
class ResultadoBiometria {
  final bool exitoso;
  final String? mensajeError;
  final LocalAuthExceptionCode? codigoError;
  final bool canceladoPorUsuario;

  const ResultadoBiometria({
    required this.exitoso,
    this.mensajeError,
    this.codigoError,
    this.canceladoPorUsuario = false,
  });

  const ResultadoBiometria.exito()
      : exitoso = true,
        mensajeError = null,
        codigoError = null,
        canceladoPorUsuario = false;

  const ResultadoBiometria.cancelado()
      : exitoso = false,
        mensajeError = null,
        codigoError = null,
        canceladoPorUsuario = true;

  const ResultadoBiometria.fallo({
    required this.mensajeError,
    this.codigoError,
  })  : exitoso = false,
        canceladoPorUsuario = false;
}

/// Servicio encargado de la comunicacion con la API nativa de biometria
/// del celular (Android / iOS) mediante el paquete local_auth.
class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  /// Comprueba si el dispositivo tiene hardware biometrico disponible.
  Future<bool> tieneHardwareBiometrico() async {
    try {
      final isSupported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      return isSupported && canCheck;
    } on PlatformException catch (e) {
      debugPrint('Error verificando hardware biometrico: $e');
      return false;
    } catch (e) {
      debugPrint('Error inesperado verificando hardware biometrico: $e');
      return false;
    }
  }

  /// Comprueba que tipos de biometria estan registrados en el telefono
  /// (por ejemplo huella dactilar, reconocimiento facial, etc.).
  Future<List<BiometricType>> obtenerBiometriasDisponibles() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      debugPrint('Error obteniendo biometrias disponibles: $e');
      return [];
    } catch (e) {
      debugPrint('Error inesperado obteniendo biometrias disponibles: $e');
      return [];
    }
  }

  /// Determina el estado exacto de la biometria en el dispositivo:
  /// - [EstadoBiometria.noSoportado] si el celular no tiene sensor.
  /// - [EstadoBiometria.sinRegistrar] si tiene sensor pero no hay huellas configuradas.
  /// - [EstadoBiometria.disponible] si tiene sensor y ya hay huellas registradas en el telefono.
  Future<EstadoBiometria> verificarEstado() async {
    try {
      final soporta = await tieneHardwareBiometrico();
      if (!soporta) {
        return EstadoBiometria.noSoportado;
      }

      final biometrias = await obtenerBiometriasDisponibles();
      if (biometrias.isEmpty) {
        return EstadoBiometria.sinRegistrar;
      }

      return EstadoBiometria.disponible;
    } catch (e) {
      debugPrint('Error verificando estado biometrico: $e');
      return EstadoBiometria.noSoportado;
    }
  }

  /// Ejecuta el proceso de autenticacion con la huella digital del celular.
  /// Retorna un [ResultadoBiometria] con el estado detallado.
  Future<ResultadoBiometria> autenticar({
    String mensaje = 'Usa tu huella digital para acceder a Canal Informativo Virtual',
  }) async {
    try {
      final resultado = await _auth.authenticate(
        localizedReason: mensaje,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );

      if (resultado) {
        return const ResultadoBiometria.exito();
      } else {
        return const ResultadoBiometria.cancelado();
      }
    } on LocalAuthException catch (e) {
      debugPrint('LocalAuthException: ${e.code} - ${e.description}');
      switch (e.code) {
        case LocalAuthExceptionCode.userCanceled:
        case LocalAuthExceptionCode.userRequestedFallback:
          return const ResultadoBiometria.cancelado();
        case LocalAuthExceptionCode.noBiometricsEnrolled:
          return const ResultadoBiometria.fallo(
            mensajeError: 'No hay huellas registradas en los ajustes de tu celular.',
            codigoError: LocalAuthExceptionCode.noBiometricsEnrolled,
          );
        case LocalAuthExceptionCode.noBiometricHardware:
          return const ResultadoBiometria.fallo(
            mensajeError: 'Este dispositivo no cuenta con sensor de huella digital.',
            codigoError: LocalAuthExceptionCode.noBiometricHardware,
          );
        case LocalAuthExceptionCode.temporaryLockout:
          return const ResultadoBiometria.fallo(
            mensajeError: 'Sensor bloqueado temporalmente por varios intentos fallidos. Usa tu PIN.',
            codigoError: LocalAuthExceptionCode.temporaryLockout,
          );
        case LocalAuthExceptionCode.biometricLockout:
          return const ResultadoBiometria.fallo(
            mensajeError: 'Sensor bloqueado. Por favor ingresa usando tu código PIN.',
            codigoError: LocalAuthExceptionCode.biometricLockout,
          );
        case LocalAuthExceptionCode.timeout:
          return const ResultadoBiometria.fallo(
            mensajeError: 'Tiempo de espera agotado. Vuelve a intentarlo.',
            codigoError: LocalAuthExceptionCode.timeout,
          );
        default:
          return ResultadoBiometria.fallo(
            mensajeError: e.description ?? 'Error al autenticar con huella.',
            codigoError: e.code,
          );
      }
    } on PlatformException catch (e) {
      debugPrint('PlatformException: ${e.code} - ${e.message}');
      return ResultadoBiometria.fallo(
        mensajeError: e.message ?? 'No se pudo completar la autenticacion biometrica.',
      );
    } catch (e) {
      debugPrint('Error inesperado de autenticacion: $e');
      return const ResultadoBiometria.fallo(
        mensajeError: 'Ocurrio un error al intentar leer tu huella.',
      );
    }
  }

  /// Cancela cualquier proceso de autenticacion biometrica en curso.
  Future<void> cancelarAutenticacion() async {
    try {
      await _auth.stopAuthentication();
    } catch (_) {}
  }
}
