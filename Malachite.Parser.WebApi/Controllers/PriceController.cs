using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Diagnostics;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;

namespace Malachite.Parser.WebApi.Controllers
{
    [ApiController]
    [Route("[controller]")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public class PriceController : ControllerBase
    {
        private readonly StoreFactory _storeFactory;
        
        private readonly Stopwatch _stopwatch = new Stopwatch();

        public PriceController(StoreFactory storeFactory)
        {
            _storeFactory = storeFactory ?? throw new ArgumentNullException(nameof(storeFactory));            
        }

        [HttpPost]
        public Task<String> GetPrice([Required] PriceRequestModel request)
        {
            if (request is null)            
                throw new ArgumentNullException(nameof(request));

            return GetPrice(request, store => store.GetProductPrice);
        }


        [HttpPost("All")]
        public async IAsyncEnumerable<String> GetPrice([Required] IEnumerable<PriceRequestModel> request)
        {
            if (request is null)            
                throw new ArgumentNullException(nameof(request));

            foreach (var model in request)
            {
                 yield return await GetPrice(model);
            }
        }

        private Task<String> GetPrice(PriceRequestModel request, Func<IStore, Func<String, Task<String>>> create)
        {
            IStore store = _storeFactory(request.Store);
            var priceFunc = create(store);

            return priceFunc(request.Url);
        }
    }
}
