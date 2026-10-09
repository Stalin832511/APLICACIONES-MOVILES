/// Configuración pública de conexión con la API de ServiHogar Connect.
library;

/// ============================================================
/// CONFIGURACIÓN DE LA API DE SERVIHOGAR CONNECT
/// ============================================================
///
/// Este archivo contiene únicamente la configuración pública
/// necesaria para establecer comunicación con el backend.
///
/// NO almacenar aquí:
/// - contraseñas
/// - tokens
/// - credenciales
/// - claves privadas
/// - datos de PostgreSQL
///
/// La API utiliza ASP.NET Core y PostgreSQL en el servidor.
/// La aplicación Flutter utiliza esta URL para comunicarse
/// con el backend.
///

class ApiConfig {
  ApiConfig._();

  /// URL base del backend ASP.NET Core.
  ///
  /// Esta dirección corresponde a la computadora donde
  /// se ejecuta actualmente la API de ServiHogar Connect.
  ///
  /// El valor predeterminado funciona con un teléfono Android
  /// conectado por USB y `adb reverse tcp:5125 tcp:5125`.
  /// Los emuladores Android deben sobrescribirlo con 10.0.2.2.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:5125',
  );
}