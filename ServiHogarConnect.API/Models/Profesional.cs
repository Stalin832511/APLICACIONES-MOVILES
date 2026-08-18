namespace ServiHogarConnect.API.Models;

public class Profesional
{
    public int IdProfesional { get; set; }

    public int IdUsuario { get; set; }

    public string Especialidad { get; set; } = string.Empty;

    public string? Descripcion { get; set; }

    public decimal TarifaHora { get; set; }

    public decimal? CalificacionPromedio { get; set; }

    // Relación con Usuario
    public Usuario Usuario { get; set; } = null!;

    // Relaciones
    public ICollection<Cotizacion> Cotizaciones { get; set; }
        = new List<Cotizacion>();

    public ICollection<Calificacion> Calificaciones { get; set; }
        = new List<Calificacion>();
}