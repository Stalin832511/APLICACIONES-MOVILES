namespace ServiHogarConnect.API.Models;

public class Cotizacion
{
    public int IdCotizacion { get; set; }

    public int IdSolicitud { get; set; }

    public int IdProfesional { get; set; }

    public decimal PrecioOfertado { get; set; }

    public string? TiempoEstimado { get; set; }

    public string Estado { get; set; } = "enviada";

    public SolicitudServicio Solicitud { get; set; } = null!;

    public Profesional Profesional { get; set; } = null!;
}