using System.Threading.Tasks;
using System;

public abstract class Store : IStore
{
    public abstract Task<String> GetProductPrice(String link);
}