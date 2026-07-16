# NU1605 lab: fix one CVE, break the builds

`Contoso.Common` bumped `Newtonsoft.Json` 12.0.1 → 13.0.3 (the CVE fix).
Every project referencing it still pins an older version, and NuGet treats a
detected downgrade (NU1605) as an error by default — so the security fix breaks
restore across the solution:

- `Contoso.Billing.Api` pins 12.0.1 ("for stability", 2020)
- `Contoso.Billing.Tests` pins 11.0.2 (copy-pasted at project creation)

Reproduce (CI runs the same thing and asserts the failure):

```bash
docker run --rm -v "$PWD":/repo -w /repo/labs/nu1605 mcr.microsoft.com/dotnet/sdk:8.0 \
  dotnet restore Contoso.Billing.Api
```

The fix shown on camera: delete the stale pins and let the floor rise — or move
the whole solution to central package management so the next bump is one line.
