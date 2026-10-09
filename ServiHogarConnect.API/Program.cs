using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using ServiHogarConnect.API.Data;
using ServiHogarConnect.API.Jobs;
using ServiHogarConnect.API.Models;
using ServiHogarConnect.API.Services;
using System.Text;

var builder = WebApplication.CreateBuilder(args);

if (builder.Environment.IsDevelopment())
{
    builder.Configuration.AddUserSecrets<Program>(optional: true);
}

var jwtSigningKey = builder.Configuration["Jwt:SigningKey"];
if (string.IsNullOrWhiteSpace(jwtSigningKey) ||
    Encoding.UTF8.GetByteCount(jwtSigningKey) < 32 ||
    jwtSigningKey.Distinct().Count() < 12)
{
    throw new InvalidOperationException(
        $"Jwt:SigningKey is missing or invalid for the {builder.Environment.EnvironmentName} environment. " +
        "In Development, set it with `dotnet user-secrets set \"Jwt:SigningKey\" <key>`.");
}

// ==========================================
// CONTROLADORES
// ==========================================

builder.Services.AddControllers();

// ==========================================
// CONEXIÓN A BASE DE DATOS POSTGRESQL
// ==========================================

builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseNpgsql(
        builder.Configuration.GetConnectionString(
            "DefaultConnection")));

builder.Services.AddScoped<IPasswordHasher<Usuario>, PasswordHasher<Usuario>>();

// ==========================================
// CACHE EN MEMORIA
// ==========================================

builder.Services.AddMemoryCache();

// ==========================================
// COLA DE TRABAJOS Y SERVICIO EN SEGUNDO PLANO
// ==========================================

builder.Services.AddSingleton<ITrabajoQueue, TrabajoQueue>();

builder.Services.AddHostedService<WorkerService>();

// ==========================================
// AUTENTICACIÓN JWT
// ==========================================

builder.Services.AddAuthentication(
    JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters =
            new TokenValidationParameters
            {
                // Verifica que el JWT haya sido firmado
                // con nuestra clave secreta.
                ValidateIssuerSigningKey = true,

                IssuerSigningKey =
                    new SymmetricSecurityKey(
                        Encoding.UTF8.GetBytes(jwtSigningKey)),

                // Actualmente no usamos Issuer.
                ValidateIssuer = false,

                // Actualmente no usamos Audience.
                ValidateAudience = false,

                // IMPORTANTE:
                // El servidor validará estrictamente
                // la fecha de expiración del JWT.
                ValidateLifetime = true,

                // IMPORTANTE PARA LA PRUEBA DE REFRESH TOKEN:
                // No permitir margen adicional después
                // de la fecha de expiración.
                //
                // Sin esta configuración, ASP.NET Core
                // utiliza por defecto un margen de tolerancia
                // que puede hacer que un token aparentemente
                // expirado siga siendo aceptado.
                ClockSkew = TimeSpan.Zero
            };
    });

// ==========================================
// AUTORIZACIÓN
// ==========================================

builder.Services.AddAuthorization();

// ==========================================
// SWAGGER
// CONFIGURACIÓN PARA TOKEN BEARER JWT
// ==========================================

builder.Services.AddEndpointsApiExplorer();

builder.Services.AddSwaggerGen(options =>
{
    options.AddSecurityDefinition(
        "Bearer",
        new OpenApiSecurityScheme
        {
            Name = "Authorization",

            Type = SecuritySchemeType.Http,

            Scheme = "bearer",

            BearerFormat = "JWT",

            In = ParameterLocation.Header,

            Description =
                "Ingrese el token JWT. Ejemplo: Bearer {token}"
        });

    options.AddSecurityRequirement(
        new OpenApiSecurityRequirement
        {
            {
                new OpenApiSecurityScheme
                {
                    Reference =
                        new OpenApiReference
                        {
                            Type =
                                ReferenceType.SecurityScheme,

                            Id = "Bearer"
                        }
                },

                Array.Empty<string>()
            }
        });
});

// ==========================================
// CONSTRUCCIÓN DE LA APLICACIÓN
// ==========================================

var app = builder.Build();

// ==========================================
// SWAGGER
// ==========================================

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();

    app.UseSwaggerUI();
}

// ==========================================
// HTTPS
// ==========================================

app.UseHttpsRedirection();

// ==========================================
// AUTENTICACIÓN
// ==========================================

app.UseAuthentication();

// ==========================================
// AUTORIZACIÓN
// ==========================================

app.UseAuthorization();

// ==========================================
// MAPEO DE CONTROLADORES
// ==========================================

app.MapControllers();

// ==========================================
// EJECUCIÓN DE LA API
// ==========================================

app.Run();