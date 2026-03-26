# CV Website — Copilot Instructions

## Project Overview
This is a **Hugo static site** that renders a professional CV from a single YAML data file. The site is designed with a minimalist business-card aesthetic, accessibility compliance (WCAG 2.1 AA), and clean black-and-white print output.

## Architecture

| Path | Purpose |
|------|---------|
| `assets/data/cv.yaml` | **All CV content** — edit this file to update the CV |
| `assets/css/main.css` | Screen stylesheet (CSS custom properties, BEM naming) |
| `assets/css/print.css` | Print/PDF stylesheet (A4 optimised, B&W safe) |
| `themes/cv-card/layouts/index.html` | Main template that renders `cv.yaml` data |
| `themes/cv-card/layouts/_default/baseof.html` | Base HTML shell (head, skip-link, footer) |
| `hugo.toml` | Hugo configuration |
| `.github/workflows/deploy.yml` | CI/CD: build → PDF → deploy via rsync |

## Key Conventions

- **Data-driven**: CV content lives exclusively in `assets/data/cv.yaml`. Templates should never contain hardcoded CV text.
- **Single-page site**: There is only one page (`index.html`). Hugo taxonomies and sections are disabled.
- **CSS methodology**: BEM naming (`block__element`), CSS custom properties for theming. No CSS frameworks.
- **Accessibility**: All sections use `aria-labelledby`, icons are `aria-hidden`, a skip-link is present, focus styles use `outline`, and colour contrast meets WCAG AA (4.5:1 minimum).
- **Print-first colour choices**: The palette is intentionally neutral/greyscale so the CV retains its character when printed in B&W. Avoid introducing colours that don't degrade well to greyscale.
- **No JavaScript**: The site is pure HTML + CSS. Do not add JS unless explicitly requested.
- **Inline styles**: CSS is inlined via Hugo's `readFile` for single-request page loads. Do not use `<link>` stylesheet references.

## How to Edit the CV
1. Open `assets/data/cv.yaml`
2. Edit any section (personal, experience, education, skills, languages, certifications, interests)
3. Run `hugo server` to preview, or push to `main` to trigger CI/CD

## Build Commands
```bash
hugo server          # Local dev server with live reload
hugo --gc --minify   # Production build → public/
```

## PDF Generation
The CI/CD pipeline generates a PDF using headless Chrome (`--print-to-pdf`). Locally you can do:
```bash
hugo --gc --minify
chrome --headless --print-to-pdf=public/cv.pdf --print-to-pdf-no-header public/index.html
```
The print CSS (`assets/css/print.css`) controls PDF layout: A4 page size, 15mm/18mm margins, hidden footer, and URL expansion for links.

## Deployment
The GitHub Actions workflow deploys via rsync over SSH. Required repository secrets:
- `DEPLOY_HOST` — server hostname or IP
- `DEPLOY_USER` — SSH username
- `DEPLOY_KEY` — private SSH key
- `DEPLOY_PATH` — remote directory (e.g. `/var/www/cv`)

## When Modifying Templates
- Keep the semantic HTML structure: `<header>`, `<section>`, `<article>`, `<dl>` for skills
- Every `<section>` must have an `aria-labelledby` pointing to its `<h2>` id
- Test both screen and print rendering after changes
- Run `hugo --gc --minify` to verify there are no build warnings
