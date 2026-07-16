using Contoso.Common;

var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

app.MapGet("/", () => Results.Content(Envelope.Wrap("billing-api", new { status = "ok" }), "application/json"));

app.Run();
