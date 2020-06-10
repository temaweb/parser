using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace Malachite.Parser.WebApi
{
    public class Startup
    {
        public IConfiguration Configuration 
        { 
            get; 
        }
        
        public Startup(IConfiguration configuration)
        {
            Configuration = configuration;
        }
        
        public void ConfigureServices(IServiceCollection services)
        {
            services.AddControllers();

            services.AddSingleton<JoomStore>();
            services.AddSingleton<AliexpressStore>();     
            services.AddSingleton<DefaultStore>();

            services.AddTransient<StoreFactory>(provider => key =>
            {
                IStore ResolveDecoratedStore<T>() where T : IStore
                {
                    var logger = provider.GetRequiredService<ILogger<T>>();
                    var store  = provider.GetRequiredService<T>();

                    return new StoreLogger<T>(store, logger);
                }

                switch (key)
                {
                    case "joom":
                        return ResolveDecoratedStore<JoomStore>();
                    
                    case "aliexpress":
                        return ResolveDecoratedStore<AliexpressStore>();
                        
                    default:
                        return provider.GetRequiredService<DefaultStore>();
                }
            });
        }

        public void Configure(IApplicationBuilder app, IWebHostEnvironment env)
        {
            if (env.IsDevelopment()) {
                app.UseDeveloperExceptionPage();
            }

            app.UseHttpsRedirection();
            app.UseRouting();
            app.UseAuthorization();

            app.UseCors(builder => 
            {
                builder.AllowAnyOrigin();
                builder.AllowAnyMethod();
                builder.AllowAnyHeader();
            });

            app.UseEndpoints(endpoints => 
            {
                endpoints.MapControllers();
            });

            app.UseFileServer();
        }
    }
}
