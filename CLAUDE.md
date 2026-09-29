# CLAUDE.md

Guidance for working in this repository. It records conventions and decisions
that are not obvious from the code or git history.

## What this repo is

Task-level timing data from manual pit latrine emptying in Mzuzu, Malawi,
collected with the Gulper Timer app, analysed with time-driven activity-based
costing (TDABC). The research questions are in `questions.md`. Each question is
answered by a self-contained Quarto manuscript that renders to DOCX.

## Layout

- `data/all_tasks.csv`: the raw app export. **Never edit it.**
- `data/all_tasks_clean.csv`: the cleaned file every analysis reads. Produced
  by `Rscript data-review/clean.R` from the repo root. Extra columns: `date`,
  `session`, `flags` (semicolon-separated: `long_entry`, `long_gap_before`,
  `timer_suspect`), `job_id_raw`, `entry_number_raw`.
- `data-review/`: `review.R` flags problems in the raw file; `clean.R` resolves
  them; `README.md` documents both, including the job-identity decisions and a
  list of items only field notes can settle (tracked as issue #7).
- `analysis/q1-total-job-time/`, `analysis/q2-travel-time/`: one Quarto
  manuscript project per question. `analysis/final-manuscript/` merges them.
- `prompts/`: archive of the prompts behind Claude-assisted commits, written by
  the commit skill. One file per prompt, `YYYY-MM-DD-NNN-slug.md`.

## Adding an analysis for a new question

1. Write a plan first and save it in the repo as `analysis/qN-<slug>/plan.md`.
   The user wants plans kept in the repo, not only in the Claude plan file.
2. Copy `_quarto.yml`, `.gitignore` and `references.bib` from an existing
   project. Keep `project: render: [index.qmd]` so `plan.md` is not rendered.
3. Read `../../data/all_tasks_clean.csv`. Reuse the setup pattern from
   `analysis/final-manuscript/index.qmd`: the `fmt()` helper, the `jobs` table
   with labour and elapsed hours, the `job_label` column, and `bar_theme()`.
4. Sections: Introduction (question in bold), Data and methods, Results,
   Conclusion, Appendix with a job-level table, Appendix with the five Zotero
   references, References. All numbers in prose via inline R, never typed.
5. Commit the rendered `_manuscript/index.docx` and `_freeze/` with the source.

## Definitions already settled (do not re-litigate)

- **Labour time** = sum of `duration_seconds` in person-hours (the TDABC
  measure). **Elapsed time** = first start to last end per job and day, in
  clock hours. Report both; say which leads.
- **Jobs** are identified by the cleaned `job_id`. There are 36. One job
  (`2026-06-12_01`) spans two days; `2026-06-14_02a` and `_02b` are two jobs
  that shared a raw ID. In tables and figures label jobs by date, numbered
  "(1)" and "(2)" where two jobs share a day. Never show raw IDs with an
  underscore suffix in reader-facing output.
- **Travel to the disposal site** (question 2) means the subtask
  `Travel to disposal site` only. Errands are excluded. Overlapping entries
  from gulpers travelling together are merged into one trip; merged intervals
  under 5 minutes are accidental taps and dropped. The population is the jobs
  with at least one trip. Headline is clock hours per job, person-hours second.
- Long entries and gaps are kept as recorded and carried as flags. Do not cap
  or drop them without the user's say; report a sensitivity check instead.

## Style

- Figures: `theme_minimal(base_size = 10)`, bars in `#2a78d6`, text in
  `#52514e`, dashed mean line with a label, no legend for a single series.
  Task groups use `#2a78d6`, `#eb6834`, `#1baf7a`, `#4a3aa7`.
- Tables: `knitr::kable(digits = 1)`. Count columns as character so a Mean or
  Median row can show one decimal. Blank, not NA, for missing cells.
- Prose wraps at 72 columns (`editor: markdown: wrap: 72` in the YAML).

## Rendering

`quarto` is not on PATH. Use
`/Applications/RStudio.app/Contents/Resources/app/quarto/bin/quarto render`
inside the project folder. Pandoc is at
`.../quarto/bin/tools/aarch64/pandoc`; `pandoc file.docx -t plain --wrap=none`
is the quickest way to check numbers in a rendered DOCX. Caption labels in the
DOCX contain a non-breaking space ("Table 1:"), so grep for them tolerantly.
Re-rendering changes the DOCX binary even when content is unchanged; restore it
with `git checkout` if it was not meant to change.

## Git workflow

- Work on `dev`. Pull requests go from `dev` into `main` only, opened with the
  `ghe-skills:open-pr` skill. Merge with a merge commit.
- Commit with the `ghe-skills:commit` skill. It detects whether the diff is
  Claude-assisted, human-only or mixed. Claude runs Claude-assisted commits;
  the user runs any commit carrying `Human-authored: true` from
  `.git/CLAUDE_COMMIT_MSG`. Trailers are `Prompts:`, then `Closes #N`, then
  `Human-authored: true`, then `Assisted-by: Claude <model-id>`. Never add
  `Co-Authored-By: Claude`.
- Conventional Commits: `feat(analysis)`, `feat(data)`, `docs(data)`,
  `fix(analysis)`, `chore`. Bodies state the key numbers.
- Leave the user's own files alone: `.Rhistory`, `*.Rproj`, rendered
  `*.html`, and their `.gitignore` edits.
- Closing keywords in commits only close issues on merge to `main`; close
  issues explicitly with `gh issue close` when the user asks.

## Open items

- Issue #7: field verification of flagged entries (timer-suspect block in
  `2026-09-03_03`, late block in `2026-06-14_02a`, long all-crew gaps, early
  starts).
- Question 3 (worker experience and efficiency) needs a definition of
  experience that the data does not contain. Ask before planning it.
