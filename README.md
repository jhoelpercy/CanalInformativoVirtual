# Canal Informativo Virtual

Aplicación móvil (Flutter) de noticias en español: categorías, regiones, búsqueda, favoritos, lectura sin conexión y acceso con PIN o huella digital.

**Autor:** Jhoel Percy Gonzales Herrera · Programación de Dispositivos Móviles II — ITEC Americano (2026)

## Requisitos
Flutter 3.44.1 (Dart 3.12), Android Studio, Android SDK 36, JDK 17. Android 7.0+ (API 24).

## Puesta en marcha
```bash
flutter pub get
copy lib\config\api_config.example.dart lib\config\api_config.dart   # y escribir su clave de newsapi.org
flutter run                                  # o: flutter run --dart-define=NEWS_API_KEY=su_clave
flutter analyze
flutter test                                 # 29 pruebas
```
Clave gratuita: <https://newsapi.org/register>. `lib/config/api_config.dart` está en `.gitignore`; no la suba.

## Estructura
```
lib/  main.dart · config/ · models/ · services/ · state/ · screens/ · widgets/ · utils/
test/ app_state · news_service · fecha_util · widget
```
Arquitectura por capas: pantallas → `AppState` (ChangeNotifier) → servicios (`NewsService`, `StorageService`, `BiometricService`).

## Documentación completa
Ver las carpetas `1_Documentacion`, `4_Pruebas` y `5_Publicacion` del paquete de entrega (requisitos, especificaciones técnicas, UI/UX, diagramas, manuales, pruebas y guías de publicación).

## Tecnologías
`http`, `shared_preferences`, `local_auth`, `url_launcher`, `share_plus`; API REST NewsAPI.org.
