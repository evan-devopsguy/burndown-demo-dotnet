# Build context is the repo root; CI is the only compiler (no SDK on the driving workstation).
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /repo
COPY nuget.config Directory.Packages.props ./
COPY packages/ packages/
COPY src/Contoso.Inventory.Api/ src/Contoso.Inventory.Api/
RUN dotnet publish src/Contoso.Inventory.Api -c Release -o /out

FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app
COPY --from=build /out .
EXPOSE 8080
ENTRYPOINT ["dotnet", "Contoso.Inventory.Api.dll"]
