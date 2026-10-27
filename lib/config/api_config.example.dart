// Autor: Jhoel Percy Gonzales Herrera
// Funcion: plantilla de la configuracion privada de la API.
/// Plantilla de la configuracion privada. Copiar este contenido a
/// lib/config/api_config.dart y escribir la clave personal obtenida
/// gratis en https://newsapi.org/register
class ApiConfig {
  static const String newsApiKey = String.fromEnvironment(
    'NEWS_API_KEY',
    defaultValue: 'TU_API_KEY_AQUI',
  );
}
