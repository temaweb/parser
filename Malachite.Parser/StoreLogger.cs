using System;
using System.Diagnostics;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;

public class StoreLogger<TStore> : IStore where TStore : IStore
{
    private readonly TStore _store;

    private readonly ILogger<TStore> _logger;
    
    private readonly Stopwatch _stopwatch = new Stopwatch();

    public StoreLogger(TStore store, ILogger<TStore> logger)
    {
        _store  = store  ?? throw new ArgumentNullException(nameof(store));
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));
    }

    public async Task<String> GetProductPrice(string link)
    {
        var eventid = new EventId();

        try
        {
            _logger.LogInformation(eventid, $"Start request {link}");
            _stopwatch.Restart();

            return await _store.GetProductPrice(link);
        }
        catch (Exception exception)  
        {
            _logger.LogError(eventid, exception, "Error");
            
            throw;
        }
        finally
        {
            _stopwatch.Stop();
            _logger.LogInformation(eventid, $"End request {link} in {_stopwatch.ElapsedMilliseconds} ms");
        }
    }
}