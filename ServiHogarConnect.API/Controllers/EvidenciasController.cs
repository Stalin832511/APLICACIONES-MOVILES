using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ServiHogarConnect.API.Data;
using ServiHogarConnect.API.Models;

namespace ServiHogarConnect.API.Controllers;

[ApiController]
[Authorize]
[Route("api/solicitudes/{id:int}/evidencias")]
public sealed class EvidenciasController : ControllerBase
{
    private const long MaxFileLength = 10 * 1024 * 1024;
    private const int MaxRequestLength = (int)(MaxFileLength + 64 * 1024);
    private readonly AppDbContext _context;
    private readonly string _storageRoot;
    private readonly ILogger<EvidenciasController> _logger;

    public EvidenciasController(
        AppDbContext context,
        IConfiguration configuration,
        IWebHostEnvironment environment,
        ILogger<EvidenciasController> logger)
    {
        _context = context;
        _logger = logger;

        var configuredRoot = configuration["EvidenceStorage:RootPath"];
        if (string.IsNullOrWhiteSpace(configuredRoot))
        {
            _storageRoot = Path.GetFullPath(Path.Combine(
                environment.ContentRootPath,
                "App_Data",
                "evidence"));
        }
        else
        {
            _storageRoot = Path.GetFullPath(Path.IsPathRooted(configuredRoot)
                ? configuredRoot
                : Path.Combine(environment.ContentRootPath, configuredRoot));
        }
    }

    [HttpPost]
    [Consumes("multipart/form-data")]
    [RequestSizeLimit(MaxRequestLength)]
    public async Task<IActionResult> Subir(
        int id,
        [FromForm(Name = "file")] IFormFile? file,
        CancellationToken cancellationToken)
    {
        var solicitud = await ObtenerSolicitudAutorizada(id, cancellationToken);
        if (solicitud.Result != null)
        {
            return solicitud.Result!;
        }

        if (file == null || file.Length == 0)
        {
            return BadRequest(new { mensaje = "Debe adjuntar un archivo." });
        }

        if (file.Length > MaxFileLength)
        {
            return StatusCode(StatusCodes.Status413PayloadTooLarge);
        }

        var nombreArchivo = ObtenerNombreSeguro(file.FileName);
        if (nombreArchivo.Length == 0)
        {
            return BadRequest(new { mensaje = "El nombre del archivo no es válido." });
        }

        var storageKey = $"{id}/{Guid.NewGuid():N}";
        var destinationPath = ObtenerRutaSegura(storageKey);
        Directory.CreateDirectory(Path.GetDirectoryName(destinationPath)!);

        string tipoContenido;
        string fileNameExtension;
        try
        {
            await using var input = file.OpenReadStream();
            var signature = new byte[12];
            var bytesRead = await LeerEncabezadoAsync(input, signature, cancellationToken);
            (tipoContenido, fileNameExtension) = DetectarTipo(signature, bytesRead);

            storageKey += fileNameExtension;
            destinationPath = ObtenerRutaSegura(storageKey);
            await using var output = new FileStream(
                destinationPath,
                FileMode.CreateNew,
                FileAccess.Write,
                FileShare.None,
                bufferSize: 81920,
                options: FileOptions.Asynchronous | FileOptions.SequentialScan);
            await output.WriteAsync(
                signature.AsMemory(0, bytesRead),
                cancellationToken);
            await input.CopyToAsync(output, cancellationToken);
        }
        catch (UnsupportedImageException)
        {
            return StatusCode(
                StatusCodes.Status415UnsupportedMediaType,
                new { mensaje = "Solo se permiten imágenes JPEG, PNG o WebP válidas." });
        }
        catch (IOException)
        {
            TryDeleteFile(destinationPath);
            throw;
        }

        var evidence = new EvidenciaServicio
        {
            IdSolicitud = id,
            StorageKey = storageKey,
            NombreArchivo = nombreArchivo,
            TipoContenido = tipoContenido,
            TamanoBytes = file.Length,
            FechaCreacion = DateTime.UtcNow
        };

        _context.EvidenciasServicio.Add(evidence);
        try
        {
            await _context.SaveChangesAsync(cancellationToken);
        }
        catch
        {
            TryDeleteFile(destinationPath);
            throw;
        }

        return CreatedAtAction(
            nameof(Descargar),
            new { id, evidenciaId = evidence.IdEvidencia },
            CrearRespuesta(evidence));
    }

    [HttpGet]
    public async Task<IActionResult> Listar(int id, CancellationToken cancellationToken)
    {
        var solicitud = await ObtenerSolicitudAutorizada(id, cancellationToken);
        if (solicitud.Result != null)
        {
            return solicitud.Result!;
        }

        var evidencias = await _context.EvidenciasServicio
            .AsNoTracking()
            .Where(e => e.IdSolicitud == id)
            .OrderBy(e => e.FechaCreacion)
            .ThenBy(e => e.IdEvidencia)
            .Select(e => new
            {
                e.IdEvidencia,
                e.IdSolicitud,
                e.NombreArchivo,
                e.TipoContenido,
                e.TamanoBytes,
                e.FechaCreacion
            })
            .ToListAsync(cancellationToken);

        return Ok(evidencias.Select(e => new
        {
            e.IdEvidencia,
            e.IdSolicitud,
            nombreArchivo = e.NombreArchivo,
            tipoContenido = e.TipoContenido,
            tamanoBytes = e.TamanoBytes,
            fechaCreacion = e.FechaCreacion,
            url = $"/api/solicitudes/{id}/evidencias/{e.IdEvidencia}/archivo"
        }));
    }

    [HttpGet("{evidenciaId:int}/archivo")]
    public async Task<IActionResult> Descargar(
        int id,
        int evidenciaId,
        CancellationToken cancellationToken)
    {
        var solicitud = await ObtenerSolicitudAutorizada(id, cancellationToken);
        if (solicitud.Result != null)
        {
            return solicitud.Result!;
        }

        var evidence = await _context.EvidenciasServicio
            .AsNoTracking()
            .FirstOrDefaultAsync(
                e => e.IdEvidencia == evidenciaId && e.IdSolicitud == id,
                cancellationToken);
        if (evidence == null)
        {
            return NotFound();
        }

        var path = ObtenerRutaSegura(evidence.StorageKey);
        try
        {
            var stream = new FileStream(
                path,
                FileMode.Open,
                FileAccess.Read,
                FileShare.Read,
                bufferSize: 81920,
                options: FileOptions.Asynchronous | FileOptions.SequentialScan);
            return File(stream, evidence.TipoContenido, evidence.NombreArchivo);
        }
        catch (FileNotFoundException)
        {
            return NotFound();
        }
        catch (DirectoryNotFoundException)
        {
            return NotFound();
        }
    }

    private async Task<(IActionResult? Result, SolicitudServicio? Value)>
        ObtenerSolicitudAutorizada(int id, CancellationToken cancellationToken)
    {
        var solicitud = await _context.SolicitudesServicio
            .AsNoTracking()
            .FirstOrDefaultAsync(s => s.IdSolicitud == id, cancellationToken);
        if (solicitud == null)
        {
            return (NotFound(new { mensaje = "Solicitud no encontrada." }), null);
        }

        var canAccess = User.IsInRole("Administrador");
        if (!canAccess &&
            int.TryParse(
                User.FindFirstValue(ClaimTypes.NameIdentifier),
                out var userId))
        {
            canAccess = solicitud.IdUsuario == userId;

            if (!canAccess && User.IsInRole("Profesional"))
            {
                var professionalId = await _context.Profesionales
                    .Where(professional => professional.IdUsuario == userId)
                    .Select(professional => (int?)professional.IdProfesional)
                    .FirstOrDefaultAsync(cancellationToken);

                canAccess = professionalId.HasValue &&
                    await _context.Cotizaciones.AnyAsync(
                        quote => quote.IdSolicitud == id &&
                            quote.IdProfesional == professionalId.Value &&
                            quote.Estado == "aceptada",
                        cancellationToken);
            }
        }

        if (!canAccess)
        {
            return (Forbid(), null);
        }

        return (null, solicitud);
    }

    private object CrearRespuesta(EvidenciaServicio evidence) => new
    {
        idEvidencia = evidence.IdEvidencia,
        idSolicitud = evidence.IdSolicitud,
        nombreArchivo = evidence.NombreArchivo,
        tipoContenido = evidence.TipoContenido,
        tamanoBytes = evidence.TamanoBytes,
        fechaCreacion = evidence.FechaCreacion,
        url = $"/api/solicitudes/{evidence.IdSolicitud}/evidencias/{evidence.IdEvidencia}/archivo"
    };

    private string ObtenerRutaSegura(string storageKey)
    {
        var portableKey = storageKey
            .Replace('/', Path.DirectorySeparatorChar)
            .Replace('\\', Path.DirectorySeparatorChar);
        var path = Path.GetFullPath(Path.Combine(_storageRoot, portableKey));
        var rootWithSeparator = _storageRoot.EndsWith(Path.DirectorySeparatorChar)
            ? _storageRoot
            : _storageRoot + Path.DirectorySeparatorChar;
        var pathComparison = OperatingSystem.IsWindows()
            ? StringComparison.OrdinalIgnoreCase
            : StringComparison.Ordinal;
        if (!path.StartsWith(rootWithSeparator, pathComparison))
        {
            throw new InvalidOperationException("Invalid evidence storage key.");
        }

        return path;
    }

    private static string ObtenerNombreSeguro(string? fileName)
    {
        var name = Path.GetFileName((fileName ?? string.Empty).Replace('\\', '/'));
        var safeName = new string(name
            .Where(character => !char.IsControl(character))
            .ToArray())
            .Trim();
        return safeName.Length <= 255 ? safeName : safeName[..255];
    }

    private static async Task<int> LeerEncabezadoAsync(
        Stream input,
        byte[] header,
        CancellationToken cancellationToken)
    {
        var total = 0;
        while (total < header.Length)
        {
            var read = await input.ReadAsync(
                header.AsMemory(total),
                cancellationToken);
            if (read == 0)
            {
                break;
            }

            total += read;
        }

        return total;
    }

    private static (string ContentType, string Extension) DetectarTipo(
        byte[] header,
        int length)
    {
        if (length >= 3 &&
            header[0] == 0xFF &&
            header[1] == 0xD8 &&
            header[2] == 0xFF)
        {
            return ("image/jpeg", ".jpg");
        }

        if (length >= 8 &&
            header.AsSpan(0, 8).SequenceEqual(
                new byte[] { 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A }))
        {
            return ("image/png", ".png");
        }

        if (length >= 12 &&
            header.AsSpan(0, 4).SequenceEqual("RIFF"u8) &&
            header.AsSpan(8, 4).SequenceEqual("WEBP"u8))
        {
            return ("image/webp", ".webp");
        }

        throw new UnsupportedImageException();
    }

    private void TryDeleteFile(string path)
    {
        try
        {
            if (System.IO.File.Exists(path))
            {
                System.IO.File.Delete(path);
            }
        }
        catch (IOException exception)
        {
            _logger.LogError(exception, "Failed to remove an unreferenced evidence file.");
        }
        catch (UnauthorizedAccessException exception)
        {
            _logger.LogError(exception, "Failed to remove an unreferenced evidence file.");
        }
    }

    private sealed class UnsupportedImageException : Exception
    {
    }
}
