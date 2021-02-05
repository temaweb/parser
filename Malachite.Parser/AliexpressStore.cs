using System;
using System.Threading.Tasks;

public class AliexpressStore : IStore
{
    public Task<String> GetProductPrice(String link)
    {
        return (Task<string>) Task.CompletedTask;
    }
}