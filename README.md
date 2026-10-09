# ServiHogar Connect

Aplicación móvil Flutter para solicitar servicios del hogar, con una API REST
ASP.NET Core y PostgreSQL. El cliente incluye almacenamiento local y una cola de
sincronización para solicitudes creadas sin conexión.

## Componentes

- `servihogar_connect/`: aplicación Flutter para Android y otras plataformas.
- `ServiHogarConnect.API/`: API ASP.NET Core 8 y acceso a PostgreSQL mediante
  Entity Framework Core.
- `ServiHogarConnect.sln`: solución del backend.

## Requisitos

- Flutter y Dart compatibles con `servihogar_connect/pubspec.yaml`.
- .NET SDK 8.
- PostgreSQL.
- Para probar en un teléfono Android: depuración USB habilitada y el teléfono y
  el equipo de desarrollo conectados a la misma red.

## Preparar el backend

Desde la raíz del proyecto, configura la cadena de conexión en la terminal
actual (no guardes credenciales en Git):

```powershell
$env:ConnectionStrings__DefaultConnection = "Host=localhost;Port=5432;Database=servi_hogar_connect;Username=TU_USUARIO;Password=TU_PASSWORD"
```

La API también requiere una clave de firma JWT para desarrollo. Genera una
clave aleatoria y guárdala en User Secrets (no en `appsettings.json`):

```powershell
$rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
$bytes = New-Object byte[] 48
$rng.GetBytes($bytes)
$key = [Convert]::ToBase64String($bytes)
$rng.Dispose()
dotnet user-secrets set "Jwt:SigningKey" $key --project .\ServiHogarConnect.API
```

La clave se guarda localmente para el usuario de Windows y se conserva entre
ejecuciones. User Secrets es solo para desarrollo; configura la clave mediante
un almacén de secretos seguro en otros entornos.

Aplica las migraciones y ejecuta la API:

```powershell
# Ejecutar una vez si la herramienta EF Core no está instalada:
dotnet tool install --global dotnet-ef --version 8.0.29

cd .\ServiHogarConnect.API
dotnet ef database update
dotnet run --launch-profile http
```

La migración del catálogo crea las diez categorías iniciales sin duplicar las
que ya existan y las marca como activas. La API de desarrollo escucha en
`http://0.0.0.0:5125`; Swagger está disponible en
`http://localhost:5125/swagger`.

## Preparar y ejecutar Flutter

Desde la raíz:

```powershell
cd .\servihogar_connect
flutter pub get
flutter analyze
flutter test
```

Para el emulador Android, la dirección por defecto es `http://10.0.2.2:5125`.
Para un teléfono físico, usa la dirección IPv4 local del equipo que ejecuta la
API:

```powershell
flutter run --dart-define=API_BASE_URL=http://DIRECCION_IPV4_DEL_EQUIPO:5125
```

El catálogo se obtiene desde `GET /api/categorias` y se conserva en el
almacenamiento local de la aplicación para permitir crear solicitudes offline
con los identificadores reales de las categorías. Las categorías desactivadas
no se ofrecen en el catálogo ni se aceptan al crear solicitudes.

## Flujo de trabajo sugerido

1. Inicia PostgreSQL y configura `ConnectionStrings__DefaultConnection`.
2. Ejecuta las migraciones y levanta la API.
3. Comprueba el health check en `GET /api/v1/health` y el catálogo en
   `GET /api/categorias`.
4. Ejecuta Flutter en un emulador o dispositivo con `API_BASE_URL` configurado.
5. Antes de enviar cambios, ejecuta `flutter analyze`, `flutter test` y
   `dotnet build`.

## Estado y siguientes bloques

### Terminado en esta iteración

- Catálogo de diez servicios con migración que evita duplicados existentes.
- Consulta API de categorías activas y rechazo de categorías inactivas al crear
  una solicitud.
- Selector dinámico en Flutter y caché local para crear solicitudes offline
  usando el ID de categoría real.
- URL de API configurable con `API_BASE_URL` y guía de ejecución en ambas
  carpetas del proyecto.

### Siguientes bloques, en orden recomendado

1. **Seguridad del backend (bloqueante antes de publicar):** sustituir el login
   de demostración y la clave JWT codificada por autenticación real y secretos
   externos; proteger solicitudes y restringir datos al usuario autenticado.
2. **Ciclo de vida de solicitudes:** historial de estados, transiciones válidas,
   filtros y paginación en API y móvil.
3. **Evidencias:** carga remota de fotografías y consulta desde otros
   dispositivos; actualmente la imagen capturada no se envía al servidor.
4. **Validación de entrega:** pruebas automatizadas e integración, mediciones de
   rendimiento, documentación Swagger verificada y compilación APK de entrega.
