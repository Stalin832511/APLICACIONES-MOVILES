using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using ServiHogarConnect.API.Data;
using ServiHogarConnect.API.Jobs;
using ServiHogarConnect.API.Services;
using System.Text;

var builder = WebApplication.CreateBuilder(args);

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
                        Encoding.UTF8.GetBytes(
                            "ServiHogarConnect-Clave-Segura-2026-123456")),

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