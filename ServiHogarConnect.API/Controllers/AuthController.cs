using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using ServiHogarConnect.API.Data;
using ServiHogarConnect.API.Models;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;

namespace ServiHogarConnect.API.Controllers;

[ApiController]
[Route("api/auth")]
public class AuthController : ControllerBase
{
    private readonly AppDbContext _context;

    private const string JwtSecret =
        "ServiHogarConnect-Clave-Segura-2026-123456";

    public AuthController(AppDbContext context)
    {
        _context = context;
    }

    [HttpPost("login")]
    public async Task<IActionResult> Login(
        [FromBody] LoginRequest request)
    {
        // Usuario de prueba para demostrar autenticación JWT.
        if (request.Email != "admin@servihogar.com" ||
            request.Password != "123456")
        {
            return Unauthorized(new
            {
                mensaje = "Credenciales incorrectas"
            });
        }

        // Buscamos el usuario real en PostgreSQL
        // para obtener su IdUsuario.
        var usuario = await _context.Usuarios
            .FirstOrDefaultAsync(u => u.Email == request.Email);

        if (usuario == null)
        {
            return Unauthorized(new
            {
                mensaje = "El usuario no existe en la base de datos"
            });
        }

        var claims = new[]
        {
            new Claim(
                ClaimTypes.Name,
                request.Email),

            new Claim(
                ClaimTypes.NameIdentifier,
                usuario.IdUsuario.ToString()),

            new Claim(
                ClaimTypes.Role,
                "Administrador")
        };

        // =====================================================
        // ACCESS TOKEN
        // =====================================================

        var clave = new SymmetricSecurityKey(
            Encoding.UTF8.GetBytes(JwtSecret));

        var credenciales = new SigningCredentials(
            clave,
            SecurityAlgorithms.HmacSha256);

        var token = new JwtSecurityToken(
            claims: claims,
            expires: DateTime.UtcNow.AddHours(1),
            signingCredentials: credenciales);

        var tokenGenerado =
            new JwtSecurityTokenHandler()
                .WriteToken(token);

        // =====================================================
        // REFRESH TOKEN
        // =====================================================

        var refreshToken = GenerarRefreshToken();

        var refreshTokenEntity = new RefreshToken
        {
            Token = refreshToken,
            FechaExpiracion = DateTime.UtcNow.AddDays(7),
            Revocado = false,
            IdUsuario = usuario.IdUsuario
        };

        _context.RefreshTokens.Add(refreshTokenEntity);

        await _context.SaveChangesAsync();

        // =====================================================
        // RESPUESTA
        // =====================================================

        return Ok(new
        {
            mensaje = "Autenticación exitosa",
            token = tokenGenerado,
            tipo = "Bearer",
            usuario = request.Email,
            idUsuario = usuario.IdUsuario,
            refreshToken = refreshToken
        });
    }

    // =========================================================
    // REFRESH TOKEN
    // =========================================================

    [HttpPost("refresh")]
    public async Task<IActionResult> Refresh(
        [FromBody] RefreshTokenRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.RefreshToken))
        {
            return Unauthorized(new
            {
                mensaje = "Refresh token requerido"
            });
        }

        var refreshToken = await _context.RefreshTokens
            .Include(r => r.Usuario)
            .FirstOrDefaultAsync(
                r => r.Token == request.RefreshToken);

        if (refreshToken == null ||
            refreshToken.Revocado ||
            refreshToken.FechaExpiracion <= DateTime.UtcNow)
        {
            return Unauthorized(new
            {
                mensaje = "Refresh token inválido o expirado"
            });
        }

        // =====================================================
        // NUEVO ACCESS TOKEN
        // =====================================================

        var claims = new[]
        {
            new Claim(
                ClaimTypes.Name,
                refreshToken.Usuario.Email),

            new Claim(
                ClaimTypes.NameIdentifier,
                refreshToken.Usuario.IdUsuario.ToString()),

            new Claim(
                ClaimTypes.Role,
                "Administrador")
        };

        var clave = new SymmetricSecurityKey(
            Encoding.UTF8.GetBytes(JwtSecret));

        var credenciales = new SigningCredentials(
            clave,
            SecurityAlgorithms.HmacSha256);

        var token = new JwtSecurityToken(
            claims: claims,
            expires: DateTime.UtcNow.AddSeconds(15),
            signingCredentials: credenciales);

        var nuevoAccessToken =
            new JwtSecurityTokenHandler()
                .WriteToken(token);

        // =====================================================
        // ROTACIÓN DEL REFRESH TOKEN
        // =====================================================

        refreshToken.Revocado = true;

        var nuevoRefreshToken = GenerarRefreshToken();

        var nuevoRefreshTokenEntity = new RefreshToken
        {
            Token = nuevoRefreshToken,
            FechaExpiracion = DateTime.UtcNow.AddDays(7),
            Revocado = false,
            IdUsuario = refreshToken.Usuario.IdUsuario
        };

        _context.RefreshTokens.Add(
            nuevoRefreshTokenEntity);

        await _context.SaveChangesAsync();

        return Ok(new
        {
            token = nuevoAccessToken,
            tipo = "Bearer",
            refreshToken = nuevoRefreshToken
        });
    }

    // =========================================================
    // GENERAR REFRESH TOKEN
    // =========================================================

    private static string GenerarRefreshToken()
    {
        var bytes = RandomNumberGenerator.GetBytes(64);

        return Convert.ToBase64String(bytes);
    }
}

// =============================================================
// LOGIN REQUEST
// =============================================================

public class LoginRequest
{
    public string Email { get; set; } = string.Empty;

    public string Password { get; set; } = string.Empty;
}

// =============================================================
// REFRESH TOKEN REQUEST
// =============================================================

public class RefreshTokenRequest
{
    public string RefreshToken { get; set; } = string.Empty;
}