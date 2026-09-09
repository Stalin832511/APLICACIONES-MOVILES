using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using ServiHogarConnect.API.Data;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

namespace ServiHogarConnect.API.Controllers;

[ApiController]
[Route("api/auth")]
public class AuthController : ControllerBase
{
    private readonly AppDbContext _context;

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

        var clave = new SymmetricSecurityKey(
            Encoding.UTF8.GetBytes(
                "ServiHogarConnect-Clave-Segura-2026-123456"));

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

        return Ok(new
        {
            mensaje = "Autenticación exitosa",
            token = tokenGenerado,
            tipo = "Bearer",
            usuario = request.Email,
            idUsuario = usuario.IdUsuario
        });
    }
}

public class LoginRequest
{
    public string Email { get; set; } = string.Empty;

    public string Password { get; set; } = string.Empty;
}