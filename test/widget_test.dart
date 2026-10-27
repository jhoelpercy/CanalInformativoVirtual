import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:canal_informativo_virtual/services/storage_service.dart';
import 'package:canal_informativo_virtual/services/biometric_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Pruebas de StorageService y Biometria', () {
    test('StorageService guarda y carga codigo PIN correctamente', () async {
      SharedPreferences.setMockInitialValues({'codigo_bloqueo': '5678'});
      final storage = StorageService();

      final codigo = await storage.cargarCodigo();
      expect(codigo, '5678');

      await storage.guardarCodigo('9999');
      final nuevoCodigo = await storage.cargarCodigo();
      expect(nuevoCodigo, '9999');
    });

    test('StorageService persiste la preferencia de biometria', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = StorageService();

      // Por defecto true
      final valorInicial = await storage.cargarUsarBiometria();
      expect(valorInicial, true);

      await storage.guardarUsarBiometria(false);
      final valorModificado = await storage.cargarUsarBiometria();
      expect(valorModificado, false);
    });

    test('ResultadoBiometria modela adecuadamente exito, cancelacion y fallo', () {
      const exito = ResultadoBiometria.exito();
      expect(exito.exitoso, true);
      expect(exito.canceladoPorUsuario, false);

      const cancelado = ResultadoBiometria.cancelado();
      expect(cancelado.exitoso, false);
      expect(cancelado.canceladoPorUsuario, true);

      const fallo = ResultadoBiometria.fallo(mensajeError: 'Sensor sucio');
      expect(fallo.exitoso, false);
      expect(fallo.mensajeError, 'Sensor sucio');
    });
  });
}
