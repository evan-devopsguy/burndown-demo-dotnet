#!/usr/bin/env python3
"""Fleet report: compare the manifest view against the shipped-DLL view per image.

Reads scan-results/<image>-manifest.json (grype, manifest-trusting SBOM) and
<image>-shipped.json (trivy, default DLL-verifying mode) and prints a markdown
table. Phantom findings appear only in the manifest column; real ones survive
into the shipped column.
"""
import json
import sys
from pathlib import Path

SEV_ORDER = ["CRITICAL", "HIGH", "MEDIUM", "LOW"]


def sev_counts_to_str(counts):
    parts = [f"{counts[s]} {s.title()}" for s in SEV_ORDER if counts.get(s)]
    return ", ".join(parts) if parts else "clean"


def manifest_findings(path):
    data = json.loads(path.read_text())
    counts = {}
    for match in data.get("matches", []):
        if match["artifact"].get("type") != "dotnet":
            continue
        sev = (match["vulnerability"].get("severity") or "UNKNOWN").upper()
        counts[sev] = counts.get(sev, 0) + 1
    return counts


def shipped_findings(path):
    data = json.loads(path.read_text())
    app_counts, os_counts = {}, {}
    for result in data.get("Results", []):
        vulns = result.get("Vulnerabilities") or []
        bucket = app_counts if result.get("Type") == "dotnet-core" else os_counts
        for vuln in vulns:
            sev = (vuln.get("Severity") or "UNKNOWN").upper()
            bucket[sev] = bucket.get(sev, 0) + 1
    return app_counts, os_counts


def main(results_dir):
    results = Path(results_dir)
    rows = []
    for manifest_path in sorted(results.glob("*-manifest.json")):
        image = manifest_path.name[: -len("-manifest.json")]
        shipped_path = results / f"{image}-shipped.json"
        if not shipped_path.exists():
            continue
        manifest = manifest_findings(manifest_path)
        shipped_app, shipped_os = shipped_findings(shipped_path)
        os_serious = sum(shipped_os.get(s, 0) for s in ("CRITICAL", "HIGH"))
        verdict = "PHANTOM — nothing vulnerable ships" if manifest and not shipped_app else (
            "REAL — fix this one" if shipped_app else "clean")
        rows.append((image.replace("_", ":"), manifest, shipped_app, os_serious, verdict))

    print("| Image | Manifest view (deps.json) | Shipped-DLL view | Base-image Crit/High | Verdict |")
    print("|---|---|---|---|---|")
    for image, manifest, shipped_app, os_serious, verdict in rows:
        print(f"| {image} | {sev_counts_to_str(manifest)} | {sev_counts_to_str(shipped_app)} | {os_serious} | {verdict} |")

    total_manifest = sum(sum(m.values()) for _, m, _, _, _ in rows)
    real_images = [image for image, _, shipped_app, _, _ in rows if shipped_app]
    print()
    print(f"Manifest view total: **{total_manifest} app-level findings across {len(rows)} images**.")
    print(f"Images that actually ship a vulnerable DLL: **{len(real_images)}** ({', '.join(real_images) or 'none'}).")


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "scan-results")
