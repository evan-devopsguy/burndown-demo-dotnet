using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Hosting;

namespace Contoso.Ledger.Api
{
    public static class Program
    {
        public static void Main(string[] args) =>
            Host.CreateDefaultBuilder(args)
                .ConfigureWebHostDefaults(web => web.UseStartup<Startup>())
                .Build()
                .Run();
    }
}
