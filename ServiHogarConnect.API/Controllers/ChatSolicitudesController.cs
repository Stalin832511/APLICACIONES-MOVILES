using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ServiHogarConnect.API.Data;
using ServiHogarConnect.API.Models;

namespace ServiHogarConnect.API.Controllers;

[ApiController]
[Authorize]
[Route("api/solicitudes/{idSolicitud:int}/chat")]
public sealed class ChatSolicitudesController : ControllerBase
{
    private const int LimiteMensaje = 2000;
    private const int TamanoPagina = 100;
    private readonly AppDbContext _context;

    public ChatSolicitudesController(AppDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<IActionResult> ObtenerMensajes(
        int idSolicitud,
        [FromQuery] int afterId = 0,
        CancellationToken cancellationToken = default)
    {
        if (afterId < 0)
        {
            return BadRequest(new { mensaje = "afterId debe ser mayor o igual a 0" });
        }

        if (!TryObtenerIdUsuario(out var idUsuario))
        {
            return Unauthorized(new { mensaje = "El token no contiene un identificador de usuario válido" });
        }

        var acceso = await ObtenerAccesoChatAsync(idSolicitud, cancellationToken);
        if (acceso == null)
        {
            return NotFound(new { mensaje = "Solicitud no encontrada" });
        }

        if (acceso.ProfesionalesEnConflicto)
        {
            return Conflict(new { mensaje = "La solicitud tiene asignaciones incompatibles para abrir el chat" });
        }

        if (!acceso.IdUsuarioProfesional.HasValue)
        {
            return Conflict(new { mensaje = "El chat estará disponible cuando se acepte una cotización" });
        }

        if (acceso.IdUsuarioCliente == acceso.IdUsuarioProfesional.Value)
        {
            return Conflict(new { mensaje = "La solicitud no tiene un participante distinto para el chat" });
        }

        if (idUsuario != acceso.IdUsuarioCliente &&
            idUsuario != acceso.IdUsuarioProfesional.Value)
        {
            return Forbid();
        }

        var consulta = _context.MensajesChat
            .AsNoTracking()
            .Where(m =>
                m.IdSolicitud == idSolicitud &&
                (m.IdEmisor == idUsuario || m.IdReceptor == idUsuario));

        List<MensajeChatDto> mensajes;
        if (afterId > 0)
        {
            mensajes = await consulta
                .Where(m => m.IdMensaje > afterId)
                .OrderBy(m => m.IdMensaje)
                .Take(TamanoPagina)
                .Select(m => new MensajeChatDto(
                    m.IdMensaje,
                    m.IdEmisor,
                    m.Emisor.Nombre,
                    m.Emisor.Apellido,
                    m.IdReceptor,
                    m.Mensaje,
                    m.FechaEnvio))
                .ToListAsync(cancellationToken);
        }
        else
        {
            mensajes = await consulta
                .OrderByDescending(m => m.IdMensaje)
                .Take(TamanoPagina)
                .Select(m => new MensajeChatDto(
                    m.IdMensaje,
                    m.IdEmisor,
                    m.Emisor.Nombre,
                    m.Emisor.Apellido,
                    m.IdReceptor,
                    m.Mensaje,
                    m.FechaEnvio))
                .ToListAsync(cancellationToken);
            mensajes.Reverse();
        }

        return Ok(mensajes);
    }

    [HttpPost]
    public async Task<IActionResult> EnviarMensaje(
        int idSolicitud,
        [FromBody] EnviarMensajeChatRequest? request,
        CancellationToken cancellationToken = default)
    {
        if (!TryObtenerIdUsuario(out var idUsuario))
        {
            return Unauthorized(new { mensaje = "El token no contiene un identificador de usuario válido" });
        }

        if (request == null || string.IsNullOrWhiteSpace(request.Mensaje))
        {
            return BadRequest(new { mensaje = "El mensaje no puede estar vacío" });
        }

        var contenido = request.Mensaje.Trim();
        if (contenido.Length > LimiteMensaje)
        {
            return BadRequest(new { mensaje = $"El mensaje no puede superar {LimiteMensaje} caracteres" });
        }

        var acceso = await ObtenerAccesoChatAsync(idSolicitud, cancellationToken);
        if (acceso == null)
        {
            return NotFound(new { mensaje = "Solicitud no encontrada" });
        }

        if (acceso.ProfesionalesEnConflicto)
        {
            return Conflict(new { mensaje = "La solicitud tiene asignaciones incompatibles para abrir el chat" });
        }

        if (!acceso.IdUsuarioProfesional.HasValue)
        {
            return Conflict(new { mensaje = "El chat estará disponible cuando se acepte una cotización" });
        }

        if (acceso.IdUsuarioCliente == acceso.IdUsuarioProfesional.Value)
        {
            return Conflict(new { mensaje = "La solicitud no tiene un participante distinto para el chat" });
        }

        int idReceptor;
        if (idUsuario == acceso.IdUsuarioCliente)
        {
            idReceptor = acceso.IdUsuarioProfesional.Value;
        }
        else if (idUsuario == acceso.IdUsuarioProfesional.Value)
        {
            idReceptor = acceso.IdUsuarioCliente;
        }
        else
        {
            return Forbid();
        }

        var mensaje = new MensajeChat
        {
            IdSolicitud = idSolicitud,
            IdEmisor = idUsuario,
            IdReceptor = idReceptor,
            Mensaje = contenido,
            FechaEnvio = DateTime.UtcNow
        };

        _context.MensajesChat.Add(mensaje);
        await _context.SaveChangesAsync(cancellationToken);

        var nombreEmisor = await _context.Usuarios
            .AsNoTracking()
            .Where(u => u.IdUsuario == idUsuario)
            .Select(u => new { u.Nombre, u.Apellido })
            .SingleAsync(cancellationToken);

        return StatusCode(StatusCodes.Status201Created, new MensajeChatDto(
            mensaje.IdMensaje,
            mensaje.IdEmisor,
            nombreEmisor.Nombre,
            nombreEmisor.Apellido,
            mensaje.IdReceptor,
            mensaje.Mensaje,
            mensaje.FechaEnvio));
    }

    private async Task<AccesoChat?> ObtenerAccesoChatAsync(
        int idSolicitud,
        CancellationToken cancellationToken)
    {
        var idUsuarioCliente = await _context.SolicitudesServicio
            .AsNoTracking()
            .Where(s => s.IdSolicitud == idSolicitud)
            .Select(s => (int?)s.IdUsuario)
            .SingleOrDefaultAsync(cancellationToken);

        if (!idUsuarioCliente.HasValue)
        {
            return null;
        }

        var profesionales = await _context.Cotizaciones
            .AsNoTracking()
            .Where(c =>
                c.IdSolicitud == idSolicitud &&
                c.Estado.ToLower() == "aceptada")
            .Select(c => c.Profesional.IdUsuario)
            .Distinct()
            .Take(2)
            .ToListAsync(cancellationToken);

        return new AccesoChat(
            idUsuarioCliente.Value,
            profesionales.Count == 1 ? profesionales[0] : null,
            profesionales.Count > 1);
    }

    private bool TryObtenerIdUsuario(out int idUsuario) =>
        int.TryParse(
            User.FindFirstValue(ClaimTypes.NameIdentifier),
            out idUsuario);

    private sealed record AccesoChat(
        int IdUsuarioCliente,
        int? IdUsuarioProfesional,
        bool ProfesionalesEnConflicto);
}

public sealed record EnviarMensajeChatRequest(string? Mensaje);

public sealed record MensajeChatDto(
    int IdMensaje,
    int IdEmisor,
    string NombreEmisor,
    string ApellidoEmisor,
    int IdReceptor,
    string Mensaje,
    DateTime FechaEnvio);
