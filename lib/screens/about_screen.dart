// Autor: Jhoel Percy Gonzales Herrera
// Funcion: pantalla Acerca de: descripcion, autor y herramientas.
import 'package:flutter/material.dart';

/// Pantalla "Acerca de": describe la aplicacion, su version, el
/// autor y las herramientas con las que fue construida.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const Color _azul = Color(0xFF1F6FB2);

  @override
  Widget build(BuildContext context) {
    final estiloGris = TextStyle(color: Theme.of(context).hintColor, fontSize: 13);

    return Scaffold(
      appBar: AppBar(title: const Text('Acerca de la aplicacion')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFFDCEBF7),
                shape: BoxShape.circle,
                border: Border.all(color: _azul, width: 2),
              ),
              child: const Icon(Icons.newspaper, color: _azul, size: 40),
            ),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'Canal Informativo Virtual',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Center(child: Text('Version 1.1.0', style: estiloGris)),
          const SizedBox(height: 24),
          const Text(
            'Aplicacion movil que reune noticias actuales en español, organizadas por '
            'categoria y region, para que el usuario se mantenga informado desde un solo '
            'lugar. Permite buscar noticias, guardar favoritos que se leen sin conexion, '
            'compartirlas y proteger el acceso con un codigo PIN o con la huella digital.',
            style: TextStyle(fontSize: 14.5, height: 1.5),
          ),
          const SizedBox(height: 20),
          _fila(Icons.person_outline, 'Autor', 'Jhoel Percy Gonzales Herrera'),
          _fila(Icons.school_outlined, 'Asignatura', 'Programacion de Dispositivos Moviles II'),
          _fila(Icons.account_balance_outlined, 'Instituto',
              'Instituto Tecnico de Educacion Comercial Americano'),
          _fila(Icons.code, 'Tecnologia', 'Flutter y Dart'),
          _fila(Icons.cloud_outlined, 'Fuente de noticias', 'NewsAPI.org'),
          _fila(Icons.calendar_today_outlined, 'Gestion', '2026'),
        ],
      ),
    );
  }

  Widget _fila(IconData icono, String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, color: _azul, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(valor),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
