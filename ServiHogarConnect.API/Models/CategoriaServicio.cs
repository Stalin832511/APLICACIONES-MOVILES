namespace ServiHogarConnect.API.Models;

public class CategoriaServicio
{
    public int IdCategoria { get; set; }

    public string Nombre { get; set; } = string.Empty;

    public string? Descripcion { get; set; }

    public bool Activa { get; set; } = true;

    public ICollection<SolicitudServicio> Solicitudes { get; set; }
        = new List<SolicitudServicio>();
}