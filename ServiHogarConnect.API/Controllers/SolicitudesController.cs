using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using ServiHogarConnect.API.Data;
using ServiHogarConnect.API.Models;

namespace ServiHogarConnect.API.Controllers;

[ApiController]
[Authorize]
[Route("api/[controller]")]
public class SolicitudesController : ControllerBase
{
    private readonly AppDbContext _context;

    public SolicitudesController(AppDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<SolicitudServicio>>> ObtenerSolicitudes()
    {
        var consulta = _context.SolicitudesServicio.AsQueryable();
        if (!EsAdministrador())
        {
            if (!ObtenerIdUsuario(out var idUsuario))
            {
                return Unauthorized();
            }

            consulta = consulta.Where(s => s.IdUsuario == idUsuario);
        }

        var solicitudes = await consulta
            .Include(s => s.Usuario)
            .Include(s => s.Categoria)
            .OrderByDescending(s => s.FechaCreacion)
            .ToListAsync();

        return Ok(solicitudes);
    }

    [HttpGet("paginadas")]
    public async Task<IActionResult> ObtenerSolicitudesPaginadas(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        [FromQuery] string? estado = null,
        [FromQuery] int? idCategoria = null)
    {
        if (page < 1)
        {
            return BadRequest(new { mensaje = "El parámetro page debe ser mayor o igual a 1" });
        }

        if (pageSize < 1 || pageSize > 100)
        {
            return BadRequest(new { mensaje = "El parámetro pageSize debe estar entre 1 y 100" });
        }

        var consulta = _context.SolicitudesServicio
            .AsNoTracking()
            .AsQueryable();

        if (!EsAdministrador())
        {
            if (!ObtenerIdUsuario(out var idUsuario))
            {
                return Unauthorized();
            }

            consulta = consulta.Where(s => s.IdUsuario == idUsuario);
        }

        if (!string.IsNullOrWhiteSpace(estado))
        {
            var estadoNormalizado = estado.Trim().ToLowerInvariant();
            var estadosCoincidentes = estadoNormalizado switch
            {
                "pendiente" => new[]
                {
                    "pendiente",
                    "publicada",
                    "asignada"
                },
                "en camino" or "en_camino" =>
                    new[] { "en camino", "en_camino" },
                "en proceso" or "en_proceso" =>
                    new[] { "en proceso", "en_proceso" },
                "completado" or "completada" or "finalizado" or "finalizada" =>
                    new[] { "completado", "completada", "finalizado", "finalizada" },
                _ => new[] { estadoNormalizado }
            };

            consulta = consulta.Where(s =>
                estadosCoincidentes.Contains(s.Estado.ToLower()));
        }

        if (idCategoria.HasValue)
        {
            consulta = consulta.Where(s => s.IdCategoria == idCategoria.Value);
        }

        var totalCount = await consulta.CountAsync();
        var offset = ((long)page - 1) * pageSize;
        var items = await consulta
            .OrderByDescending(s => s.FechaCreacion)
            .ThenByDescending(s => s.IdSolicitud)
            .Skip(offset > int.MaxValue ? int.MaxValue : (int)offset)
            .Take(pageSize)
            .Select(s => new
            {
                s.IdSolicitud,
                s.IdUsuario,
                s.IdCategoria,
                s.ClientOperationId,
                s.Descripcion,
                s.Estado,
                s.FechaCreacion,
                s.Latitud,
                s.Longitud,
                Categoria = new
                {
                    IdCategoria = s.Categoria!.IdCategoria,
                    Nombre = s.Categoria.Nombre
                },
                Usuario = new
                {
                    IdUsuario = s.Usuario!.IdUsuario,
                    Nombre = s.Usuario.Nombre,
                    Apellido = s.Usuario.Apellido
                }
            })
            .ToListAsync();

        return Ok(new
        {
            items,
            page,
            pageSize,
            totalCount,
            totalPages = (int)Math.Ceiling((double)totalCount / pageSize)
        });
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<SolicitudServicio>> ObtenerSolicitud(int id)
    {
        var solicitud = await _context.SolicitudesServicio
            .Include(s => s.Usuario)
            .Include(s => s.Categoria)
            .Include(s => s.Cotizaciones)
            .FirstOrDefaultAsync(s => s.IdSolicitud == id);

        if (solicitud == null)
        {
            return NotFound(new
            {
                mensaje = "Solicitud no encontrada"
            });
        }

        if (!EsAdministrador() &&
            (!ObtenerIdUsuario(out var idUsuario) ||
             solicitud.IdUsuario != idUsuario))
        {
            return Forbid();
        }

        return Ok(solicitud);
    }

    [HttpPost]
    public async Task<ActionResult<SolicitudServicio>> CrearSolicitud(
        SolicitudServicio solicitud)
    {
        if (!ObtenerIdUsuario(out var idUsuario))
        {
            return Unauthorized();
        }

        solicitud.Descripcion = solicitud.Descripcion?.Trim() ?? string.Empty;
        if (solicitud.Descripcion.Length is < 1 or > 2000)
        {
            return BadRequest(new
            {
                mensaje = "La descripción debe tener entre 1 y 2000 caracteres"
            });
        }

        if (solicitud.Latitud is < -90 or > 90 ||
            solicitud.Longitud is < -180 or > 180)
        {
            return BadRequest(new
            {
                mensaje = "Las coordenadas están fuera de rango"
            });
        }

        if (solicitud.ClientOperationId != null)
        {
            solicitud.ClientOperationId = solicitud.ClientOperationId.Trim();
            if (solicitud.ClientOperationId.Length == 0)
            {
                solicitud.ClientOperationId = null;
            }
            else if (solicitud.ClientOperationId.Length > 100)
            {
                return BadRequest(new
                {
                    mensaje = "ClientOperationId no puede superar 100 caracteres"
                });
            }
        }

        var estado = NormalizarEstadoInicial(solicitud.Estado);
        if (estado == null)
        {
            return BadRequest(new
            {
                mensaje = "El estado inicial debe ser publicada o pendiente"
            });
        }

        if (!string.IsNullOrEmpty(solicitud.ClientOperationId))
        {
            var existente = await _context.SolicitudesServicio
                .AsNoTracking()
                .Include(s => s.Cotizaciones)
                .FirstOrDefaultAsync(s =>
                    s.ClientOperationId == solicitud.ClientOperationId);

            if (existente != null)
            {
                if (existente.IdUsuario == idUsuario)
                {
                    return Ok(existente);
                }

                return Conflict(new
                    {
                        mensaje = "ClientOperationId ya está asociado a otra solicitud"
                    });
            }
        }

        var categoriaExiste = await _context.CategoriasServicio
            .AnyAsync(c =>
                c.IdCategoria == solicitud.IdCategoria &&
                c.Activa);

        if (!categoriaExiste)
        {
            return BadRequest(new
            {
                mensaje = "La categoría especificada no existe o está inactiva"
            });
        }

        solicitud.IdUsuario = idUsuario;
        solicitud.IdSolicitud = 0;
        solicitud.FechaCreacion = DateTime.UtcNow;
        solicitud.Estado = estado;
        solicitud.Usuario = null;
        solicitud.Categoria = null;
        solicitud.Cotizaciones = new List<Cotizacion>();

        _context.SolicitudesServicio.Add(solicitud);

        try
        {
            await _context.SaveChangesAsync();
        }
        catch (DbUpdateException)
        {
            _context.Entry(solicitud).State = EntityState.Detached;
            if (!string.IsNullOrEmpty(solicitud.ClientOperationId))
            {
                var existente = await _context.SolicitudesServicio
                    .AsNoTracking()
                    .Include(s => s.Cotizaciones)
                    .FirstOrDefaultAsync(s =>
                        s.ClientOperationId == solicitud.ClientOperationId);
                if (existente != null)
                {
                    if (existente.IdUsuario == idUsuario)
                    {
                        return Ok(existente);
                    }

                    return Conflict(new
                        {
                            mensaje = "ClientOperationId ya está asociado a otra solicitud"
                        });
                }
            }

            throw;
        }

        return CreatedAtAction(
            nameof(ObtenerSolicitud),
            new { id = solicitud.IdSolicitud },
            solicitud);
    }

    private bool EsAdministrador() =>
        User.IsInRole("Administrador");

    private bool ObtenerIdUsuario(out int idUsuario) =>
        int.TryParse(
            User.FindFirstValue(ClaimTypes.NameIdentifier),
            out idUsuario);

    private static string? NormalizarEstadoInicial(string? estado) =>
        estado?.Trim().ToLowerInvariant() switch
        {
            null or "" or "published" or "publicada" or "publicado" =>
                "publicada",
            "pendiente" => "pendiente",
            _ => null
        };
}