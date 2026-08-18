using System.Threading.Channels;

namespace ServiHogarConnect.API.Services;

public interface ITrabajoQueue
{
    ValueTask EnqueueAsync(Func<CancellationToken, Task> trabajo);
    ValueTask<Func<CancellationToken, Task>> DequeueAsync(
        CancellationToken cancellationToken);
}

public class TrabajoQueue : ITrabajoQueue
{
    private readonly Channel<Func<CancellationToken, Task>> _cola;

    public TrabajoQueue()
    {
        _cola = Channel.CreateUnbounded<Func<CancellationToken, Task>>();
    }

    public async ValueTask EnqueueAsync(
        Func<CancellationToken, Task> trabajo)
    {
        await _cola.Writer.WriteAsync(trabajo);
    }

    public async ValueTask<Func<CancellationToken, Task>> DequeueAsync(
        CancellationToken cancellationToken)
    {
        return await _cola.Reader.ReadAsync(cancellationToken);
    }
}
