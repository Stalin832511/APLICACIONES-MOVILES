using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ServiHogarConnect.API.Data;
using ServiHogarConnect.API.Models;

namespace ServiHogarConnect.API.Controllers;

[ApiController]
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
        var solicitudes = await _context.SolicitudesServicio
            .Include(s => s.Usuario)
            .Include(s => s.Categoria)
            .OrderByDescending(s => s.FechaCreacion)
            .ToListAsync();

        return Ok(solicitudes);
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

        return Ok(solicitud);
    }

    [HttpPost]
    public async Task<ActionResult<SolicitudServicio>> CrearSolicitud(
        SolicitudServicio solicitud)
    {
        var usuarioExiste = await _context.Usuarios
            .AnyAsync(u => u.IdUsuario == solicitud.IdUsuario);

        if (!usuarioExiste)
        {
            return BadRequest(new
            {
                mensaje = "El usuario especificado no existe"
            });
        }

        var categoriaExiste = await _context.CategoriasServicio
            .AnyAsync(c => c.IdCategoria == solicitud.IdCategoria);

        if (!categoriaExiste)
        {
            return BadRequest(new
            {
                mensaje = "La categoría especificada no existe"
            });
        }

        solicitud.IdSolicitud = 0;
        solicitud.FechaCreacion = DateTime.UtcNow;

        _context.SolicitudesServicio.Add(solicitud);

        await _context.SaveChangesAsync();

        return CreatedAtAction(
            nameof(ObtenerSolicitud),
            new { id = solicitud.IdSolicitud },
            solicitud);
    }
}