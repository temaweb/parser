using System;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;

public class DefaultStore : IStore
{
    private readonly ILogger<DefaultStore> _logger;

    public DefaultStore(ILogger<DefaultStore> logger)
    {
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));
    }

    public Task<String> GetProductPrice(String link)
    {
        _logger.LogWarning($"Not supported store: {link}");
        return Task.Run(() => (String) null);
    }
}