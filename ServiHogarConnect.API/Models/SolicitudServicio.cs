using System.Text.Json.Serialization;

namespace ServiHogarConnect.API.Models;

public class SolicitudServicio
{
    public int IdSolicitud { get; set; }

    public int IdUsuario { get; set; }

    public int IdCategoria { get; set; }

    public string Descripcion { get; set; } = string.Empty;

    public string Estado { get; set; } = "publicada";

    public DateTime FechaCreacion { get; set; } = DateTime.UtcNow;

    public decimal Latitud { get; set; }

    public decimal Longitud { get; set; }

    [JsonIgnore]
    public Usuario? Usuario { get; set; }

    [JsonIgnore]
    public CategoriaServicio? Categoria { get; set; }

    public ICollection<Cotizacion> Cotizaciones { get; set; } = new List<Cotizacion>();
}