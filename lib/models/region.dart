// Autor: Jhoel Percy Gonzales Herrera
// Funcion: modelo Region (Bolivia, Latinoamerica, España, Mundo) para filtrar noticias.
/// Region de interes para las noticias. NewsAPI.org no entrega
/// titulares (top-headlines) de paises hispanohablantes en el plan
/// gratuito, por eso la app consulta articulos en español (language=es)
/// filtrados por palabras clave de cada region.
class Region {
  final String id;
  final String nombre;

  /// Expresion de busqueda (sintaxis de NewsAPI) que se combina con
  /// la de la categoria elegida.
  final String consulta;

  const Region({required this.id, required this.nombre, required this.consulta});

  static const bolivia = Region(id: 'bo', nombre: 'Bolivia', consulta: 'Bolivia');
  static const latinoamerica = Region(
    id: 'latam',
    nombre: 'Latinoamerica',
    consulta: '(Latinoamerica OR Mexico OR Colombia OR Argentina OR Peru OR Chile)',
  );
  static const espana = Region(id: 'es', nombre: 'España', consulta: 'España');
  static const mundo = Region(
    id: 'mundo',
    nombre: 'Mundo',
    consulta: '(mundo OR internacional OR global)',
  );

  static const List<Region> lista = [bolivia, latinoamerica, espana, mundo];

  static Region porId(String id) =>
      lista.firstWhere((r) => r.id == id, orElse: () => bolivia);
}
