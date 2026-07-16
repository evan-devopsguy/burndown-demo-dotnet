# Build context is the repo root; CI is the only compiler (no SDK on the driving workstation).
# The modern SDK builds the legacy target; the runtime image is the EOL netcoreapp3.1 base.
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /repo
COPY nuget.config Directory.Packages.props ./
COPY packages/ packages/
COPY src/Contoso.Ledger.Api/ src/Contoso.Ledger.Api/
RUN dotnet publish src/Contoso.Ledger.Api -c Release -o /out

FROM mcr.microsoft.com/dotnet/aspnet:3.1
WORKDIR /app
COPY --from=build /out .
EXPOSE 80
ENTRYPOINT ["dotnet", "Contoso.Ledger.Api.dll"]
