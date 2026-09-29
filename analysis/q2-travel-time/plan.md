# Plan: Q2 — Average time per job travelling to the disposal site

Written 29 September 2026. Plan only; no analysis has been run and no
manuscript files exist yet.

## Context

`questions.md` lists three questions; Q1 (total job time) is answered in
`analysis/q1-total-job-time/`. This plan answers Q2 as specified: **the
average time spent per job travelling to the disposal site, for jobs where
the team travelled to the disposal site.** The deliverable is a new,
self-contained Quarto manuscript project that renders to docx, following the
Q1 project's layout and style so the two read as a series.

Definitions:

- **Travel = the `Travel to disposal site` subtask only.** `On errand`
  entries are not part of the analysis; Methods says so in one sentence.
- **Population = jobs with at least one disposal-site trip.** From a
  read-only check this is 8 of the 36 jobs (43 entries, ≈20.7 person-hours).
  Jobs without a trip are not in the denominator.
- **Headline measure = clock hours per job:** the union of all disposal-site
  Travel intervals within a job across all gulpers, so a trip made by four
  gulpers together counts once. **Person-hours** (sum of `duration_seconds`,
  Q1's TDABC measure) is reported alongside as the secondary figure.

Expected magnitude, to sanity-check the render: trips of roughly 30–46 min
made by 3–4 gulpers at once, so on the order of 0.8–1.0 clock-hours and
≈2.6 person-hours per job. Exact values come from the render.

## Files to create (all under `analysis/q2-travel-time/`)

Mirror `analysis/q1-total-job-time/`:

1. `_quarto.yml` — copy of Q1's verbatim (manuscript project, `article:
   index.qmd`, docx with `toc: false`, `number-sections: true`, `fig-dpi:
   300`; execute `echo: false`, `warning/message: false`, `freeze: auto`).
2. `.gitignore` — copy of Q1's (`/.quarto/`, `**/*.quarto_ipynb`).
3. `references.bib` — copy of Q1's five Zotero entries.
4. `index.qmd` — the manuscript (below).

The render produces `_manuscript/index.docx` and `_freeze/`; Q1 commits both,
so leave them in place. No CLAUDE.md, renv, reference-doc or csl exist; do
not add any.

## `index.qmd` design

**YAML header:** same shape as Q1 (title, author block, `date: 2026-09-29`,
`bibliography: references.bib`, abstract). Title: "Time spent travelling to
the disposal site during pit emptying jobs in Mzuzu, Malawi".

**Setup chunk** (reuse Q1: `dplyr`, `readr`, `ggplot2`, `knitr`;
`read_csv("../../data/all_tasks.csv")`; the same `fmt()` helper):

- `travel <- tasks |> filter(task == "Travel", subtask == "Travel to disposal site")`.
- Per job: `n_workers = n_distinct(gulper_id)`, `n_entries`, `labour_h =
  sum(duration_seconds)/3600`.
- Clock hours per job by interval union: convert `hms` to seconds, sort by
  start, merge overlaps (`new = start > lag(cummax(end), default = -Inf)`,
  `grp = cumsum(new)`), sum `max(end) - min(start)` over groups. Also keep
  the number of merged intervals as `n_trips` and their mean length. No job
  crosses midnight (established in Q1 and the data review).
- Scalars: `n_travel_jobs`, `mean_clock_h`, `median_clock_h`, range,
  `mean_labour_h`, `mean_trips`, `mean_trip_min`, `mean_gulpers_per_trip`
  (= person-h / clock-h), and each job's travel share of its total labour
  (Q1's per-job `labour_h`).

**Sections** (same headings as Q1):

1. **Introduction** — TDABC framing; transporting sludge to the disposal site
   is a distinct activity whose time per job is needed for costing; restate
   the question in bold.
2. **Data and methods** — dataset summary; the Travel task and its two
   subtasks, with the sentence that errands are excluded; the population
   (jobs with a disposal-site trip) and why it is the denominator; clock
   hours (interval union) vs person-hours; scope caveat that travel from the
   base to the job site is not recorded. Data checks: reuse Q1's; check at
   run time whether the flagged Travel rows in
   `data-review/flagged_rows.csv` (row 6947, 2.9 s; rows 9765/9768, <1 s)
   fall in the disposal-site subset, and if so note they are kept with
   negligible effect.
3. **Results** —
   - Headline paragraph: mean clock hours per job (median, range) for the
     jobs with a trip; then person-hours; trips per job and mean trip length;
     how many gulpers travel together.
   - `@tbl-jobs`: one row per job with a trip — date, gulpers, trips, clock
     h, person-h, share of that job's labour time; a Mean row (`kable`,
     digits = 1).
   - `@fig-jobs`: clock hours of travel per job with a trip, ordered by date,
     dashed mean line, styled as Q1's `fig-jobs` (`theme_minimal(base_size =
     10)`, `#2a78d6` fill, `#52514e` text).
   - Sensitivity sentence: the data review found three job IDs holding two
     recording sessions; check whether any of the travel jobs is one of them
     (2026-06-14_02 and 2026-09-03_03 have Travel rows; confirm subtask) and
     say whether splitting them changes the mean.
4. **Conclusion** — one paragraph with the headline number in bold and the
   person-hour figure.
5. **Appendix A: Relevant literature** `{.appendix}` — Q1's five references,
   reworded toward transport and disposal logistics.
6. **References** — `::: {#refs}`.

All numbers in prose via inline `r fmt(...)`.

## Verification

1. Render (quarto is not on PATH):
   ```
   cd analysis/q2-travel-time && /Applications/RStudio.app/Contents/Resources/app/quarto/bin/quarto render
   ```
   Confirm `_manuscript/index.docx` is produced with no chunk errors.
2. Sanity checks: 43 entries in 8 jobs; clock hours ≤ person-hours for every
   job and equal where one gulper travelled alone; disposal-site person-hours
   plus errand person-hours equals the Travel row of Q1's `@tbl-task`
   (≈36.2).
3. `pandoc _manuscript/index.docx -t plain` and confirm the table and figure
   cross-references resolve, citations render, and the appendix is present.

## Out of scope

- No changes to `data/`, Q1, `questions.md` or `README.md`.
- No commit as part of the analysis; commit separately with the repo's
  Conventional Commits style, e.g. `feat(analysis): answer average travel
  time to disposal site per job`.
