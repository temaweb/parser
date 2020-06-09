using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;

namespace Malachite.Parser.WebApi
{
    public class Startup
    {
        public Startup(IConfiguration configuration)
        {
            Configuration = configuration;
        }

        public IConfiguration Configuration 
        { 
            get; 
        }

        public void ConfigureServices(IServiceCollection services)
        {
            services.AddControllers();

            services.AddTransient<JoomStore>();
            services.AddTransient<AliexpressStore>();
            services.AddTransient<DefaultStore>();

            services.AddTransient<StoreFactory>(serviceProvider => key =>
            {
                switch (key)
                {
                    case "joom.com":
                    case "www.joom.com":
                        return serviceProvider.GetService<JoomStore>();
                    
                    case "aliexpress.ru":
                    case "aliexpress.com":
                        return serviceProvider.GetService<AliexpressStore>();
                        
                    default:
                        return serviceProvider.GetService<DefaultStore>();
                }
            });
        }

        public void Configure(IApplicationBuilder app, IWebHostEnvironment env)
        {
            if (env.IsDevelopment()){
                app.UseDeveloperExceptionPage();
            }

            app.UseHttpsRedirection();
            app.UseRouting();
            app.UseAuthorization();

            app.UseEndpoints(endpoints => 
            {
                endpoints.MapControllers();
            });
        }
    }
}
