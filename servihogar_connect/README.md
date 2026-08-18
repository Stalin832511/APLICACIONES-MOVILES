# ServiHogar Connect — App Móvil (Flutter)

Aplicación móvil multiplataforma del proyecto integrador **ServiHogar Connect**, 
desarrollada con Flutter. Conecta usuarios que requieren servicios del hogar con 
profesionales, consumiendo el backend REST desarrollado en ASP.NET Core.

## Arquitectura de este avance

Flutter (celular Android físico)
│
│ HTTP GET
▼
ASP.NET Core API (PC, puerto 5125)
│
│ EF Core
▼
PostgreSQL (servi_hogar_connect)


## Entorno de desarrollo utilizado

| Herramienta | Versión |
|---|---|
| Flutter | 3.47.0 (channel stable) |
| Dart | 3.13.0 |
| Android SDK | Platform 37 (API 37), Build-Tools 36.0.0 |
| Dispositivo de prueba | TECNO BG7, Android 13 (API 33), físico vía USB |
| Backend | ASP.NET Core (.NET 8), puerto 5125 |
| Base de datos | PostgreSQL |

## Decisión: dispositivo físico en lugar de emulador

Se optó por ejecutar la aplicación en un dispositivo Android físico (TECNO BG7) 
conectado por USB, en lugar de un emulador, debido a las limitaciones de memoria 
RAM del equipo de desarrollo, que no alcanza los requisitos recomendados para 
correr un emulador Android de forma fluida.

## Requisitos previos

- Flutter SDK 3.47.0 o superior — https://docs.flutter.dev/get-started/install
- Android Studio (para el Android SDK y las herramientas de plataforma)
- Un dispositivo Android físico con:
  - Opciones de desarrollador activadas
  - Depuración USB (USB Debugging) activada
  - Conectado a la misma red Wi-Fi que la PC de desarrollo
- Backend ServiHogarConnect.API corriendo (ver sección siguiente)

## Cómo levantar el backend

Dentro de la carpeta `ServiHogarConnect.API`:

```powershell
dotnet run
```

El backend está configurado para escuchar en `0.0.0.0:5125` (todas las interfaces 
de red), no solo en `localhost`, ya que un dispositivo físico externo (el celular) 
no puede alcanzar `localhost` de la PC — ese término, desde el celular, se refiere 
al propio celular. Esta configuración se definió en 
`Properties/launchSettings.json`, perfil `http`:

```json
"applicationUrl": "http://0.0.0.0:5125"
```

## Configuración de la URL del backend en Flutter

La dirección del backend está centralizada en `lib/config/api_config.dart`, 
en lugar de repetirse por todo el código, para facilitar el cambio entre entornos:

```dart
class ApiConfig {
  static const String baseUrl = 'http://192.168.100.104:5125';
}
```

**Importante:** esta IP corresponde a la dirección local de la PC de desarrollo 
dentro de la red utilizada durante las pruebas. Si se ejecuta en otra red, debe 
obtenerse la IP actual con `ipconfig` (Windows) y actualizarse en este archivo.

## Cómo ejecutar la app móvil

1. Conectar el dispositivo Android por USB y verificar que aparece detectado:
```powershell
   flutter devices
```
2. Dentro de la carpeta `servihogar_connect`, instalar dependencias:
```powershell
   flutter pub get
```
3. Ejecutar la app en el dispositivo conectado:
```powershell
   flutter run
```
4. Durante el desarrollo, los cambios se pueden aplicar sin reiniciar la app 
   presionando `r` en la terminal (Hot Reload).

## Endpoint consumido en este avance

GET /api/v1/health


Respuesta esperada:

```json
{
  "success": true,
  "message": "API ServiHogar Connect funcionando correctamente",
  "project": "ServiHogar Connect",
  "version": "v1"
}
```

## Estructura del proyecto Flutter

lib/
├── main.dart # Punto de entrada y pantalla principal
├── config/
│ └── api_config.dart # URL base del backend, centralizada
└── services/
└── api_service.dart # Lógica de conexión HTTP con la API


## Limitaciones conocidas

- El tráfico HTTP (no HTTPS) está habilitado únicamente para el entorno de 
  desarrollo local. Antes de una distribución real, debe sustituirse por HTTPS.
- La app fue probada únicamente en Android físico. No se realizaron pruebas en 
  iOS, ya que la compilación para esa plataforma requiere Xcode, disponible 
  solo en macOS.