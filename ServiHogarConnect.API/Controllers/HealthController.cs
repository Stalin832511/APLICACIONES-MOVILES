using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace ServiHogarConnect.API.Controllers;

[ApiController]
[Route("api/v1/health")]
public class HealthController : ControllerBase
{
    [HttpGet]
    [Authorize]
    public IActionResult Get()
    {
        return Ok(new
        {
            success = true,
            message = "API ServiHogar Connect funcionando correctamente",
            project = "ServiHogar Connect",
            version = "v1"
        });
    }
}