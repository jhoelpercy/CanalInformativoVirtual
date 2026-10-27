// Autor: Jhoel Percy Gonzales Herrera
// Funcion: chip de categoria reutilizable.
import 'package:flutter/material.dart';
import '../models/noticia.dart';

/// Chip seleccionable usado para filtrar noticias por categoria
/// en la pantalla de Inicio.
class CategoryChip extends StatelessWidget {
  final Categoria categoria;
  final bool activo;
  final VoidCallback onTap;

  const CategoryChip({
    super.key,
    required this.categoria,
    required this.activo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(categoria.nombre),
        selected: activo,
        onSelected: (_) => onTap(),
        selectedColor: const Color(0xFF1F6FB2),
        labelStyle: TextStyle(
          color: activo ? Colors.white : Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        side: BorderSide(color: activo ? const Color(0xFF1F6FB2) : Colors.grey.shade400),
      ),
    );
  }
}
