// Autor: Jhoel Percy Gonzales Herrera
// Funcion: pruebas de la utilidad que convierte fechas ISO a texto legible.
import 'package:canal_informativo_virtual/utils/fecha_util.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final ahora = DateTime.utc(2026, 10, 20, 12, 0, 0);

  test('menos de un minuto', () {
    expect(fechaLegible('2026-10-20T11:59:40Z', ahora: ahora), 'Hace un momento');
  });

  test('minutos', () {
    expect(fechaLegible('2026-10-20T11:30:00Z', ahora: ahora), 'Hace 30 min');
  });

  test('horas', () {
    expect(fechaLegible('2026-10-20T09:00:00Z', ahora: ahora), 'Hace 3 h');
  });

  test('dias (singular y plural)', () {
    expect(fechaLegible('2026-10-19T11:00:00Z', ahora: ahora), 'Hace 1 dia');
    expect(fechaLegible('2026-10-16T11:00:00Z', ahora: ahora), 'Hace 4 dias');
  });

  test('mas de una semana muestra la fecha', () {
    expect(fechaLegible('2026-10-01T12:00:00Z', ahora: ahora), contains('oct 2026'));
  });

  test('fecha vacia o invalida devuelve cadena vacia', () {
    expect(fechaLegible('', ahora: ahora), '');
    expect(fechaLegible('no es fecha', ahora: ahora), '');
  });
}
