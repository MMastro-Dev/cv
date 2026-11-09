# CV — Hugo Static Site

A minimalist, data-driven CV website built with [Hugo](https://gohugo.io/). Edit one YAML file, get a responsive website, an auto-generated PDF, and a library of job-tailored CV variants — all from a single `git push`.

---

## Features

- **Single source of truth** — all content lives in `assets/data/cv.yaml`; no HTML to touch for content edits
- **Tailored variant library** — generate company-specific CV pages at `/canonical-frontend/`, `/mc-engineering/`, etc., each from its own YAML
- **PDF download** — a download button on every page; CI/CD auto-generates a print-ready PDF via headless Chromium on every deploy
- **Accessibility** — WCAG 2.1 AA compliant (skip-link, `aria-labelledby`, `aria-hidden` icons, focus styles, 4.5:1 contrast)
- **Print-first design** — A4 layout, color accents by default, optional B&W output
- **No JavaScript** — pure HTML + CSS; zero client-side dependencies
- **AI skills** — GitHub Copilot agent skills for job fitness analysis and cross-variant syncing (see [AI Skills](#ai-skills))

---

## Prerequisites

| Tool | Version | Install |
|------|---------|---------|
| [Hugo Extended](https://gohugo.io/installation/) | ≥ 0.156 | `winget install Hugo.Hugo.Extended` |
| A modern browser | — | For local preview |
| Chromium / Chrome | Any | For local PDF generation only |

---

## Quick Start

```bash
# 1. Clone the repo
git clone <your-repo-url>
cd cv

# 2. Start the dev server
hugo server

# 3. Open http://localhost:1313 in your browser
```

Edit `assets/data/cv.yaml` — the browser reloads automatically.

---

## Project Structure

```
cv/
├── assets/
│   ├── css/
│   │   ├── main.css              # Screen stylesheet (BEM, CSS custom properties)
│   │   ├── print.css             # Preserved print/PDF layout (A4, B&W)
│   │   └── print-color.css       # Optional color-only print overrides
│   └── data/
│       ├── cv.yaml               # ← Canonical CV — always edit here first
│       ├── cv.canonical-frontend.yaml   # Tailored variant example
│       └── cv.mc-engineering.yaml       # Tailored variant example
├── content/
│   ├── canonical-frontend.md     # Variant page (front matter only)
│   └── mc-engineering.md         # Variant page (front matter only)
├── themes/cv-card/
│   └── layouts/
│       ├── index.html            # Home page → delegates to partial
│       ├── partials/
│       │   └── cv-body.html      # Shared CV rendering logic
│       └── _default/
│           ├── baseof.html       # HTML shell (head, skip-link, footer)
│           └── single.html       # Variant pages → delegates to partial
├── Dockerfile                # Multi-stage: Hugo build → nginx serve
├── docker-compose.yml        # Local preview and production deployment
├── nginx.conf                # nginx: clean URLs, headers, asset caching
├── .dockerignore             # Excludes .git, public/, resources/ from build
├── .gitea/workflows/deploy.yml   # CI/CD pipeline (Gitea Actions)
├── .github/
│   ├── copilot-instructions.md   # AI agent project context
│   └── skills/
│       ├── job-fitness-review/SKILL.md  # AI skill: job analysis
│       └── cv-variant-sync/SKILL.md     # AI skill: variant syncing
└── hugo.toml                     # Hugo configuration
```

---

## Editing Your CV

Open `assets/data/cv.yaml`. The file is structured into clear sections:

```yaml
personal:       # name, title, contact, summary
experience:     # employers, with nested `projects` for multi-client roles
education:      # degrees and diplomas
skills:         # grouped skill categories
languages:      # spoken languages with levels
certifications: # professional certifications
interests:      # personal interests
```

Each section is optional — Hugo's `{{ with }}` blocks hide empty sections automatically.

### Multi-client experience

If you worked for one employer across multiple clients (e.g. a consultancy), use the `projects` key:

```yaml
experience:
  - company: "Acme Consulting"
    period: "2020 — Present"
    projects:
      - client: "ClientCo — Project Name"
        role: "Frontend Developer"
        period: "2023 — Present"
        highlights:
          - "Built accessible UI components in React"
        tech: ["React", "TypeScript"]
```

Tech tags appear on screen only and are hidden in print.

---

## Build & Deploy

### Local build

```bash
hugo server          # Dev server with live reload at http://localhost:1313
hugo --gc --minify   # Production build → public/
```

### Docker (recommended for preview and deploy)

```bash
# Build and run locally
docker compose up --build
# → http://localhost:8080

# Build with your real domain (affects canonical URLs)
BASE_URL=https://cv.example.com docker compose up --build

# Build image manually
docker build --build-arg BASE_URL=https://cv.example.com -t cv .
```

The image is a two-stage build: `debian:bookworm-slim` installs Hugo Extended + Chromium, builds the site and generates `cv.pdf`; then `nginx:alpine` serves only the `public/` output. Final image size is ~25 MB.

### PDF generation (local)

```bash
hugo --gc --minify
chrome --headless --print-to-pdf=public/cv.pdf --no-pdf-header-footer public/index.html
```

The Docker build generates a separate `cv.pdf` beside every CV page, including `/cv-italian/cv.pdf`. PDF generation remains best-effort, with warnings identifying any failed page.

Color printing is enabled by `printColor = true` under `[params]` in `hugo.toml`. Set it to `false` to use the unchanged black-and-white stylesheet. Rebuild the Docker image to regenerate the downloadable PDF after changing print styles.

The PDF command suppresses browser-generated headers and footers, including the file path. For manual browser printing, disable **Headers and footers** in the print dialog, select **Color**, and enable **Background graphics** for colored tags.

### CI/CD (Gitea Actions)

Push to `main` and the pipeline (`.gitea/workflows/deploy.yml`) will automatically:

1. Build the Docker image (Hugo build + PDF generation baked in)
2. Push the image to your container registry
3. SSH to your server and run `docker pull` + `docker run --restart unless-stopped`

No web server config is required on the host — nginx runs inside the container on port 80.

#### Required secrets

Set these in **Gitea → Settings → Actions → Secrets**:

| Secret | Value |
|--------|-------|
| `REGISTRY_URL` | Container registry hostname, e.g. `gitea.example.com` |
| `REGISTRY_USER` | Registry username |
| `REGISTRY_TOKEN` | API token with `packages:read+write` scope |
| `SITE_URL` | Public URL of the site, e.g. `https://cv.example.com` |
| `DEPLOY_HOST` | Server hostname or IP |
| `DEPLOY_USER` | SSH username |
| `DEPLOY_KEY` | Private SSH key (ed25519 recommended) |

---

## CV Variant Library

Each company-specific CV is a separate YAML file (`assets/data/cv.{slug}.yaml`) paired with a one-line content page (`content/{slug}.md`).

### Adding a variant manually

1. Copy `assets/data/cv.yaml` to `assets/data/cv.{slug}.yaml`
2. Edit the summary, reorder skills, and adjust bullet points for the target role
3. Add a comment header identifying the role:
   ```yaml
   # Tailored to: Acme Corp / Senior Frontend Engineer
   ```
4. Create `content/{slug}.md`:
   ```markdown
   ---
   title: "CV — Acme Corp Senior Frontend Engineer"
   dataFile: "cv.acme-frontend"
   ---
   ```
5. Run `hugo --gc --minify` to verify it builds; the variant will be at `/{slug}/`

### Adding a variant with AI

Say something like: _"analyse this job description"_ — the **job-fitness-review** skill will score your CV, suggest improvements, and offer to generate the YAML + content page automatically. See [AI Skills](#ai-skills).

---

## Configuration

Edit `hugo.toml` to personalise the site metadata:

```toml
baseURL = 'https://your-domain.com/'
title   = 'CV — Your Name'

[params]
  description = 'Professional CV / Resume'
  author      = 'Your Name'
  printColor  = true
```

---

## AI Skills

This repo includes two [GitHub Copilot agent skills](https://code.visualstudio.com/docs/copilot/copilot-customization) that turn the AI assistant into an active job-search partner. They are defined in `.github/skills/` and are loaded automatically by Copilot when relevant trigger phrases are detected.

> **Requires**: VS Code with GitHub Copilot, agent mode enabled.

---

### `job-fitness-review` — Job Analysis & Tailored CV Generation

Acts as an experienced technical recruiter to analyse how well your CV matches a job posting, then optionally generates a tailored variant.

#### Trigger phrases
`job fitness` · `job description` · `ATS score` · `how do I match this role` · `keywords missing` · `compare these jobs` · `analyse this file`

#### What it does

**Single job mode** (paste one URL or job description text):
1. Scores CV compatibility (x/10) with strengths, partial matches and gaps
2. Produces a keyword matrix (Present ✓ / Partial ~ / Missing ✗)
3. Rewrites weak bullet points and suggests a new `summary` snippet
4. Re-scores after changes, checks ATS format and AI writing red flags
5. Offers to create `assets/data/cv.{slug}.yaml` + `content/{slug}.md` with improvements applied

**Batch mode** (paste a `.md` file with multiple jobs):
1. Parses all roles from the file
2. Produces a ranked comparison table (score, strengths, gaps, verdict)
3. Lists 3–5 CV edits that improve fit across all top roles simultaneously
4. Lets you pick which roles to generate tailored variants for

#### Batch file format

Create a `.md` file and attach it in chat:

```markdown
# Company Name

## Job Title

[Full job description text]

---

# Next Company

## Another Role

[Full job description text]
```

---

### `cv-variant-sync` — Propagate Base CV Changes to Variants

Keeps all tailored variants up to date after you edit `assets/data/cv.yaml`, while preserving each variant's specialised focus.

#### Trigger phrases
`sync variants` · `propagate changes` · `update all CVs` · `reflect changes` · `I changed cv.yaml`

#### What it does

1. Reads the base CV and every `cv.*.yaml` variant in parallel
2. Diffs them section by section (or uses your description of what changed)
3. Shows you the change list before touching any file
4. Applies smart propagation rules per section:
   - **Always synced**: contact info, education, languages, certifications
   - **Adapted, not overwritten**: summaries — new facts are woven in without replacing the variant's tailored framing
   - **Conditional**: new skills are only added if they fit the variant's narrative; skill ordering is never synced from base to variants
   - **Experience rewrites**: synced unless the variant already has a custom version of that bullet
5. Outputs a sync report (propagated / adapted / skipped with reasons)
6. Runs `hugo --gc --minify` to verify the build

#### Example workflow

```
You:   I added Docker to skills and updated my phone number in cv.yaml. Sync.
AI:    [reads all files, shows diff, propagates phone + Docker to all variants,
        skips Docker in the Canonical variant because it would dilute the
        open-source/Linux narrative — explains why, offers to override]
```

---

## Accessibility

The template meets WCAG 2.1 AA:

- Skip-to-content link at the top of every page
- All sections use `aria-labelledby` pointing to their `<h2>`
- Decorative SVG icons are `aria-hidden="true"`
- Focus styles via `focus-visible` (never removed)
- Colour contrast ≥ 4.5:1 throughout
- Greyscale-safe palette — prints cleanly in B&W

---

## Design Principles

- **No frameworks** — custom CSS only, BEM naming, CSS custom properties for theming
- **Inline CSS** — both stylesheets are inlined in `<head>` via Hugo's `readFile` for a single-request page load
- **No JavaScript** — zero runtime dependencies
- **Data over templates** — never put CV content in HTML; always in YAML

---

## License

MIT
