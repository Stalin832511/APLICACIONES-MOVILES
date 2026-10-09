using System.ComponentModel.DataAnnotations;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using ServiHogarConnect.API.Data;
using ServiHogarConnect.API.Models;

namespace ServiHogarConnect.API.Controllers;

[ApiController]
[Route("api/auth")]
public class AuthController : ControllerBase
{
    private readonly AppDbContext _context;
    private readonly IPasswordHasher<Usuario> _passwordHasher;
    private readonly byte[] _jwtSigningKey;

    public AuthController(
        AppDbContext context,
        IPasswordHasher<Usuario> passwordHasher,
        IConfiguration configuration)
    {
        _context = context;
        _passwordHasher = passwordHasher;
        _jwtSigningKey = Encoding.UTF8.GetBytes(
            configuration["Jwt:SigningKey"]!);
    }

    [HttpPost("register")]
    public async Task<IActionResult> Register(
        [FromBody] RegisterRequest request)
    {
        var email = request.Email.Trim().ToLowerInvariant();
        if (await _context.Usuarios.AnyAsync(
                u => u.Email.ToLower() == email))
        {
            return Conflict(new { mensaje = "El correo ya está registrado" });
        }

        var usuario = new Usuario
        {
            Nombre = request.Nombre.Trim(),
            Apellido = request.Apellido.Trim(),
            Email = email,
            Telefono = string.IsNullOrWhiteSpace(request.Telefono)
                ? null
                : request.Telefono.Trim(),
            TipoUsuario = "cliente"
        };
        usuario.PasswordHash = _passwordHasher.HashPassword(
            usuario,
            request.Password);

        _context.Usuarios.Add(usuario);
        try
        {
            await _context.SaveChangesAsync();
        }
        catch (DbUpdateException)
        {
            if (await _context.Usuarios.AnyAsync(
                    u => u.Email.ToLower() == email))
            {
                return Conflict(new { mensaje = "El correo ya está registrado" });
            }

            throw;
        }

        var accessToken = CrearAccessToken(usuario);
        var refreshToken = GenerarRefreshToken();
        _context.RefreshTokens.Add(new RefreshToken
        {
            Token = refreshToken,
            FechaExpiracion = DateTime.UtcNow.AddDays(7),
            Revocado = false,
            IdUsuario = usuario.IdUsuario
        });
        await _context.SaveChangesAsync();

        return StatusCode(
            StatusCodes.Status201Created,
            new
            {
                mensaje = "Cuenta creada correctamente",
                token = accessToken,
                tipo = "Bearer",
                usuario = usuario.Email,
                idUsuario = usuario.IdUsuario,
                rol = ObtenerRol(usuario.TipoUsuario),
                refreshToken
            });
    }

    [HttpPost("login")]
    public async Task<IActionResult> Login(
        [FromBody] LoginRequest request)
    {
        var email = request.Email.Trim().ToLowerInvariant();
        var usuario = await _context.Usuarios
            .FirstOrDefaultAsync(u => u.Email.ToLower() == email);

        if (usuario == null)
        {
            return Unauthorized(new { mensaje = "Credenciales incorrectas" });
        }

        var verificationResult = _passwordHasher.VerifyHashedPassword(
            usuario,
            usuario.PasswordHash,
            request.Password);
        if (verificationResult == PasswordVerificationResult.Failed)
        {
            return Unauthorized(new { mensaje = "Credenciales incorrectas" });
        }

        if (verificationResult == PasswordVerificationResult.SuccessRehashNeeded)
        {
            usuario.PasswordHash = _passwordHasher.HashPassword(
                usuario,
                request.Password);
        }

        var accessToken = CrearAccessToken(usuario);
        var refreshToken = GenerarRefreshToken();
        _context.RefreshTokens.Add(new RefreshToken
        {
            Token = refreshToken,
            FechaExpiracion = DateTime.UtcNow.AddDays(7),
            Revocado = false,
            IdUsuario = usuario.IdUsuario
        });
        await _context.SaveChangesAsync();

        return Ok(new
        {
            mensaje = "Autenticación exitosa",
            token = accessToken,
            tipo = "Bearer",
            usuario = usuario.Email,
            idUsuario = usuario.IdUsuario,
            rol = ObtenerRol(usuario.TipoUsuario),
            refreshToken
        });
    }

    [HttpPost("refresh")]
    public async Task<IActionResult> Refresh(
        [FromBody] RefreshTokenRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.RefreshToken))
        {
            return Unauthorized(new { mensaje = "Refresh token requerido" });
        }

        var refreshToken = await _context.RefreshTokens
            .Include(r => r.Usuario)
            .FirstOrDefaultAsync(r => r.Token == request.RefreshToken);

        if (refreshToken == null ||
            refreshToken.Revocado ||
            refreshToken.FechaExpiracion <= DateTime.UtcNow)
        {
            return Unauthorized(new
            {
                mensaje = "Refresh token inválido o expirado"
            });
        }

        refreshToken.Revocado = true;
        var nuevoRefreshToken = GenerarRefreshToken();
        _context.RefreshTokens.Add(new RefreshToken
        {
            Token = nuevoRefreshToken,
            FechaExpiracion = DateTime.UtcNow.AddDays(7),
            Revocado = false,
            IdUsuario = refreshToken.Usuario.IdUsuario
        });

        await _context.SaveChangesAsync();

        return Ok(new
        {
            token = CrearAccessToken(refreshToken.Usuario),
            tipo = "Bearer",
            refreshToken = nuevoRefreshToken
        });
    }

    private string CrearAccessToken(Usuario usuario)
    {
        var claims = new[]
        {
            new Claim(ClaimTypes.Name, usuario.Email),
            new Claim(
                ClaimTypes.NameIdentifier,
                usuario.IdUsuario.ToString()),
            new Claim(ClaimTypes.Role, ObtenerRol(usuario.TipoUsuario))
        };
        var credentials = new SigningCredentials(
            new SymmetricSecurityKey(_jwtSigningKey),
            SecurityAlgorithms.HmacSha256);
        var token = new JwtSecurityToken(
            claims: claims,
            expires: DateTime.UtcNow.AddHours(1),
            signingCredentials: credentials);

        return new JwtSecurityTokenHandler().WriteToken(token);
    }

    private static string ObtenerRol(string tipoUsuario) =>
        tipoUsuario.Trim().ToLowerInvariant() switch
        {
            "admin" or "administrador" => "Administrador",
            "profesional" => "Profesional",
            _ => "Cliente"
        };

    private static string GenerarRefreshToken() =>
        Convert.ToBase64String(RandomNumberGenerator.GetBytes(64));
}

public class LoginRequest
{
    [Required]
    [EmailAddress]
    [StringLength(150)]
    public string Email { get; set; } = string.Empty;

    [Required]
    [StringLength(128, MinimumLength = 1)]
    public string Password { get; set; } = string.Empty;
}

public class RegisterRequest
{
    [Required]
    [StringLength(100, MinimumLength = 1)]
    public string Nombre { get; set; } = string.Empty;

    [Required]
    [StringLength(100, MinimumLength = 1)]
    public string Apellido { get; set; } = string.Empty;

    [Required]
    [EmailAddress]
    [StringLength(150)]
    public string Email { get; set; } = string.Empty;

    [Required]
    [StringLength(128, MinimumLength = 8)]
    public string Password { get; set; } = string.Empty;

    [StringLength(30)]
    public string? Telefono { get; set; }
}

public class RefreshTokenRequest
{
    [Required]
    public string RefreshToken { get; set; } = string.Empty;
}
