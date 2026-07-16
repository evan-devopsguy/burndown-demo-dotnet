# burndown-demo-dotnet

> **⚠️ Deliberately vulnerable demo environment.** This repo exists to be scanned on camera
> for the [Burndown](https://github.com/evan-devopsguy/burndown) YouTube channel about
> large-scale vulnerability remediation with Claude Code. Everything in it — the frozen
> SDK, the pinned packages, the EOL runtime — is vulnerable **on purpose**. Do not deploy
> any of it anywhere that matters. "Contoso" is a fictional company.

## The scenario: phantom findings

A scanner looks at this fleet and reports a wall of critical/high findings across every
service. The real number of services that need fixing is **one**.

The mechanism:

- `Contoso.Platform.Sdk` is an internal NuGet package frozen at **1.4.2 (2019-era)**.
  The platform team that owned it was disbanded; every service still pins it.
- It declares 2019-era dependencies — `System.Net.Http 4.3.0`, `System.Text.RegularExpressions 4.3.0`,
  `System.Text.Encodings.Web 4.5.0` — each carrying a known high/critical advisory.
- Every consuming service records those packages in its published **`deps.json`** manifest.
  But on .NET 8, all three assemblies come from the **shared framework** (already patched);
  the vulnerable DLLs **never ship** in the image. A scanner that trusts the manifest flags
  every service anyway. Those are the phantoms.
- `Contoso.Ledger.Api` is the exception: still on **netcoreapp3.1** (EOL runtime, EOL
  debian 10 base) and pinning `Newtonsoft.Json 12.0.1`, whose vulnerable DLL genuinely
  ships in the image. That's the one real fix.

## Reproduce it

Requires Docker only — the scanners and the .NET SDK all run as pinned containers.

```bash
./scripts/scan-fleet.sh
```

This builds all nine images and scans each one twice:

| View | Tooling | What it believes |
|---|---|---|
| **Manifest view** | syft (`scanners/syft-manifest-trusting.yaml`) → grype | Every library named in `deps.json` — how manifest-believing scanners (including several commercial platforms) see a .NET image |
| **Shipped-DLL view** | trivy, default settings | Only libraries whose DLLs actually ship |

The closing report shows the wall of findings on the left and the single real offender on
the right. Interesting wrinkle: modern OSS scanners (trivy ≥0.5x, syft/grype current
defaults) have specifically engineered this false-positive class away by verifying that a
DLL ships before reporting it — the manifest-trusting config exists to reproduce what
less careful scanners still report.

The restore logs tell the same story from the build side: NuGet's own audit (`NU1903`/`NU1904`)
warns about all three frozen pins on every build.

## Repo conventions

- **Central package management** — versions live in `Directory.Packages.props`, not in
  csproj files. The one real fix (bumping Newtonsoft.Json) is a one-line diff that heals
  every consumer at once.
- **CI is the only compiler** — no workstation builds this code; `dotnet publish` happens
  inside the Docker build, and the validation build in `.github/workflows/validate.yml`
  is the gate. There is deliberately no local-SDK workflow.
- **The "internal feed"** — `packages/` is a checked-in folder NuGet source holding the
  frozen `Contoso.Platform.Sdk.1.4.2.nupkg` artifact, so the 2019 pin reproduces exactly
  without a real private feed. Its source lives in `sdk/` for reference; the artifact is
  what the fleet consumes.

## Layout

```
sdk/Contoso.Platform.Sdk/    source of the frozen internal SDK (netstandard2.0, v1.4.2)
packages/                    the "internal feed": the frozen .nupkg artifact
src/Contoso.*.Api/           8 tiny net8.0 services, all consuming the SDK (the phantoms)
src/Contoso.Ledger.Api/      the netcoreapp3.1 straggler (the real fix)
scanners/                    the manifest-trusting syft config
scripts/                     build + dual-view scan + fleet report
.github/workflows/           per-service validation builds + fleet report summary
```

## Labs

Self-contained side scenarios for other episodes, excluded from the fleet scan:

- `labs/nu1605/` — fix one CVE, break the builds: a library bumps Newtonsoft.Json and every stale per-project pin fails restore with NU1605. CI asserts the failure.
- `labs/port-8080/` — the non-root hardening fix that failed every healthcheck: .NET 8 + `USER app` listens on 8080 while the probe checks 80, and the same `USER app` line on an aspnet:6.0 base won't start at all (`./labs/port-8080/demo.sh`).

Scanner versions are pinned in `scripts/scan-image.sh` (syft v1.46.0, grype v0.115.0,
trivy 0.72.0) so the demo reproduces; advisory databases update over time, so exact
counts may drift while the phantom-vs-real split stays put.
