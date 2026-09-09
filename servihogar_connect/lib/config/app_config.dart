/// Configuración pública y general de ServiHogar Connect.
library;

/// ============================================================
/// CONFIGURACIÓN GENERAL DE SERVIHOGAR CONNECT
/// ============================================================
///
/// Este archivo contiene información pública y general
/// de la aplicación.
///
/// Aquí NO deben almacenarse:
/// - contraseñas
/// - tokens
/// - información privada del usuario
/// - credenciales
/// - datos de la base de datos
///
/// La finalidad es centralizar la identidad y configuración
/// pública de la aplicación.
///

class AppConfig {
  AppConfig._();

  static const String appName = 'ServiHogar Connect';

  static const String appShortName = 'ServiHogar';

  static const String appSubtitle =
      'Servicios para tu hogar';

  static const String appSlogan =
      'Tu hogar, nuestros servicios.';

  static const String homeDescription =
      'Encuentra profesionales para tus servicios del hogar.';

  static const String appVersion = '1.0.0';

  static const String environment = 'development';

  static const bool isDevelopment = true;

  static const bool isProduction = false;
}