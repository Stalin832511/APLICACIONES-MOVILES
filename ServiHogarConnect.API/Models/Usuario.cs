namespace ServiHogarConnect.API.Models;

public class Usuario
{
    public int IdUsuario { get; set; }

    public string Nombre { get; set; } = string.Empty;

    public string Apellido { get; set; } = string.Empty;

    public string Email { get; set; } = string.Empty;

    public string PasswordHash { get; set; } = string.Empty;

    public string? Telefono { get; set; }

    public string TipoUsuario { get; set; } = "cliente";

    public DateTime FechaRegistro { get; set; } = DateTime.UtcNow;

    // Relaciones
    public Profesional? Profesional { get; set; }

    public ICollection<SolicitudServicio> Solicitudes { get; set; }
        = new List<SolicitudServicio>();

    public ICollection<Calificacion> Calificaciones { get; set; }
        = new List<Calificacion>();

    public ICollection<MensajeChat> MensajesEnviados { get; set; }
        = new List<MensajeChat>();

    public ICollection<MensajeChat> MensajesRecibidos { get; set; }
        = new List<MensajeChat>();
}