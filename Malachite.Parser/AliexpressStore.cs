using System;
using System.Threading.Tasks;

public class AliexpressStore : Store
{
    public override Task<string> GetProductPrice(string link)
    {
        return Task.Run(() => (String) null);
    }
}