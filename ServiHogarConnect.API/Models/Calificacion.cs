namespace ServiHogarConnect.API.Models;

public class Calificacion
{
    public int IdCalificacion { get; set; }

    public int IdUsuario { get; set; }

    public int IdProfesional { get; set; }

    public int Puntuacion { get; set; }

    public string? Comentario { get; set; }

    public DateTime Fecha { get; set; } = DateTime.UtcNow;

    public Usuario Usuario { get; set; } = null!;

    public Profesional Profesional { get; set; } = null!;
}