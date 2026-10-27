// Autor: Jhoel Percy Gonzales Herrera
// Funcion: pantalla de listado de categorias.
import 'package:flutter/material.dart';
import '../models/noticia.dart';

/// Pantalla de Categorias: listado completo de categorias disponibles.
/// Al seleccionar una, se aplica como filtro en la pantalla de Inicio.
class CategoriesScreen extends StatelessWidget {
  final void Function(Categoria) onCategoriaSeleccionada;

  const CategoriesScreen({super.key, required this.onCategoriaSeleccionada});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categorias')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: Categoria.lista.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final categoria = Categoria.lista[index];
          return InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              onCategoriaSeleccionada(categoria);
              Navigator.of(context).pop();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: categoria.color),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  CircleAvatar(radius: 10, backgroundColor: categoria.color),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(categoria.nombre,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
