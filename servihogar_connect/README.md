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

La dirección del backend está centralizada en `lib/config/api_config.dart` y
puede configurarse al ejecutar o compilar la aplicación:

```dart
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:5125',
  );
}
```

Para usar el teléfono físico conectado por USB, crea primero un reenvío de
puerto con Android Debug Bridge. La URL predeterminada de Flutter ya apunta a
la dirección local reenviada:

```powershell
adb reverse tcp:5125 tcp:5125
flutter run
```

El comando `adb reverse` debe repetirse si se desconecta el dispositivo o se
reinicia ADB. En un emulador Android usa `10.0.2.2`:

```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5125
```

Si se usa el teléfono por Wi-Fi en lugar de USB, ambos equipos deben estar en
la misma red y se debe indicar la IPv4 local de la PC:

```powershell
flutter run --dart-define=API_BASE_URL=http://DIRECCION_IPV4_DEL_EQUIPO:5125
```

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
   adb reverse tcp:5125 tcp:5125
   flutter run
```
4. Durante el desarrollo, los cambios se pueden aplicar sin reiniciar la app 
   presionando `r` en la terminal (Hot Reload).

## Endpoints utilizados por la aplicación

| Método | Endpoint | Uso |
|---|---|---|
| GET | `/api/v1/health` | Comprobar disponibilidad de la API |
| GET | `/api/categorias` | Cargar categorías activas del catálogo |
| GET | `/api/Solicitudes` | Consultar solicitudes |
| POST | `/api/Solicitudes` | Crear solicitud con su categoría |

El catálogo se conserva localmente después de una carga exitosa para permitir
seleccionarlo si el dispositivo queda offline. Las solicitudes pendientes
guardan el identificador real de categoría para reutilizarlo durante la
sincronización.

En la aplicación, el flujo principal conecta Inicio con el catálogo de
servicios, el detalle de cada categoría y el formulario de solicitud. Al crear
una solicitud desde ese flujo, se abre automáticamente su seguimiento en
“Mis solicitudes”. El catálogo también está disponible desde la pestaña
“Servicios” y permite buscar categorías.

La navegación inferior conserva Inicio, Solicitudes, Servicios y Perfil como
pestañas; las solicitudes mantienen sus filtros y estado al cambiar de pestaña.
El detalle incluye una pantalla de seguimiento basada en los estados reales de
la API y un centro de ayuda con información del funcionamiento offline. No se
muestran datos ficticios de técnicos, tiempos estimados ni chat en tiempo real.

El cliente también cuenta con una pestaña Actividad con totales por estado,
resumen de servicios en progreso, tendencia semanal de las últimas solicitudes
cargadas y actividad reciente. Si la API no está disponible, el panel usa los
registros locales y las solicitudes pendientes de sincronización.

La pantalla Inicio presenta un resumen de solicitudes, una gráfica semanal de
la muestra cargada, accesos a actividad y solicitudes, categorías del catálogo,
las solicitudes recientes, los pasos para pedir un servicio y las capacidades
de ubicación, fotografía y uso sin conexión. Los datos se obtienen de la API y,
si no está disponible, se muestran los registros de SQLite y la cola local de
sincronización; el resumen identifica cuándo utiliza información local.

Respuesta esperada del health check:

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
├── config/       # Configuración del entorno
├── database/     # Base de datos local y cola offline (Drift)
├── models/       # Modelos de solicitudes y categorías
├── screens/      # Pantallas y flujos de usuario
├── services/     # API, autenticación, catálogo y sincronización
└── widgets/      # Componentes reutilizables


## Limitaciones conocidas

- El tráfico HTTP (no HTTPS) está habilitado únicamente para el entorno de 
  desarrollo local. Antes de una distribución real, debe sustituirse por HTTPS.
- La app fue probada únicamente en Android físico. No se realizaron pruebas en 
  iOS, ya que la compilación para esa plataforma requiere Xcode, disponible 
  solo en macOS.