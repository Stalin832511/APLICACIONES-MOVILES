using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ServiHogarConnect.API.Data;
using ServiHogarConnect.API.Models;

namespace ServiHogarConnect.API.Controllers;

[ApiController]
[Route("api/categorias")]
public class CategoriasController : ControllerBase
{
    private readonly AppDbContext _context;

    public CategoriasController(AppDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<CategoriaResponse>>> ObtenerCategorias(
        CancellationToken cancellationToken)
    {
        var categorias = await _context.CategoriasServicio
            .AsNoTracking()
            .Where(categoria => categoria.Activa)
            .OrderBy(categoria => categoria.Nombre)
            .Select(categoria => new CategoriaResponse(
                categoria.IdCategoria,
                categoria.Nombre,
                categoria.Descripcion))
            .ToListAsync(cancellationToken);

        return Ok(categorias);
    }

    [HttpGet("admin")]
    [Authorize(Roles = "Administrador")]
    public async Task<ActionResult<IEnumerable<object>>> ObtenerTodasParaAdministrador(
        CancellationToken cancellationToken)
    {
        var categorias = await _context.CategoriasServicio
            .AsNoTracking()
            .OrderBy(categoria => categoria.Nombre)
            .Select(categoria => new
            {
                categoria.IdCategoria,
                categoria.Nombre,
                categoria.Descripcion,
                categoria.Activa
            })
            .ToListAsync(cancellationToken);

        return Ok(categorias);
    }

    [HttpPost]
    [Authorize(Roles = "Administrador")]
    public async Task<ActionResult<CategoriaResponse>> CrearCategoria(
        [FromBody] CrearCategoriaRequest request,
        CancellationToken cancellationToken)
    {
        var nombre = NormalizarNombre(request.Nombre);
        if (await ExisteNombreAsync(nombre, null, cancellationToken))
        {
            return Conflict(new { mensaje = "Ya existe una categoría con ese nombre" });
        }

        var categoria = new CategoriaServicio
        {
            Nombre = nombre,
            Descripcion = NormalizarDescripcion(request.Descripcion),
            Activa = true
        };

        _context.CategoriasServicio.Add(categoria);
        try
        {
            await _context.SaveChangesAsync(cancellationToken);
        }
        catch (DbUpdateException)
        {
            if (await ExisteNombreAsync(nombre, null, cancellationToken))
            {
                return Conflict(new { mensaje = "Ya existe una categoría con ese nombre" });
            }

            throw;
        }

        return StatusCode(
            StatusCodes.Status201Created,
            new CategoriaResponse(
                categoria.IdCategoria,
                categoria.Nombre,
                categoria.Descripcion));
    }

    [HttpPut("{id:int}")]
    [Authorize(Roles = "Administrador")]
    public async Task<ActionResult<CategoriaResponse>> ActualizarCategoria(
        int id,
        [FromBody] ActualizarCategoriaRequest request,
        CancellationToken cancellationToken)
    {
        var categoria = await _context.CategoriasServicio
            .FirstOrDefaultAsync(
                item => item.IdCategoria == id,
                cancellationToken);

        if (categoria == null)
        {
            return NotFound(new { mensaje = "No se encontró la categoría solicitada" });
        }

        var nombre = NormalizarNombre(request.Nombre);
        if (await ExisteNombreAsync(nombre, id, cancellationToken))
        {
            return Conflict(new { mensaje = "Ya existe una categoría con ese nombre" });
        }

        categoria.Nombre = nombre;
        categoria.Descripcion = NormalizarDescripcion(request.Descripcion);
        categoria.Activa = request.Activa!.Value;

        try
        {
            await _context.SaveChangesAsync(cancellationToken);
        }
        catch (DbUpdateException)
        {
            if (await ExisteNombreAsync(nombre, id, cancellationToken))
            {
                return Conflict(new { mensaje = "Ya existe una categoría con ese nombre" });
            }

            throw;
        }

        return Ok(new CategoriaResponse(
            categoria.IdCategoria,
            categoria.Nombre,
            categoria.Descripcion));
    }

    private Task<bool> ExisteNombreAsync(
        string nombreNormalizado,
        int? idExcluido,
        CancellationToken cancellationToken)
    {
        var nombreClave = nombreNormalizado.ToLowerInvariant();
        var consulta = _context.CategoriasServicio
            .Where(categoria =>
                categoria.Nombre.Trim().ToLower() == nombreClave);

        if (idExcluido.HasValue)
        {
            consulta = consulta.Where(
                categoria => categoria.IdCategoria != idExcluido.Value);
        }

        return consulta.AnyAsync(cancellationToken);
    }

    private static string NormalizarNombre(string nombre) => nombre.Trim();

    private static string? NormalizarDescripcion(string? descripcion) =>
        string.IsNullOrWhiteSpace(descripcion) ? null : descripcion.Trim();
}

public sealed record CategoriaResponse(
    int IdCategoria,
    string Nombre,
    string? Descripcion);

public class CrearCategoriaRequest
{
    [Required(ErrorMessage = "El nombre de la categoría es obligatorio.")]
    [StringLength(
        100,
        ErrorMessage = "El nombre de la categoría no puede superar los 100 caracteres.")]
    public string Nombre { get; init; } = string.Empty;

    [StringLength(
        500,
        ErrorMessage = "La descripción no puede superar los 500 caracteres.")]
    public string? Descripcion { get; init; }
}

public sealed class ActualizarCategoriaRequest : CrearCategoriaRequest
{
    [Required(ErrorMessage = "Debe indicar si la categoría está activa.")]
    public bool? Activa { get; init; }
}
