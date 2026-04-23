---
name: cv-variant-sync
description: "Propagate edits from the main cv.yaml to all tailored CV variants. Use when: you have modified cv.yaml and want to reflect those changes in company-specific variants; adding a new skill, certification or experience entry; updating contact details; refreshing bullet points; or after any structural change to the base CV. Triggers: 'sync variants', 'propagate changes', 'update all CVs', 'push to variants', 'reflect changes', 'update tailored CVs', 'I changed cv.yaml'."
argument-hint: "Describe what you changed in cv.yaml, OR just say 'sync' and the agent will auto-detect differences"
---

# CV Variant Sync

You are acting as a careful CV editor. Your job is to propagate edits from `assets/data/cv.yaml` (the canonical base CV) to all company-tailored variant files, while preserving each variant's specialised focus.

The guiding principle: **a change that belongs to the base CV should appear in a variant only if it strengthens — or at least does not dilute — that variant's tailored narrative.**

---

## Context

- **Base CV**: `assets/data/cv.yaml`
- **Variant files**: all files matching `assets/data/cv.*.yaml` **except** `assets/data/certifications-archive.yaml` — the archive is not a CV variant and must never be modified by this skill
- **Content pages**: matching `content/{slug}.md` files (these rarely need changes — only update if `title` changed)
- The variant's tailoring focus is declared in the comment header at the top of the file (line starting with `# Tailored to:`) and is also evident from differences in `summary`, skill ordering, and any variant-specific bullet rewrites

---

## Input handling

The user may provide:
- **Explicit description** of what changed: read the base CV for the new values, then proceed directly to the propagation decision for each variant
- **"Sync" / no description**: auto-detect by reading the base and each variant and diffing them section by section before proceeding

If no variant files exist yet, inform the user and stop.

---

## Workflow

### Step 1 — Read base and variants

Read `assets/data/cv.yaml` and all `assets/data/cv.*.yaml` files in parallel. For each variant, note its **tailoring focus** from the header comment.

### Step 2 — Identify changes

If the user described the changes, use that directly. Otherwise, compare each section of the base CV against each variant and list every discrepancy:

```
Section       | What changed in base
--------------|---------------------
personal      | …
summary       | …
experience    | added / modified entry …
skills        | added item "X" to category "Y"
certifications| added cert "Z"
…
```

Present this diff to the user before making any edits, so they can confirm or exclude specific changes.

### Step 3 — Propagation decision per variant

For each variant × each change, apply the following rules:

#### Always propagate (no judgement needed)
| Section | Rule |
|---------|------|
| `personal.*` | All fields — contact info is always universal |
| `education` | Always sync; it never conflicts with a tailored narrative |
| `languages` | Always sync |
| `certifications` | Sync unless the cert is clearly off-brand for the variant (e.g. a cloud cert in a Linux-systems variant is fine; an unrelated business cert in a deep-tech variant can be skipped — use judgement). When syncing a cert addition, also update `assets/data/certifications-archive.yaml`: add the entry with `status: active` if it is new, or update from `planned` to `active` if it was already in the archive. Never touch the `archived` entries. |
| `interests` | Sync; reorder only if an interest is particularly relevant to the variant's focus |

#### Propagate with adaptation
| Section | Rule |
|---------|------|
| `personal.title` | Sync only if the variant does not already have a more specific/targeted title |
| `personal.summary` | **Do not overwrite** the variant's summary with the base summary. Instead, check whether factual new content (e.g. a new technology added to the base summary) should be woven into the variant's summary. Adapt, don't replace |
| `skills` — new item added | Add to the variant **only if** the new skill is relevant to the variant's focus domain. If neutral, add. If it would dilute the variant's specialisation narrative, skip with a note |
| `skills` — item removed from base | Remove from variant only if also present in the variant (do not remove skills the variant added itself) |
| `skills` — reorder | **Do not sync** reordering from the base to a variant; each variant owns its skill ordering as part of its tailoring |

#### Evaluate per entry (experience)
| Change | Rule |
|--------|------|
| Bullet rewrite on existing entry present in both | Sync the rewrite — the variant can always benefit from stronger copy. Exception: if the variant already has a custom rewrite tuned for the role, keep the variant's version and note the conflict |
| New experience entry added to base | Add to variants — a new job is always relevant, regardless of focus |
| Bullet rewrite on entry present in base but not variant | N/A — nothing to sync |
| Tech tag change | Sync |

#### Never sync
- The variant's own custom summary (it was written for a specific role)
- Skill reordering from base to variants
- Any change that was already handled differently in the variant as part of its original tailoring (identified by comparing the variant's field value vs the old base value)

### Step 4 — Apply and report

For each variant, make all approved changes. After completing all edits, produce a sync report:

```
## Sync Report

### cv.canonical-frontend.yaml
✅ Propagated: personal.phone, skills > Languages > added "Rust", certifications > added "LFC132"
⚠️  Adapted:   summary — new "Rust" mention woven in without overwriting Canonical-specific framing
⏭️  Skipped:   skills > "SQL" deprioritised in base (kept in variant; SQL is relevant to Canonical backend work)

### cv.mc-engineering.yaml
✅ Propagated: …
⏭️  Skipped:   …
```

If any decision was a close call, explain the reasoning in a note.

### Step 5 — Verify build

After all edits, run:
```bash
hugo --gc --minify
```

Report the page count and confirm there are no errors. If there are errors, diagnose and fix before finishing.

---

## Tone

Precise and transparent. Always explain skip decisions so the user can override them if they disagree.
