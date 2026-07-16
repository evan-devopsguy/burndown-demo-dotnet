using Contoso.Platform;

var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

var platform = new PlatformClient("orders-api");

app.MapGet("/", () => Results.Content(platform.DescribeService(), "application/json"));
app.MapGet("/healthz", () => Results.Ok("ok"));

app.Run();
