using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ServiHogarConnect.API.Data;
using ServiHogarConnect.API.Models;

namespace ServiHogarConnect.API.Controllers;

[ApiController]
[Authorize]
[Route("api/marketplace")]
public class MarketplaceController : ControllerBase
{
    private const string RolProfesional = "Profesional";
    private const string RolAdministrador = "Administrador";
    private readonly AppDbContext _context;

    public MarketplaceController(AppDbContext context)
    {
        _context = context;
    }

    [HttpGet("professional/requests")]
    public async Task<IActionResult> ObtenerSolicitudesDisponibles(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        CancellationToken cancellationToken = default)
    {
        if (!EsProfesional() && !EsAdministrador())
        {
            return Forbid();
        }

        if (page < 1)
        {
            return BadRequest(new { mensaje = "El parámetro page debe ser mayor o igual a 1" });
        }

        if (pageSize is < 1 or > 100)
        {
            return BadRequest(new { mensaje = "El parámetro pageSize debe estar entre 1 y 100" });
        }

        var idProfesionalAutenticado = await ObtenerIdProfesionalAsync(cancellationToken);
        if (EsProfesional() && !idProfesionalAutenticado.HasValue)
        {
            return Forbid();
        }

        var consulta = _context.SolicitudesServicio
            .AsNoTracking()
            .Where(s =>
                (s.Estado.ToLower() == "publicada" ||
                 s.Estado.ToLower() == "pendiente") &&
                !s.Cotizaciones.Any(c => c.Estado.ToLower() == "aceptada"));

        var totalCount = await consulta.CountAsync(cancellationToken);
        var offset = ((long)page - 1) * pageSize;
        var solicitudes = await consulta
            .OrderByDescending(s => s.FechaCreacion)
            .ThenByDescending(s => s.IdSolicitud)
            .Skip(offset > int.MaxValue ? int.MaxValue : (int)offset)
            .Take(pageSize)
            .Select(s => new
            {
                s.IdSolicitud,
                s.IdCategoria,
                Categoria = new { s.Categoria!.Nombre },
                s.Descripcion,
                s.FechaCreacion,
                s.Latitud,
                s.Longitud
            })
            .ToListAsync(cancellationToken);

        return Ok(new
        {
            items = solicitudes,
            page,
            pageSize,
            totalCount,
            totalPages = (int)Math.Ceiling((double)totalCount / pageSize)
        });
    }

    [HttpGet("professional/assigned")]
    public async Task<IActionResult> ObtenerTrabajosAsignados(
        CancellationToken cancellationToken = default)
    {
        if (!EsProfesional() && !EsAdministrador())
        {
            return Forbid();
        }

        var idProfesional = await ObtenerIdProfesionalAsync(cancellationToken);
        if (EsProfesional() && !idProfesional.HasValue)
        {
            return Forbid();
        }

        var cotizaciones = _context.Cotizaciones
            .AsNoTracking()
            .Where(c =>
                c.Estado.ToLower() == "aceptada" &&
                (c.Solicitud.Estado.ToLower() == "asignada" ||
                 c.Solicitud.Estado.ToLower() == "en proceso" ||
                 c.Solicitud.Estado.ToLower() == "completada"));

        if (EsProfesional())
        {
            cotizaciones = cotizaciones.Where(c => c.IdProfesional == idProfesional!.Value);
        }

        var trabajos = await cotizaciones
            .OrderByDescending(c => c.Solicitud.FechaCreacion)
            .ThenByDescending(c => c.IdCotizacion)
            .Select(c => new
            {
                c.Solicitud.IdSolicitud,
                c.IdCotizacion,
                Estado = c.Solicitud.Estado,
                c.Solicitud.Descripcion,
                c.Solicitud.FechaCreacion,
                Categoria = new { Nombre = c.Solicitud.Categoria!.Nombre },
                c.PrecioOfertado,
                c.TiempoEstimado
            })
            .ToListAsync(cancellationToken);

        return Ok(trabajos);
    }

    [HttpPost("requests/{id:int}/quotes")]
    public async Task<IActionResult> CrearCotizacion(
        int id,
        [FromBody] CrearCotizacionRequest? request,
        CancellationToken cancellationToken = default)
    {
        if (!EsProfesional() && !EsAdministrador())
        {
            return Forbid();
        }

        if (request == null)
        {
            return BadRequest(new { mensaje = "Se requiere el cuerpo de la cotización" });
        }

        if (request.PrecioOfertado <= 0 || request.PrecioOfertado > 100_000_000m)
        {
            return BadRequest(new
            {
                mensaje = "El precioOfertado debe ser mayor que 0 y no superar 100000000"
            });
        }

        if (request.TiempoEstimado?.Length > 120)
        {
            return BadRequest(new { mensaje = "El tiempoEstimado no puede superar 120 caracteres" });
        }

        var perfilPropio = await ObtenerIdProfesionalAsync(cancellationToken);
        if (EsProfesional() && !perfilPropio.HasValue)
        {
            return Forbid();
        }

        var idProfesional = EsAdministrador() && request.IdProfesional.HasValue
            ? request.IdProfesional
            : perfilPropio;
        if (!idProfesional.HasValue)
        {
            return BadRequest(new
            {
                mensaje = "El administrador debe indicar un idProfesional existente para asociar la cotización"
            });
        }

        if (!await _context.Profesionales.AnyAsync(
                p => p.IdProfesional == idProfesional.Value,
                cancellationToken))
        {
            return BadRequest(new { mensaje = "El profesional especificado no existe" });
        }

        var solicitud = await _context.SolicitudesServicio
            .AsNoTracking()
            .Where(s => s.IdSolicitud == id)
            .Select(s => new { s.IdSolicitud, s.Estado })
            .SingleOrDefaultAsync(cancellationToken);

        if (solicitud == null)
        {
            return NotFound(new { mensaje = "Solicitud no encontrada" });
        }

        if (!EsSolicitudAbierta(solicitud.Estado) ||
            await _context.Cotizaciones.AnyAsync(
                c => c.IdSolicitud == id && c.Estado.ToLower() == "aceptada",
                cancellationToken))
        {
            return Conflict(new { mensaje = "La solicitud ya no está abierta para recibir cotizaciones" });
        }

        if (await _context.Cotizaciones.AnyAsync(
                c => c.IdSolicitud == id && c.IdProfesional == idProfesional.Value,
                cancellationToken))
        {
            return Conflict(new { mensaje = "Ya existe una cotización de este profesional para la solicitud" });
        }

        var cotizacion = new Cotizacion
        {
            IdSolicitud = id,
            IdProfesional = idProfesional.Value,
            PrecioOfertado = request.PrecioOfertado,
            TiempoEstimado = string.IsNullOrWhiteSpace(request.TiempoEstimado)
                ? null
                : request.TiempoEstimado.Trim(),
            Estado = "enviada"
        };

        _context.Cotizaciones.Add(cotizacion);
        await _context.SaveChangesAsync(cancellationToken);

        return StatusCode(StatusCodes.Status201Created, new
        {
            cotizacion.IdCotizacion,
            cotizacion.IdSolicitud,
            cotizacion.IdProfesional,
            cotizacion.PrecioOfertado,
            cotizacion.TiempoEstimado,
            cotizacion.Estado
        });
    }

    [HttpGet("requests/{id:int}/quotes")]
    public async Task<IActionResult> ObtenerCotizaciones(
        int id,
        CancellationToken cancellationToken = default)
    {
        if (!EsAdministrador() && !TryObtenerIdUsuario(out _))
        {
            return Unauthorized(new { mensaje = "El token no contiene un identificador de usuario válido" });
        }

        var solicitud = await _context.SolicitudesServicio
            .AsNoTracking()
            .Where(s => s.IdSolicitud == id)
            .Select(s => new { s.IdSolicitud, s.IdUsuario, s.Estado })
            .SingleOrDefaultAsync(cancellationToken);

        if (solicitud == null)
        {
            return NotFound(new { mensaje = "Solicitud no encontrada" });
        }

        if (!EsAdministrador() &&
            (!TryObtenerIdUsuario(out var idUsuario) || solicitud.IdUsuario != idUsuario))
        {
            return Forbid();
        }

        var cotizaciones = await _context.Cotizaciones
            .AsNoTracking()
            .Where(c => c.IdSolicitud == id)
            .OrderBy(c => c.IdCotizacion)
            .Select(c => new
            {
                c.IdCotizacion,
                c.IdSolicitud,
                c.IdProfesional,
                NombreProfesional = c.Profesional.Usuario.Nombre + " " + c.Profesional.Usuario.Apellido,
                c.Profesional.Especialidad,
                c.Profesional.CalificacionPromedio,
                c.PrecioOfertado,
                c.TiempoEstimado,
                c.Estado,
                YaCalificado = _context.Calificaciones.Any(calificacion =>
                    calificacion.IdUsuario == solicitud.IdUsuario &&
                    calificacion.IdProfesional == c.IdProfesional)
            })
            .ToListAsync(cancellationToken);

        return Ok(new
        {
            items = cotizaciones,
            estado = solicitud.Estado
        });
    }

    [HttpPost("requests/{id:int}/quotes/{quoteId:int}/accept")]
    public async Task<IActionResult> AceptarCotizacion(
        int id,
        int quoteId,
        CancellationToken cancellationToken = default)
    {
        if (!EsAdministrador() && !TryObtenerIdUsuario(out _))
        {
            return Unauthorized(new { mensaje = "El token no contiene un identificador de usuario válido" });
        }

        var solicitud = await _context.SolicitudesServicio
            .SingleOrDefaultAsync(s => s.IdSolicitud == id, cancellationToken);

        if (solicitud == null)
        {
            return NotFound(new { mensaje = "Solicitud no encontrada" });
        }

        if (!EsAdministrador() &&
            (!TryObtenerIdUsuario(out var idUsuario) || solicitud.IdUsuario != idUsuario))
        {
            return Forbid();
        }

        if (EsSolicitudAsignadaOCerrada(solicitud.Estado))
        {
            return Conflict(new { mensaje = "La solicitud ya fue asignada o está cerrada" });
        }

        if (!EsSolicitudAbierta(solicitud.Estado))
        {
            return Conflict(new { mensaje = "La solicitud no está disponible para asignación" });
        }

        var cotizacion = await _context.Cotizaciones
            .SingleOrDefaultAsync(
                c => c.IdCotizacion == quoteId && c.IdSolicitud == id,
                cancellationToken);

        if (cotizacion == null)
        {
            return NotFound(new { mensaje = "Cotización no encontrada para esta solicitud" });
        }

        if (cotizacion.Estado.ToLower() != "enviada")
        {
            return Conflict(new { mensaje = "La cotización no se encuentra disponible para aceptar" });
        }

        var otrasCotizaciones = await _context.Cotizaciones
            .Where(c => c.IdSolicitud == id && c.IdCotizacion != quoteId)
            .ToListAsync(cancellationToken);

        cotizacion.Estado = "aceptada";
        foreach (var otra in otrasCotizaciones)
        {
            otra.Estado = "rechazada";
        }

        solicitud.Estado = "asignada";
        await _context.SaveChangesAsync(cancellationToken);

        return Ok(new
        {
            mensaje = "Cotización aceptada",
            solicitud.IdSolicitud,
            solicitud.Estado,
            cotizacion = new
            {
                cotizacion.IdCotizacion,
                cotizacion.IdProfesional,
                cotizacion.PrecioOfertado,
                cotizacion.TiempoEstimado,
                cotizacion.Estado
            }
        });
    }

    [HttpPatch("requests/{id:int}/status")]
    public async Task<IActionResult> ActualizarEstadoSolicitud(
        int id,
        [FromBody] ActualizarEstadoRequest? request,
        CancellationToken cancellationToken = default)
    {
        if (!EsAdministrador() && !EsProfesional())
        {
            return Forbid();
        }

        if (request == null || string.IsNullOrWhiteSpace(request.Estado))
        {
            return BadRequest(new { mensaje = "El campo estado es obligatorio" });
        }

        var estadoSolicitado = NormalizarEstado(request.Estado);
        if (estadoSolicitado is not ("en proceso" or "completada"))
        {
            return BadRequest(new { mensaje = "El estado debe ser en proceso o completada" });
        }

        if (!EsAdministrador() && !TryObtenerIdUsuario(out _))
        {
            return Unauthorized(new { mensaje = "El token no contiene un identificador de usuario válido" });
        }

        var solicitud = await _context.SolicitudesServicio
            .SingleOrDefaultAsync(s => s.IdSolicitud == id, cancellationToken);

        if (solicitud == null)
        {
            return NotFound(new { mensaje = "Solicitud no encontrada" });
        }

        if (!EsAdministrador())
        {
            var idProfesional = await ObtenerIdProfesionalAsync(cancellationToken);
            var esProfesionalAsignado = idProfesional.HasValue &&
                await _context.Cotizaciones.AnyAsync(
                    c => c.IdSolicitud == id &&
                         c.IdProfesional == idProfesional.Value &&
                         c.Estado.ToLower() == "aceptada",
                    cancellationToken);

            if (!esProfesionalAsignado)
            {
                return Forbid();
            }
        }

        var estadoActual = NormalizarEstado(solicitud.Estado);
        var transicionValida =
            (estadoActual == "asignada" && estadoSolicitado == "en proceso") ||
            (estadoActual == "en proceso" && estadoSolicitado == "completada");

        if (!transicionValida)
        {
            return BadRequest(new
            {
                mensaje = "Transición de estado inválida. Solo se permite asignada → en proceso → completada"
            });
        }

        solicitud.Estado = estadoSolicitado;
        await _context.SaveChangesAsync(cancellationToken);

        return Ok(new
        {
            solicitud.IdSolicitud,
            solicitud.Estado
        });
    }

    [HttpGet("admin/summary")]
    public async Task<IActionResult> ObtenerResumenAdministrador(
        CancellationToken cancellationToken = default)
    {
        if (!EsAdministrador())
        {
            return Forbid();
        }

        var solicitudesPorEstado = await _context.SolicitudesServicio
            .AsNoTracking()
            .GroupBy(s => s.Estado.ToLower())
            .Select(grupo => new
            {
                Estado = grupo.Key,
                Cantidad = grupo.Count()
            })
            .OrderBy(grupo => grupo.Estado)
            .ToListAsync(cancellationToken);

        var totalUsuarios = await _context.Usuarios
            .AsNoTracking()
            .CountAsync(cancellationToken);
        var totalProfesionales = await _context.Profesionales
            .AsNoTracking()
            .CountAsync(cancellationToken);
        var totalCategorias = await _context.CategoriasServicio
            .AsNoTracking()
            .CountAsync(cancellationToken);
        var totalCategoriasActivas = await _context.CategoriasServicio
            .AsNoTracking()
            .CountAsync(c => c.Activa, cancellationToken);

        return Ok(new
        {
            solicitudesPorEstado,
            totalUsuarios,
            totalProfesionales,
            totalCategorias,
            totalCategoriasActivas
        });
    }

    [HttpGet("admin/professionals")]
    public async Task<IActionResult> ObtenerProfesionales(
        CancellationToken cancellationToken = default)
    {
        if (!EsAdministrador())
        {
            return Forbid();
        }

        var profesionales = await _context.Profesionales
            .AsNoTracking()
            .OrderBy(p => p.IdProfesional)
            .Select(p => new
            {
                p.IdProfesional,
                p.IdUsuario,
                p.Especialidad,
                p.Descripcion,
                p.TarifaHora,
                p.CalificacionPromedio,
                Usuario = new
                {
                    p.Usuario.Nombre,
                    p.Usuario.Apellido,
                    p.Usuario.Email,
                    p.Usuario.Telefono,
                    p.Usuario.TipoUsuario
                }
            })
            .ToListAsync(cancellationToken);

        return Ok(profesionales);
    }

    [HttpGet("admin/users")]
    public async Task<IActionResult> ObtenerUsuariosAdministrador(
        CancellationToken cancellationToken = default)
    {
        if (!EsAdministrador())
        {
            return Forbid();
        }

        var usuarios = await _context.Usuarios
            .AsNoTracking()
            .OrderBy(u => u.IdUsuario)
            .Select(u => new
            {
                u.IdUsuario,
                u.Nombre,
                u.Apellido,
                u.Email,
                u.TipoUsuario
            })
            .ToListAsync(cancellationToken);

        return Ok(usuarios);
    }

    [HttpPost("admin/professionals")]
    public async Task<IActionResult> CrearProfesional(
        [FromBody] CrearProfesionalRequest? request,
        CancellationToken cancellationToken = default)
    {
        if (!EsAdministrador())
        {
            return Forbid();
        }

        if (request == null)
        {
            return BadRequest(new { mensaje = "Se requiere el cuerpo del perfil profesional" });
        }

        var especialidad = request.Especialidad?.Trim();
        if (string.IsNullOrWhiteSpace(especialidad) || especialidad.Length > 100)
        {
            return BadRequest(new { mensaje = "La especialidad es obligatoria y no puede superar 100 caracteres" });
        }

        if (request.TarifaHora <= 0 || request.TarifaHora > 99_999_999.99m)
        {
            return BadRequest(new { mensaje = "La tarifaHora debe ser mayor que 0 y no superar 99999999.99" });
        }

        var usuario = await _context.Usuarios
            .SingleOrDefaultAsync(
                u => u.IdUsuario == request.IdUsuario,
                cancellationToken);

        if (usuario == null)
        {
            return NotFound(new { mensaje = "Usuario no encontrado" });
        }

        if (await _context.Profesionales.AnyAsync(
                p => p.IdUsuario == request.IdUsuario,
                cancellationToken))
        {
            return Conflict(new { mensaje = "El usuario ya tiene un perfil profesional" });
        }

        var profesional = new Profesional
        {
            IdUsuario = usuario.IdUsuario,
            Especialidad = especialidad,
            Descripcion = string.IsNullOrWhiteSpace(request.Descripcion)
                ? null
                : request.Descripcion.Trim(),
            TarifaHora = request.TarifaHora
        };

        usuario.TipoUsuario = "profesional";
        _context.Profesionales.Add(profesional);
        await _context.SaveChangesAsync(cancellationToken);

        return StatusCode(StatusCodes.Status201Created, new
        {
            profesional.IdProfesional,
            profesional.IdUsuario,
            profesional.Especialidad,
            profesional.Descripcion,
            profesional.TarifaHora,
            profesional.CalificacionPromedio,
            Usuario = new
            {
                usuario.Nombre,
                usuario.Apellido,
                usuario.Email,
                usuario.Telefono,
                usuario.TipoUsuario
            }
        });
    }

    [HttpPost("requests/{id:int}/ratings")]
    public async Task<IActionResult> CrearCalificacion(
        int id,
        [FromBody] CrearCalificacionRequest? request,
        CancellationToken cancellationToken = default)
    {
        if (request == null)
        {
            return BadRequest(new { mensaje = "Se requiere el cuerpo de la calificación" });
        }

        if (request.Puntuacion is < 1 or > 5)
        {
            return BadRequest(new { mensaje = "La puntuacion debe estar entre 1 y 5" });
        }

        if (request.Comentario?.Length > 1000)
        {
            return BadRequest(new { mensaje = "El comentario no puede superar 1000 caracteres" });
        }

        if (!TryObtenerIdUsuario(out var idUsuario))
        {
            return Unauthorized(new { mensaje = "El token no contiene un identificador de usuario válido" });
        }

        var solicitud = await _context.SolicitudesServicio
            .AsNoTracking()
            .Where(s => s.IdSolicitud == id)
            .Select(s => new { s.IdSolicitud, s.IdUsuario, s.Estado })
            .SingleOrDefaultAsync(cancellationToken);

        if (solicitud == null)
        {
            return NotFound(new { mensaje = "Solicitud no encontrada" });
        }

        if (solicitud.IdUsuario != idUsuario)
        {
            return Forbid();
        }

        if (NormalizarEstado(solicitud.Estado) != "completada")
        {
            return Conflict(new { mensaje = "Solo se pueden calificar solicitudes completadas" });
        }

        var profesional = await _context.Profesionales
            .SingleOrDefaultAsync(
                p => p.IdProfesional == request.IdProfesional,
                cancellationToken);

        if (profesional == null)
        {
            return NotFound(new { mensaje = "Profesional no encontrado" });
        }

        var cotizacionAceptada = await _context.Cotizaciones.AnyAsync(
            c => c.IdSolicitud == id &&
                 c.IdProfesional == request.IdProfesional &&
                 c.Estado.ToLower() == "aceptada",
            cancellationToken);

        if (!cotizacionAceptada)
        {
            return BadRequest(new
            {
                mensaje = "El profesional no tiene una cotización aceptada para esta solicitud"
            });
        }

        if (await _context.Calificaciones.AnyAsync(
                c => c.IdUsuario == idUsuario &&
                     c.IdProfesional == request.IdProfesional,
                cancellationToken))
        {
            return Conflict(new { mensaje = "Ya calificaste a este profesional" });
        }

        var calificacion = new Calificacion
        {
            IdUsuario = idUsuario,
            IdProfesional = request.IdProfesional,
            Puntuacion = request.Puntuacion,
            Comentario = string.IsNullOrWhiteSpace(request.Comentario)
                ? null
                : request.Comentario.Trim()
        };

        _context.Calificaciones.Add(calificacion);
        var calificacionesPrevias = await _context.Calificaciones
            .AsNoTracking()
            .Where(c => c.IdProfesional == request.IdProfesional)
            .Select(c => (double)c.Puntuacion)
            .ToListAsync(cancellationToken);

        var promedio = (decimal)Math.Round(
            (calificacionesPrevias.Sum() + request.Puntuacion) /
                (calificacionesPrevias.Count + 1),
            2,
            MidpointRounding.AwayFromZero);
        profesional.CalificacionPromedio = promedio;

        await _context.SaveChangesAsync(cancellationToken);

        return StatusCode(StatusCodes.Status201Created, new
        {
            calificacion.IdCalificacion,
            calificacion.IdUsuario,
            calificacion.IdProfesional,
            calificacion.Puntuacion,
            calificacion.Comentario,
            calificacion.Fecha,
            profesional.CalificacionPromedio
        });
    }

    private bool EsProfesional() => User.IsInRole(RolProfesional);

    private bool EsAdministrador() => User.IsInRole(RolAdministrador);

    private bool TryObtenerIdUsuario(out int idUsuario) =>
        int.TryParse(
            User.FindFirstValue(ClaimTypes.NameIdentifier),
            out idUsuario);

    private async Task<int?> ObtenerIdProfesionalAsync(
        CancellationToken cancellationToken)
    {
        if (!TryObtenerIdUsuario(out var idUsuario))
        {
            return null;
        }

        return await _context.Profesionales
            .AsNoTracking()
            .Where(p => p.IdUsuario == idUsuario)
            .Select(p => (int?)p.IdProfesional)
            .SingleOrDefaultAsync(cancellationToken);
    }

    private static bool EsSolicitudAbierta(string estado)
    {
        var estadoNormalizado = NormalizarEstado(estado);
        return estadoNormalizado is "publicada" or "pendiente";
    }

    private static bool EsSolicitudAsignadaOCerrada(string estado) =>
        NormalizarEstado(estado) is
            "asignada" or "en proceso" or "completada" or "completado" or
            "cerrada" or "cerrado" or "cancelada" or "cancelado";

    private static string NormalizarEstado(string estado) =>
        estado.Trim().ToLowerInvariant().Replace('_', ' ');
}

public sealed class CrearCotizacionRequest
{
    public decimal PrecioOfertado { get; set; }

    public string? TiempoEstimado { get; set; }

    public int? IdProfesional { get; set; }
}

public sealed class ActualizarEstadoRequest
{
    public string? Estado { get; set; }
}

public sealed class CrearProfesionalRequest
{
    public int IdUsuario { get; set; }

    public string? Especialidad { get; set; }

    public string? Descripcion { get; set; }

    public decimal TarifaHora { get; set; }
}

public sealed class CrearCalificacionRequest
{
    public int IdProfesional { get; set; }

    public int Puntuacion { get; set; }

    public string? Comentario { get; set; }
}
