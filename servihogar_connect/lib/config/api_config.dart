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
  /// Para utilizar la aplicación desde un teléfono físico,
  /// la computadora y el teléfono deben estar conectados
  /// a la misma red local.
  static const String baseUrl =
      'http://192.168.100.104:5125';
}