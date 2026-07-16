# Maptek Geo Suite — JFrog Release Bundles Demo Script

**Audience**: New to JFrog Artifactory
**Duration**: ~45 minutes
**Instance**: https://hts1.jfrog.io
**Repo**: https://github.com/cecillesc-jfrog/maptek-rb-demo

---

## Pre-flight Checklist

Before starting the demo, confirm:
- [ ] Browser logged into hts1.jfrog.io as `cecillesc@jfrog.com`
- [ ] Terminal open at `/Users/cecillesc/maptek-rb-demo`
- [ ] `export TOKEN="<current-token>"` set in terminal
- [ ] `infographic.html` open in a browser tab
- [ ] GitHub Actions tab open: `cecillesc-jfrog/maptek-rb-demo/actions`
- [ ] Three release bundles exist: `2026.demo.1`, `2026.demo.2`, `2026.hotfix.1`

---

## Part 1 — Concepts (5 min)

**Open `demo/infographic.html` in browser**

Walk through each section of the infographic:

### What is Artifactory?
> "Artifactory is a universal artifact repository — it stores every binary your teams produce. Docker images, Python packages, Java JARs, Helm charts — all in one place, with consistent metadata and access control."

### What is a Repository?
> "Artifacts live in repositories. For Maptek we have `maptek-docker-local` — a local Docker repository where CI pushes all 5 microservices."

### What are Properties?
> "Every artifact can have key=value properties attached to it — think of them as searchable tags. These are not just labels — they power filtering, policy enforcement, and lifecycle decisions."

### What is a Release Bundle?
> "A Release Bundle is a versioned, signed collection of artifacts. It is the unit of promotion — you don't promote individual artifacts, you promote a bundle. It is cryptographically signed, so you know exactly what is in it and that it hasn't been tampered with."

### Dual Tagging
> "One of the most powerful patterns is dual tagging. Each artifact carries its own metadata — which team owns it, what type of service it is. The bundle also adds collective metadata — `rb.project`, `rb.build_type`, `rb.pipeline`. Together, you can answer questions like: 'give me all platform team artifacts from any release bundle created by GitHub Actions'."

---

## Part 2 — The Artifacts in Artifactory UI (8 min)

**Navigate to**: `hts1.jfrog.io` → **Artifactory** → **Artifacts**

### Browse the repository
1. Expand `maptek-docker-local`
2. Show the 5 service folders: `geo-api`, `auth-service`, `data-processor`, `visualizer`, `report-generator`
3. Expand `geo-api` → `2026.demo.1` → click `manifest.json`

> "This is a Docker image manifest — the top-level descriptor for the geo-api image. Let's look at its properties."

### Show artifact properties
4. Click the **Properties** tab on the manifest.json detail panel

Point out each property group:
- `project.name`, `project.version` → identifies the logical build
- `build.type` → release / snapshot / hotfix
- `component.name`, `component.team`, `component.service_type` → who owns it and what it does
- `git.commit`, `build.number` → traceability back to the CI run
- `rb.project`, `rb.build_type`, `rb.pipeline` → collective/bundle-level metadata

> "Notice we have two categories of properties here. The `component.*` ones describe this specific artifact — the geo-api microservice. The `rb.*` ones describe the bundle it belongs to. This dual-tagging is what makes the cross-filtering powerful."

### Compare with auth-service
5. Navigate to `auth-service/2026.demo.1/manifest.json` → Properties

> "Same `rb.*` properties, but different `component.team` — platform, and `component.service_type` — security. So the operations team can query just their slice of any release."

---

## Part 3 — GitHub Actions Workflow (7 min)

**Open browser**: `github.com/cecillesc-jfrog/maptek-rb-demo/actions`

### Show the workflow file
1. Click the latest successful run
2. Show the two-job structure: **Tag artifacts** (5 parallel) and **Create Release Bundle**

> "The workflow has two jobs. The first runs in parallel across all 5 services — each one tags its own manifest.json with `jf rt sp`. They all run simultaneously, which is why you see 5 jobs."

### Walk through the tagging step
3. Click on the **Tag — geo-api** job
4. Expand **Tag geo-api — per-artifact metadata**

> "This is the `jf rt sp` command — set properties. It stamps 11 properties onto the manifest.json in one shot. The path includes `ARTIFACT_VERSION` which is always `2026.demo.1` — the actual location in the repo."

### Walk through bundle creation
5. Click **Create Release Bundle** job
6. Expand **AQL — verify tagged artifacts**

> "Before creating the bundle, we do a dry-run AQL search to confirm all 5 manifests were successfully tagged. You can see `Found 5 artifacts`."

7. Expand **Write AQL bundle spec**

> "The bundle spec uses an AQL query to define its contents — not a hard-coded list of paths. Whatever the AQL finds gets bundled. This is the recommended pattern — metadata-driven bundling."

8. Expand **Create Release Bundle v2 and tag**

> "Two commands in one step: `jf rbc` creates and signs the bundle, then `jf rba` immediately annotates it with the `QA-Passed` tag. The signing key is `default-lifecycle-key`."

### Show how to trigger a new bundle
9. Click **Run workflow** → show the three inputs

> "We can create multiple bundles from the same artifacts just by changing the `version` and `build_type` inputs. The `artifact_version` always stays `2026.demo.1` — that's where the actual Docker images live."

---

## Part 4 — AQL Queries in Terminal (10 min)

**Switch to terminal** at `/Users/cecillesc/maptek-rb-demo`

> "AQL is a query language built into Artifactory. We run these queries directly against the REST API. Let me show you the 5 use cases we've built for Maptek."

### Script 01 — Find a specific build
```bash
curl -s -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: text/plain" \
  -XPOST "https://hts1.jfrog.io/artifactory/api/search/aql" \
  --data-binary @scripts/aql/01-find-by-project-version.aql | jq '[.results[] | {path}]'
```

> "This answers: 'find build 2026.demo.2 for project maptek-geo-suite'. Returns all 5 manifests tagged with that version."

### Script 02 — All release builds since a date
```bash
curl -s -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: text/plain" \
  -XPOST "https://hts1.jfrog.io/artifactory/api/search/aql" \
  --data-binary @scripts/aql/02-find-release-builds-since-date.aql | jq '[.results[] | {path, created}]'
```

> "This answers: 'show me all release builds since July 16th'. Note it only returns artifacts where `build.type=release` — not snapshots, not hotfixes."

### Script 03 — Filter by team
```bash
curl -s -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: text/plain" \
  -XPOST "https://hts1.jfrog.io/artifactory/api/search/aql" \
  --data-binary @scripts/aql/03-find-by-team-or-type.aql | jq '[.results[] | {path}]'
```

> "This returns only the `platform` team artifacts — geo-api and auth-service. An ops team can query their own slice without knowing the full bundle structure."

### Script 05 — Cross-filter
```bash
curl -s -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: text/plain" \
  -XPOST "https://hts1.jfrog.io/artifactory/api/search/aql" \
  --data-binary @scripts/aql/05-cross-filter-bundle-and-artifact.aql | jq '[.results[] | {path}]'
```

> "This is the dual-tagging use case in action. We're combining `rb.pipeline=github-actions` — a collective/bundle property — with `component.team=platform` — a per-artifact property. Returns only the platform artifacts from GitHub Actions pipelines."

### Script 06 — Find bundles by tag
```bash
bash scripts/06-find-by-release-bundle-tag.sh
```

> "Release Bundle tags are stored in the JFrog Lifecycle service, not in Artifactory's property system — so we use the Lifecycle REST API here, not AQL. This returns all 3 bundles tagged `QA-Passed`."

---

## Part 5 — Release Bundles in the UI (8 min)

**Navigate to**: `hts1.jfrog.io` → **Artifactory** → **Release Lifecycle**

### Show all bundles
1. You should see `maptek-geo-suite` listed with 3 versions

> "These are our three bundles — `2026.demo.1`, `2026.demo.2`, and `2026.hotfix.1`. Each was created by the same GitHub Actions workflow with different inputs."

### Inspect a bundle
2. Click `maptek-geo-suite` → `2026.demo.2`

Point out:
- **Status**: COMPLETED / PRE_RELEASE
- **Signed by**: default-lifecycle-key
- **Tag**: QA-Passed
- **Created by**: cecillesc@jfrog.com

> "The bundle is immutable and signed. The `QA-Passed` tag was added by `jf rba` immediately after creation in the pipeline."

3. Click the **Artifacts** tab

> "Here are the 5 manifests that make up this bundle. Each one carries all the properties we set in the pipeline."

4. Click on `geo-api/2026.demo.1/manifest.json`

> "Clicking an artifact from within the bundle takes us directly to its properties — you can see both the per-artifact and the rb.* collective properties side by side."

### Show the hotfix bundle
5. Navigate back and open `2026.hotfix.1`

> "This is the hotfix bundle. Notice the `rb.build_type=hotfix` property on the artifacts. Script 02 filters by `build.type=release` so this bundle's artifacts would NOT appear in that query — only the release bundles do."

---

## Part 6 — Create a Release Bundle from the UI (5 min)

> "Let's see how you'd create a Release Bundle manually from the UI — the same thing our pipeline does automatically."

1. In Release Lifecycle, click **+ New Release Bundle**
2. Enter:
   - **Name**: `maptek-geo-suite`
   - **Version**: `2026.ui-demo.1`
3. Click **Add Artifacts**
4. Choose **Query** method → enter AQL:

```
items.find({
  "@project.name": {"$eq": "maptek-geo-suite"},
  "repo": {"$match": "maptek-docker-local"}
})
```

5. Show the preview — 5 artifacts appear
6. Select signing key: `default-lifecycle-key`
7. Click **Create**

> "The UI gives you the same AQL-driven approach as the CLI. You define what goes in the bundle by querying on metadata, not by picking files manually. This is the power of property-driven workflows."

---

## Part 7 — Xray Security Scanning (5 min)

**Navigate to**: The bundle detail page → **Security** tab (or **Xray** tab)

> "JFrog Xray is integrated directly with Release Bundles. Every artifact in the bundle has been scanned for known CVEs."

### Walk through the security results
1. Show the vulnerability breakdown by severity (Critical / High / Medium / Low)

> "Xray does deep recursive scanning — it doesn't just look at the top-level image, it scans every layer, every dependency inside the container."

2. Click on a CVE to show the detail panel

> "For each vulnerability you get the CVE ID, affected package, fixed version, and a severity score. Xray also does contextual analysis — it can tell you whether a vulnerability is actually reachable in your code."

3. Show the **Licenses** tab if available

> "Xray also checks license compliance — making sure you're not shipping a GPL library inside a commercial product, for example."

### Policy enforcement
> "You can configure Xray policies that automatically block a Release Bundle from being promoted if it has Critical CVEs. This creates a quality gate in your pipeline — you can't promote to PROD if security hasn't signed off."

---

## Summary & Q&A (2 min)

Bring up the infographic **Section 8 — Summary** panel.

> "To summarise what we've seen today:
>
> **Tag every artifact** — rich metadata on each individual service so it's always discoverable and filterable.
>
> **Bundle and sign** — group those tagged artifacts into a signed Release Bundle. Immutable, traceable, the unit of delivery.
>
> **Query anything** — AQL lets Maptek find any build by version, date, team, or pipeline — cross-filtering across both per-artifact and collective metadata.
>
> **Promote safely** — Xray scans at every stage, policies block bad bundles, lifecycle promotion ensures only approved artifacts reach production."

---

## Key Commands Reference

```bash
# Tag an artifact with properties
jf rt sp "repo/path/manifest.json" "key1=val1;key2=val2"

# Create a Release Bundle from an AQL spec
jf rbc --spec=rb-spec.json --signing-key="default-lifecycle-key" "bundle-name" "version"

# Annotate a bundle with a tag
jf rba --tag="QA-Passed" "bundle-name" "version"

# Promote a bundle to an environment
jf rbp --signing-key="default-lifecycle-key" "bundle-name" "version" STAGING

# Search artifacts by property
jf rt search --props "project.name=maptek-geo-suite;build.type=release" "repo/**"

# Find bundles by tag (Lifecycle API)
curl -H "Authorization: Bearer $TOKEN" \
  "https://hts1.jfrog.io/lifecycle/api/v2/release_bundle/records/maptek-geo-suite?tag=QA-Passed"

# Run an AQL script
curl -s -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: text/plain" \
  -XPOST "https://hts1.jfrog.io/artifactory/api/search/aql" \
  --data-binary @scripts/aql/01-find-by-project-version.aql | jq .
```

---

## Troubleshooting

| Issue | Fix |
|---|---|
| 401 Token expired | Generate new token at hts1.jfrog.io → Profile → Identity Token. Update `$TOKEN` and GitHub secret. |
| AQL parse error | AQL does not support any comments (`//` or `/* */`). Queries must be bare. |
| `jf rbc` source not found | `artifact_version` input must be `2026.demo.1` — the actual path in the repo. |
| Runner not picking up jobs | Check `pgrep Runner.Listener` on cecillesc-mac. Start with `~/actions-runner/run.sh`. |
| 403 on `jf rt sp` | Transient Artifactory error. Re-run the failed job with `gh run rerun <id> --failed`. |
