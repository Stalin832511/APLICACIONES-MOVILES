namespace ServiHogarConnect.API.Models;

public class MensajeChat
{
    public int IdMensaje { get; set; }

    public int IdEmisor { get; set; }

    public int IdReceptor { get; set; }

    public string Mensaje { get; set; } = string.Empty;

    public DateTime FechaEnvio { get; set; } = DateTime.UtcNow;

    public Usuario Emisor { get; set; } = null!;

    public Usuario Receptor { get; set; } = null!;
}