using System;
using System.ComponentModel.DataAnnotations;
using System.Diagnostics;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;

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
        
        private readonly ILogger<PriceController> _logger;
        

        public PriceController(StoreFactory storeFactory, ILogger<PriceController> logger)
        {
            _storeFactory = storeFactory ?? throw new ArgumentNullException(nameof(storeFactory));
            _logger = logger ?? throw new ArgumentNullException(nameof(logger));
        }

        [HttpPost]
        public Task<String> GetPrice([Required] PriceRequestModel request)
        {
            if (request is null)            
                throw new ArgumentNullException(nameof(request));
            
            return GetPriceInRub(request);
        }

        [HttpPost("Rub")]
        public async Task<String> GetPriceInRub([Required] PriceRequestModel request)
        {
            if (request is null)            
                throw new ArgumentNullException(nameof(request));

            var eventid = new EventId();

            try
            {
                _logger.LogInformation(eventid, $"Start request {request.Url}");
                _stopwatch.Restart();

                return await GetPrice(request, store => store.GetProductPrice);
            }
            catch (Exception exception)  
            {
                _logger.LogError(eventid, exception, "Error");
                throw;
            }
            finally
            {
                _stopwatch.Stop();
                _logger.LogInformation(eventid, $"End request {request.Url} in {_stopwatch.ElapsedMilliseconds} ms");
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
