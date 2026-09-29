# Plan: resolve the data-review inconsistencies

Written 29 September 2026.

## Context

`data-review/README.md` (29 Sep 2026) flagged 62 rows in `data/all_tasks.csv`
under five flags but changed nothing. Both manuscripts (`analysis/q1-*` and
`analysis/q2-*`) still read the raw file, and the Q1 job count and elapsed
times depend on how the split-session job IDs are treated. This plan resolves
every flag with a documented, reproducible action, produces a cleaned dataset
that analyses read instead of the raw file, and re-renders both manuscripts.

Principles: the raw file is never edited; every change is made by a script
and written to a log; judgement calls that the data cannot settle are kept
as flags, not silent edits; the user's field knowledge decides job identity.

### Job identity, as decided by the user (29 Sep 2026)

Interpretation of the user's answer against the actual job IDs in the file
(only `2026-06-14_02` exists on 14 June; only `2026-09-03_03` on 3 Sep):

| Raw job_id (session) | Crew | Decision | Cleaned job_id |
|---|---|---|---|
| `2026-06-12_01` | 1,3,11,18 | one job with the two below | `2026-06-12_01` |
| `2026-06-13_01` (s1) | 1,3,11,18 | same job, day 2 | `2026-06-12_01` |
| `2026-06-13_01` (s2) | 6,10,14,19 | same job, second crew | `2026-06-12_01` |
| `2026-06-14_02` (s1) | 1,3,11,18 | separate job | `2026-06-14_02a` |
| `2026-06-14_02` (s2) | 10,12,14 | separate job | `2026-06-14_02b` |
| `2026-09-03_03` (s1 + s2) | 1,3,14,16 / 2,12,18 | one job | `2026-09-03_03` |

Net: 36 jobs, one of which spans two dates. **Confirm this reading before
executing if it is wrong.**

### Decisions for the other flags

| Flag | Rows | Action |
|---|---|---|
| `label_variant` | 3 | Recode `Equipment / Repair` to `Repairing`. |
| `near_zero_duration` | 6 (< 2 s) | Drop as accidental taps; list in the log. |
| `long_entry` | 16 (> 50 min) | Keep values unchanged; flag `long_entry`. Four in `2026-09-03_03` ending ~13:22 also get `timer_suspect` for sensitivity checks (user chose "keep, but flag"). |
| `long_gap_before` | 35 | Keep; flag `long_gap_before`. Gaps are unrecorded time, not errors. |
| `session_restart` | 3 | Resolved by the job-identity table; `session` kept as a column. |
| README count | 1 | Fix 10,435 to the real counts. |

Not resolvable from the data, left as a field-verification list in the
review README: the 13:22 block in `2026-09-03_03`; the 19:43–19:48 block in
`2026-06-14_02` (s1) after a 91-min gap; gulper 5's 2.9-s Travel entry after
126 min in `2026-08-08_01`; the 48–100 min all-crew gaps
(`2026-06-29_01`, `2026-07-09_01`, `2026-08-20_02`, `2026-08-27_02`) that may
be unlogged breaks; starts before 06:00 (`2026-07-29_01`, `2026-06-18_01`,
`2026-09-14_01`).

## Files

### 0. `data-review/plan.md` (new)
Copy of this plan, per the user's preference for plans kept in the repo.

### 1. `data-review/clean.R` (new) — run from repo root
Reuse verbatim from `data-review/review.R`: the load block with `row` and
`session = cumsum(entry_number == 1)` (lines 11–15), the gap computation
(lines 30–34), and each flag `filter()` condition.

Steps, in order:
1. Read raw; add `row`, `session`, `job_id_raw = job_id`,
   `date = as.Date(substr(job_id_raw, 1, 10))`.
2. Recode `subtask == "Repair"` to `"Repairing"` (log 3 rows, `recode_label`).
3. Compute flags on the raw data (before dropping anything, so row numbers
   match `flagged_rows.csv`): `long_entry` (> 3000 s), `long_gap_before`
   (> 600 s, grouped by `job_id_raw, session, gulper_id`), `timer_suspect`
   (rows 9652, 9653, 9655, 9656, identified by rule: `job_id_raw ==
   "2026-09-03_03"`, duration > 3000, end between 13:21 and 13:23), joined
   into one `flags` column, semicolon-separated, empty if none.
4. Drop `duration_seconds < 2` (log 6 rows, `drop_near_zero`).
5. Assign cleaned `job_id` from a small lookup table keyed on
   `(job_id_raw, session)` as above; all other IDs unchanged. Log the affected
   rows once per group (`merge_job` / `split_job`).
6. Recompute `entry_number` as a 1..n sequence per cleaned `job_id` ordered by
   date then start time, keeping the raw value as `entry_number_raw`.
7. Assertions: rows out = 10,778; 36 distinct `job_id`; no `Repair`;
   `sum(duration_seconds)` equals raw sum minus dropped seconds; every
   `job_id` has ≥ 1 Extraction entry; no gulper overlaps within a job.
8. Write `data/all_tasks_clean.csv` with columns
   `job_id, date, session, entry_number, gulper_id, task, subtask,
   entry_start_time, entry_end_time, duration_seconds, flags, job_id_raw,
   entry_number_raw` (`na = ""`), and `data-review/cleaning_log.csv` with
   `row, job_id_raw, gulper_id, task, subtask, duration_seconds, action,
   detail` (one line per changed or dropped row).
9. Print a summary: rows dropped, rows recoded, jobs merged/split, flag counts.

### 2. `data-review/README.md` (edit)
Add a "Resolution (date)" section after the flag summary: how to reproduce
(`Rscript data-review/clean.R`), the job-identity table, the per-flag action
table, the field-verification list, and a pointer to `cleaning_log.csv`. Note
`review.R` still targets the raw file and is unchanged.

### 3. `README.md` (edit)
Line 18: replace "10,435 records" with the raw count (10,784) and add a
paragraph describing `data/all_tasks_clean.csv` (10,778 rows, 36 jobs), the
extra columns, and that analyses use the cleaned file. In the column table
note that `entry_number` restarts within three raw job IDs.

### 4. `analysis/q1-total-job-time/index.qmd` (edit, then re-render)
- Read `../../data/all_tasks_clean.csv`; keep `n_jobs` from the data.
- Elapsed time: the merged job spans two dates, so compute
  `elapsed_h` per `(job_id, date)` as `max(end) - min(start)` and sum per job
  (identical to the current formula for single-day jobs).
- Job table: `date` becomes first date; add a Dates column only if needed.
- Methods: replace the "no job crosses midnight" sentence with a paragraph
  on the cleaned file (job merges/splits, 6 dropped rows, label recode) and
  cite the data review. Results: add one sensitivity sentence using the
  `timer_suspect` flag (total labour if those four entries are capped at
  50 min, roughly −2.1 person-hours).
- Expected shifts: labour total ≈ 509.0 person-h (unchanged to 0.1);
  36 jobs; elapsed total ≈ 143.6 h (+4.2 h from splitting 06-14_02);
  per-job means and the fig-jobs/tbl-jobs rows change for the merged and
  split jobs.

### 5. `analysis/q2-travel-time/index.qmd` (edit, then re-render)
- Read the cleaned file. None of the seven disposal-trip jobs is merged or
  split, so the headline (0.9 clock-h, 3.0 person-h over 7 jobs) is expected
  to be unchanged; `n_jobs_all` stays 36.
- Replace the split-session sensitivity sentence and the data-checks
  paragraph with a reference to the cleaned file; drop the
  `sessions`/`split_travel_jobs` code.
- The 5-minute trip rule stays (the 42-s and 2.9-s stubs are > 2 s so they
  survive cleaning; Q2 handles them).

## Verification

1. `Rscript data-review/clean.R` runs clean; assertions pass; summary shows
   6 dropped, 3 recoded, 1 merge (3 pieces), 1 split (2 pieces).
2. Re-run the review rules against the cleaned file (ad hoc, in R): only
   `long_entry` and `long_gap_before` remain, no `session_restart` under the
   cleaned `job_id`, no `Repair`, no duration < 2 s.
3. Render both manuscripts with
   `/Applications/RStudio.app/Contents/Resources/app/quarto/bin/quarto render`
   in each folder; no chunk errors; `pandoc ... -t plain` to read the numbers.
4. Compare Q1 and Q2 headline numbers before/after and report the deltas.
5. `git status` shows only the intended files; nothing under `data/all_tasks.csv`
   changed (`git diff --stat data/all_tasks.csv` empty).

## Out of scope
- Editing the raw CSV. Committing (use the `ghe-skills:commit` skill if asked;
  suggested subject `fix(data): resolve data-review flags and add cleaned dataset`).
- Modelling the true length of the timer-suspect entries or the unlogged gaps.
