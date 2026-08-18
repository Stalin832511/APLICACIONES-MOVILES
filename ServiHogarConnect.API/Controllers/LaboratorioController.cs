using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;
using ServiHogarConnect.API.Data;
using ServiHogarConnect.API.Services;
using System.Diagnostics;

namespace ServiHogarConnect.API.Controllers;

[ApiController]
[Route("api/laboratorio")]
public class LaboratorioController : ControllerBase
{
    private readonly AppDbContext _context;
    private readonly IMemoryCache _cache;
    private readonly ITrabajoQueue _cola;

    public LaboratorioController(
        AppDbContext context,
        IMemoryCache cache,
        ITrabajoQueue cola)
    {
        _context = context;
        _cache = cache;
        _cola = cola;
    }

    // ==========================================
    // 1. CONSULTA N+1 SIMULADA
    // ==========================================

    [HttpGet("n-plus-one")]
    public async Task<IActionResult> ConsultaNPlusOne()
    {
        var cronometro = Stopwatch.StartNew();

        var solicitudes = await _context.SolicitudesServicio
            .AsNoTracking()
            .ToListAsync();

        var resultado = new List<object>();

        foreach (var solicitud in solicitudes)
        {
            var usuario = await _context.Usuarios
                .AsNoTracking()
                .FirstOrDefaultAsync(
                    u => u.IdUsuario == solicitud.IdUsuario);

            var categoria = await _context.CategoriasServicio
                .AsNoTracking()
                .FirstOrDefaultAsync(
                    c => c.IdCategoria == solicitud.IdCategoria);

            resultado.Add(new
            {
                solicitud.IdSolicitud,
                solicitud.Descripcion,
                Usuario = usuario?.Nombre,
                Categoria = categoria?.Nombre
            });
        }

        cronometro.Stop();

        return Ok(new
        {
            estrategia = "N+1",
            consultas = "1 + N + N",
            tiempoMilisegundos = cronometro.ElapsedMilliseconds,
            resultados = resultado
        });
    }

    // ==========================================
    // 2. CONSULTA OPTIMIZADA
    // ==========================================

    [HttpGet("optimizada")]
    public async Task<IActionResult> ConsultaOptimizada()
    {
        var cronometro = Stopwatch.StartNew();

        var resultado = await _context.SolicitudesServicio
            .AsNoTracking()
            .Include(s => s.Usuario)
            .Include(s => s.Categoria)
            .Select(s => new
            {
                s.IdSolicitud,
                s.Descripcion,
                Usuario = s.Usuario.Nombre,
                Categoria = s.Categoria.Nombre,
                s.Estado
            })
            .ToListAsync();

        cronometro.Stop();

        return Ok(new
        {
            estrategia = "Eager Loading + Proyección",
            consultas = "Consulta optimizada",
            tiempoMilisegundos = cronometro.ElapsedMilliseconds,
            resultados = resultado
        });
    }

    // ==========================================
    // 3. CACHE-ASIDE
    // ==========================================

    [HttpGet("cache")]
    public async Task<IActionResult> ObtenerConCache()
    {
        const string clave = "solicitudes-cache";

        if (_cache.TryGetValue(clave, out object? datos))
        {
            return Ok(new
            {
                origen = "CACHE",
                mensaje = "Datos obtenidos desde memoria",
                datos
            });
        }

        var solicitudes = await _context.SolicitudesServicio
            .AsNoTracking()
            .Include(s => s.Usuario)
            .Include(s => s.Categoria)
            .Select(s => new
            {
                s.IdSolicitud,
                s.Descripcion,
                Usuario = s.Usuario.Nombre,
                Categoria = s.Categoria.Nombre,
                s.Estado
            })
            .ToListAsync();

        var opciones = new MemoryCacheEntryOptions
        {
            AbsoluteExpirationRelativeToNow =
                TimeSpan.FromMinutes(5)
        };

        _cache.Set(clave, solicitudes, opciones);

        return Ok(new
        {
            origen = "BASE DE DATOS",
            mensaje = "Datos consultados y guardados en caché",
            datos = solicitudes
        });
    }

    // ==========================================
    // 4. INVALIDACIÓN EXPLÍCITA DEL CACHÉ
    // ==========================================

    [HttpDelete("cache")]
    public IActionResult InvalidarCache()
    {
        _cache.Remove("solicitudes-cache");

        return Ok(new
        {
            mensaje = "Caché invalidada correctamente"
        });
    }

    // ==========================================
    // 5. COLA DE TRABAJO ASÍNCRONA
    // ==========================================

    [HttpPost("trabajo-asincrono")]
    public async Task<IActionResult> CrearTrabajoAsincrono()
    {
        await _cola.EnqueueAsync(async cancellationToken =>
        {
            await Task.Delay(3000, cancellationToken);
        });

        return Accepted(new
        {
            estado = "Encolado",
            mensaje =
                "El trabajo fue enviado a la cola y se procesará en segundo plano"
        });
    }

    // ==========================================
    // 6. RUTA PROTEGIDA
    // ==========================================

    [Authorize]
    [HttpGet("protegido")]
    public IActionResult RutaProtegida()
    {
        return Ok(new
        {
            mensaje = "Acceso autorizado mediante JWT",
            usuario = User.Identity?.Name
        });
    }
}
