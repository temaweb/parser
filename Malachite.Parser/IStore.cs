using System;
using System.Threading.Tasks;

public interface IStore
{
    Task<String> GetProductPrice(String link);
}