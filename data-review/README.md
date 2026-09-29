# Data review: `data/all_tasks.csv`

Review date: 29 September 2026. Reproduce with `Rscript data-review/review.R`
from the repository root.

The review checked the 10,784 task entries across 36 job IDs for internal
consistency. Flagged entries are listed in [`flagged_rows.csv`](flagged_rows.csv),
one line per row and flag. `row` is the data row number in `all_tasks.csv`
(1 = first line after the header). Nothing in the source data has been changed.

## Summary of flags

| Flag | Lines | Priority | What to check |
|---|---:|---|---|
| `session_restart` | 3 | High | Is each job ID one job or two? |
| `long_entry` | 16 | Medium | Was the timer left running? |
| `long_gap_before` | 35 | Medium | Was an unlogged break or a late stop recorded? |
| `near_zero_duration` | 6 | Low | Accidental taps? |
| `label_variant` | 3 | Low | Merge "Repair" into "Repairing"? |

## Resolution (29 September 2026)

Every flag is resolved by `data-review/clean.R`, which reads the raw file,
applies the actions below and writes `data/all_tasks_clean.csv` plus
`data-review/cleaning_log.csv` (one line per changed or dropped row, with the
raw `row` number). Reproduce with `Rscript data-review/clean.R` from the
repository root. The raw file is never edited, and `review.R` still runs
against it unchanged. Both manuscripts under `analysis/` now read the cleaned
file.

### Job identity

Decided from field knowledge, not from the data:

| Raw job_id (session) | Gulpers | Decision | Cleaned job_id |
|---|---|---|---|
| 2026-06-12_01 | 1, 3, 11, 18 | one job with the two rows below (two days, two crews) | 2026-06-12_01 |
| 2026-06-13_01 (session 1) | 1, 3, 11, 18 | same job, second day | 2026-06-12_01 |
| 2026-06-13_01 (session 2) | 6, 10, 14, 19 | same job, second crew | 2026-06-12_01 |
| 2026-06-14_02 (session 1) | 1, 3, 11, 18 | a separate job | 2026-06-14_02a |
| 2026-06-14_02 (session 2) | 10, 12, 14 | a separate job | 2026-06-14_02b |
| 2026-09-03_03 (sessions 1 and 2) | 1, 3, 14, 16 / 2, 12, 18 | one job | 2026-09-03_03 |

The cleaned file therefore still has 36 jobs, one of which spans two dates.
`job_id_raw`, `session` and `entry_number_raw` keep the original values;
`entry_number` is renumbered within each cleaned job; `date` comes from the
raw job ID.

### Actions per flag

| Flag | Rows | Action in the cleaned file |
|---|---:|---|
| `session_restart` | 3 | Resolved by the job-identity table above. |
| `long_entry` | 16 | Kept unchanged; marked `long_entry` in the `flags` column. The four entries in 2026-09-03_03 ending within a minute of 13:22 are also marked `timer_suspect`, so analyses can cap or exclude them in a sensitivity check. |
| `long_gap_before` | 35 | Kept; marked `long_gap_before` (34 rows remain, one was dropped as near-zero). Gaps are unrecorded time, not errors. |
| `near_zero_duration` | 6 | Dropped as accidental taps (rows 283, 3316, 6097, 7134, 9765, 9768; 5.5 seconds in total). |
| `label_variant` | 3 | Equipment "Repair" recoded to "Repairing". "Repair" under Superstructure is a different subtask and is left alone. |
| README count | 1 | The project README now gives the real counts. |

### Still to verify in the field

The data cannot settle these; they are flagged, not changed:

- 2026-09-03_03: the four entries of 78–87 minutes all ending at about 13:22
  (was the timer left running over a break?), and the seven Rest entries
  ending together at about 16:34.
- 2026-06-14_02 (now 2026-06-14_02a): four short entries at 19:43–19:48 after
  a 91-minute gap, which extend the job by 1.5 clock hours.
- 2026-08-08_01: gulper 5's 2.9-second Travel entry at 18:02 after 126
  minutes with no record.
- All-crew gaps of 48–100 minutes in 2026-06-29_01, 2026-07-09_01,
  2026-08-20_02 and 2026-08-27_02, which may be breaks not logged as Rest.
- Starts before 06:00 in 2026-07-29_01, 2026-06-18_01 and 2026-09-14_01.

## 1. Two recording sessions under one job ID (high)

In 33 jobs, `entry_number` runs from 1 to n once. In three jobs it restarts at
1 partway through, splitting the job into two blocks of rows. The two crews in
each pair share no workers and were recording over overlapping hours:

| job_id | Session | Rows | Gulpers | Clock time | Person-hours |
|---|---|---|---|---|---:|
| 2026-06-13_01 | 1 | 750–957 | 1, 3, 11, 18 | 08:49–12:17 | 12.4 |
| 2026-06-13_01 | 2 | 958–1888 | 6, 10, 14, 19 | 07:41–11:51 | 14.1 |
| 2026-06-14_02 | 1 | 2130–2584 | 1, 3, 11, 18 | 11:32–19:48 | 27.0 |
| 2026-06-14_02 | 2 | 2585–3316 | 10, 12, 14 | 11:57–16:10 | 12.3 |
| 2026-09-03_03 | 1 | 9428–9788 | 1, 3, 14, 16 | 09:02–17:25 | 33.4 |
| 2026-09-03_03 | 2 | 9789–10057 | 2, 12, 18 | 09:09–17:24 | 24.7 |

This looks like two recordings (two phones, or two jobs) filed under one
`job_id`. Total person-hours are unaffected, but if the pairs are separate jobs
there are 39 jobs rather than 36, total elapsed time rises from 139.4 to about
154.9 clock hours, and the per-job results in `analysis/q1-total-job-time` change.

## 2. Very long single entries (medium)

Sixteen entries last more than 50 minutes. The most suspicious are in
2026-09-03_03, where four workers each have one unbroken 78–87 minute entry
(Mixing ×2, Pulling out trash, Disposal) all ending within a minute of 13:22.
That pattern fits a timer left running over a break. The same job has five
Rest entries of 59–68 minutes ending together at 16:34. The four
59-minute Rest entries in 2026-08-20_02 (12:14–13:14) look like a genuine lunch
break.

## 3. Long unrecorded gaps (medium)

There are 35 cases of a worker going more than 10 minutes without a recorded
task. Gaps over 1 minute add up to 36.5 hours, which is not counted in labour
time. Notable cases:

- **2026-06-14_02:** no entries between 18:13 and 19:43. Four entries then
  start at 19:43 and all stop at 19:48:09, which extends the job's clock time by
  about 1.5 hours.
- **2026-08-08_01, gulper 5:** a 126-minute gap, then one 3-second Travel entry
  at 18:02 that stops together with everyone else's final entries.
- **2026-08-27_02:** all four workers have a 100-minute gap before 13:45.
- **2026-09-14_01:** a 36-minute gap, then three 6–17 second Rest entries
  starting at 09:00:00 before the recording stops.

Several group gaps of 48–58 minutes (2026-08-20_02, 2026-06-29_01,
2026-07-09_01) may be breaks that were not logged as Rest.

## 4. Minor issues (low)

- Six entries last under 2 seconds, including one of 0 seconds (row 283).
- Equipment uses both "Repair" (3 rows) and "Repairing" (51 rows).
- The project README says the file has 10,435 records, but it has 10,784.
- A few jobs start before 06:00 (2026-07-29_01 at 05:31; 2026-06-18_01 and
  2026-09-14_01 around 05:45). These are plausible but worth confirming.

## Checks that passed

No duplicate rows; no whitespace or case variants in any category; no worker
has overlapping tasks within a job; no worker is recorded on two jobs at once;
durations match end minus start time to within ±1 second; entry numbers follow
start-time order within each session; every job has at least one Extraction
entry.
