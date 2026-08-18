using ServiHogarConnect.API.Services;

namespace ServiHogarConnect.API.Jobs;

public class WorkerService : BackgroundService
{
    private readonly ITrabajoQueue _cola;
    private readonly ILogger<WorkerService> _logger;

    public WorkerService(
        ITrabajoQueue cola,
        ILogger<WorkerService> logger)
    {
        _cola = cola;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(
        CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                var trabajo = await _cola.DequeueAsync(stoppingToken);

                await trabajo(stoppingToken);

                _logger.LogInformation(
                    "Trabajo asíncrono ejecutado correctamente");
            }
            catch (OperationCanceledException)
            {
                break;
            }
            catch (Exception ex)
            {
                _logger.LogError(
                    ex,
                    "Error ejecutando trabajo asíncrono");
            }
        }
    }
}
