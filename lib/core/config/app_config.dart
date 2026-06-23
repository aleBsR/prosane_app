class AppConfig {
  /// Inyectar con --dart-define=API_BASE_URL=...
  // OJO: la IP es la de tu Mac en la WiFi actual (cambia al cambiar de red).
  //   Mac/iOS simulator → http://127.0.0.1:8000/api/v1/auth
  //   Emulador Android  → http://10.0.2.2:8000/api/v1/auth
  //   Celular físico    → http://<IP-LAN-de-tu-Mac>:8000/api/v1/auth
  // Mejor aún: inyectar al correr →
  //   flutter run --dart-define=API_BASE_URL=http://10.120.174.47:8000/api/v1/auth
  static const apiBaseUrl =
    String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.26.3.142:8000/api/v1/auth');

  /// Base para rutas fuera de /auth (tutores, hijos, etc.).
  /// Quita el sufijo `/auth` de [apiBaseUrl] para quedar en `.../api/v1`.
  static String get apiV1Base {
    const url = apiBaseUrl;
    if (url.endsWith('/auth')) return url.substring(0, url.length - '/auth'.length);
    return url;
  }
}
