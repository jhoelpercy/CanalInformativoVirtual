// Autor: Jhoel Percy Gonzales Herrera
// Funcion: conversion de fechas ISO a texto legible en español.
/// Convierte la fecha ISO 8601 que entrega la API (por ejemplo
/// 2026-10-13T21:47:36Z) en un texto facil de leer en español:
/// "Hace 3 h", "Hace 2 dias" o "13 oct 2026".
/// Devuelve una cadena vacia si la fecha no es valida.
String fechaLegible(String iso, {DateTime? ahora}) {
  final fecha = DateTime.tryParse(iso)?.toLocal();
  if (fecha == null) return '';

  final referencia = ahora ?? DateTime.now();
  final diferencia = referencia.difference(fecha);

  if (diferencia.isNegative || diferencia.inMinutes < 1) return 'Hace un momento';
  if (diferencia.inMinutes < 60) return 'Hace ${diferencia.inMinutes} min';
  if (diferencia.inHours < 24) return 'Hace ${diferencia.inHours} h';
  if (diferencia.inDays < 7) {
    final dias = diferencia.inDays;
    return 'Hace $dias ${dias == 1 ? 'dia' : 'dias'}';
  }

  const meses = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
  ];
  return '${fecha.day} ${meses[fecha.month - 1]} ${fecha.year}';
}
