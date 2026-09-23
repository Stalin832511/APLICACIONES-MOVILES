namespace ServiHogarConnect.API.Models;

public class RefreshToken
{
    public int IdRefreshToken { get; set; }

    public string Token { get; set; } = string.Empty;

    public DateTime FechaExpiracion { get; set; }

    public bool Revocado { get; set; }

    public int IdUsuario { get; set; }

    public Usuario Usuario { get; set; } = null!;
}