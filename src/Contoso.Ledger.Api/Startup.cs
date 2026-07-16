using Contoso.Platform;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.DependencyInjection;
using Newtonsoft.Json;

namespace Contoso.Ledger.Api
{
    public class Startup
    {
        public void ConfigureServices(IServiceCollection services)
        {
            services.AddRouting();
        }

        public void Configure(IApplicationBuilder app)
        {
            var platform = new PlatformClient("ledger-api");

            app.UseRouting();
            app.UseEndpoints(endpoints =>
            {
                endpoints.MapGet("/", async context =>
                {
                    context.Response.ContentType = "application/json";
                    await context.Response.WriteAsync(
                        JsonConvert.SerializeObject(new { service = platform.ServiceName, engine = "ledger-v1" }));
                });

                endpoints.MapGet("/healthz", async context => await context.Response.WriteAsync("ok"));
            });
        }
    }
}
