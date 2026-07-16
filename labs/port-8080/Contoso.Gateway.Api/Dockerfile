# The hardening upgrade: .NET 8 base + non-root USER app.
# .NET 8 images also moved the default listen port from 80 to 8080 —
# but the healthcheck below (standing in for an ALB target group) still
# probes port 80. Container runs fine and reports unhealthy forever.
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /repo
COPY . .
RUN dotnet publish Contoso.Gateway.Api -c Release -o /out

FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app
COPY --from=build /out .
USER app
EXPOSE 8080
# The stale "target group": still probing the pre-.NET-8 port.
HEALTHCHECK --interval=5s --timeout=2s --retries=3 \
  CMD bash -c 'exec 3<>/dev/tcp/localhost/80' || exit 1
ENTRYPOINT ["dotnet", "Contoso.Gateway.Api.dll"]
