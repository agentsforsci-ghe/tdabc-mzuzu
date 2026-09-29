# Data review of data/all_tasks.csv
#
# Flags entries that look inconsistent or need checking against field notes.
# Run from the repository root:  Rscript data-review/review.R
# Writes data-review/flagged_rows.csv (one line per row x flag).
# `row` is the data row number in all_tasks.csv (1 = first line after the header).

suppressMessages(library(dplyr))
library(readr)

tasks <- read_csv("data/all_tasks.csv", show_col_types = FALSE) |>
  mutate(row = row_number()) |>
  group_by(job_id) |>
  mutate(session = cumsum(entry_number == 1)) |>
  ungroup()

# 1. entry_number restarts at 1 inside a job: a second recording session
session_restart <- tasks |>
  filter(entry_number == 1, session > 1) |>
  mutate(flag = "session_restart",
         detail = "entry_number restarts at 1 within the job; rows from here belong to a second recording session")

# 2. single entries longer than 50 minutes
long_entry <- tasks |>
  filter(duration_seconds > 3000) |>
  mutate(flag = "long_entry",
         detail = sprintf("single entry lasts %.0f min", duration_seconds / 60))

# 3. worker has more than 10 minutes of unrecorded time before this entry
long_gap <- tasks |>
  arrange(job_id, gulper_id, entry_start_time) |>
  group_by(job_id, gulper_id) |>
  mutate(gap_s = as.numeric(entry_start_time - lag(entry_end_time))) |>
  ungroup() |>
  filter(gap_s > 600) |>
  mutate(flag = "long_gap_before",
         detail = sprintf("%.0f min unrecorded since this worker's previous entry", gap_s / 60)) |>
  select(-gap_s)

# 4. near-zero durations (likely accidental taps)
near_zero <- tasks |>
  filter(duration_seconds < 2) |>
  mutate(flag = "near_zero_duration",
         detail = sprintf("duration %.1f s", duration_seconds))

# 5. subtask label variant ("Repair" vs "Repairing" under Equipment)
label_variant <- tasks |>
  filter(task == "Equipment", subtask == "Repair") |>
  mutate(flag = "label_variant",
         detail = "Equipment subtask 'Repair' (3 rows) vs 'Repairing' (51 rows)")

flagged <- bind_rows(session_restart, long_entry, long_gap, near_zero, label_variant) |>
  select(row, flag, detail, job_id, session, entry_number, gulper_id, task, subtask,
         entry_start_time, entry_end_time, duration_seconds) |>
  arrange(row, flag)

write_csv(flagged, "data-review/flagged_rows.csv", na = "")

# Session summary for the three jobs with a restart
sessions <- tasks |>
  filter(job_id %in% session_restart$job_id) |>
  group_by(job_id, session) |>
  summarise(rows = paste0(min(row), "-", max(row)),
            gulpers = paste(sort(unique(gulper_id)), collapse = ", "),
            start = min(entry_start_time), end = max(entry_end_time),
            person_h = round(sum(duration_seconds) / 3600, 1),
            .groups = "drop")

print(count(flagged, flag))
print(as.data.frame(sessions))
