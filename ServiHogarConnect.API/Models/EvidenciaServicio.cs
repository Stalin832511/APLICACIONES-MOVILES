namespace ServiHogarConnect.API.Models;

public class EvidenciaServicio
{
    public int IdEvidencia { get; set; }

    public int IdSolicitud { get; set; }

    public string StorageKey { get; set; } = string.Empty;

    public string NombreArchivo { get; set; } = string.Empty;

    public string TipoContenido { get; set; } = string.Empty;

    public long TamanoBytes { get; set; }

    public DateTime FechaCreacion { get; set; } = DateTime.UtcNow;

    public SolicitudServicio? Solicitud { get; set; }
}
