# Cleaning of data/all_tasks.csv
#
# Resolves the flags raised by data-review/review.R (see data-review/README.md,
# "Resolution"). The raw file is never edited. Run from the repository root:
#   Rscript data-review/clean.R
# Writes data/all_tasks_clean.csv and data-review/cleaning_log.csv.
# `row` refers to the data row number in all_tasks.csv (1 = first line after
# the header), as in flagged_rows.csv.

suppressMessages(library(dplyr))
library(readr)

tasks <- read_csv("data/all_tasks.csv", show_col_types = FALSE) |>
  mutate(row = row_number()) |>
  group_by(job_id) |>
  mutate(session = cumsum(entry_number == 1)) |>
  ungroup() |>
  mutate(job_id_raw = job_id,
         entry_number_raw = entry_number,
         date = as.Date(substr(job_id_raw, 1, 10)))

raw_rows <- nrow(tasks)
raw_seconds <- sum(tasks$duration_seconds)

log_cols <- c("row", "job_id_raw", "gulper_id", "task", "subtask", "duration_seconds")
log_entry <- function(d, action, detail) {
  d |> select(all_of(log_cols)) |> mutate(action = action, detail = detail)
}
log <- list()

# 1. Label variant: Equipment / "Repair" -> "Repairing"
recode_rows <- tasks |> filter(task == "Equipment", subtask == "Repair")
log$recode <- log_entry(recode_rows, "recode_label", "subtask 'Repair' recoded to 'Repairing'")
tasks <- tasks |>
  mutate(subtask = if_else(task == "Equipment" & subtask == "Repair", "Repairing", subtask))

# 2. Flags kept on the data (computed on the raw rows, before any row is dropped)
long_entry <- tasks |> filter(duration_seconds > 3000) |> pull(row)

long_gap <- tasks |>
  arrange(job_id_raw, session, gulper_id, entry_start_time) |>
  group_by(job_id_raw, session, gulper_id) |>
  mutate(gap_s = as.numeric(entry_start_time - lag(entry_end_time))) |>
  ungroup() |>
  filter(gap_s > 600) |>
  pull(row)

timer_suspect <- tasks |>
  filter(job_id_raw == "2026-09-03_03", duration_seconds > 3000,
         as.numeric(entry_end_time) >= 13 * 3600 + 21 * 60,
         as.numeric(entry_end_time) <= 13 * 3600 + 23 * 60) |>
  pull(row)

tasks <- tasks |>
  mutate(flags = paste(
    if_else(row %in% long_entry, "long_entry", NA_character_),
    if_else(row %in% long_gap, "long_gap_before", NA_character_),
    if_else(row %in% timer_suspect, "timer_suspect", NA_character_),
    sep = ";")) |>
  mutate(flags = gsub("NA;|;NA", "", flags),
         flags = if_else(flags == "NA", "", flags))

# 3. Drop near-zero durations (accidental taps)
drop_rows <- tasks |> filter(duration_seconds < 2)
log$drop <- log_entry(drop_rows, "drop_near_zero",
                      sprintf("duration %.1f s, dropped as accidental tap", drop_rows$duration_seconds))
tasks <- tasks |> filter(duration_seconds >= 2)

# 4. Job identity, decided from field knowledge (29 September 2026):
#    - 2026-06-12_01 and both recording sessions of 2026-06-13_01 are one job
#      (two days, two crews): job_id 2026-06-12_01
#    - the two recording sessions of 2026-06-14_02 are two jobs: _02a and _02b
#    - the two recording sessions of 2026-09-03_03 are one job: unchanged
job_map <- tribble(
  ~job_id_raw,      ~session, ~job_id_new,      ~action,
  "2026-06-13_01",  1L,       "2026-06-12_01",  "merge_job",
  "2026-06-13_01",  2L,       "2026-06-12_01",  "merge_job",
  "2026-06-14_02",  1L,       "2026-06-14_02a", "split_job",
  "2026-06-14_02",  2L,       "2026-06-14_02b", "split_job"
)
tasks <- tasks |>
  left_join(job_map, by = c("job_id_raw", "session")) |>
  mutate(job_id = coalesce(job_id_new, job_id_raw)) |>
  select(-job_id_new)

log$jobs <- tasks |>
  filter(!is.na(action)) |>
  group_by(job_id_raw, session, job_id, action) |>
  summarise(row = min(row), n = n(), .groups = "drop") |>
  transmute(row, job_id_raw, gulper_id = NA_real_, task = NA_character_, subtask = NA_character_,
            duration_seconds = NA_real_, action,
            detail = sprintf("session %d (%d rows from this row) assigned to job %s", session, n, job_id))
tasks <- tasks |> select(-action)

# 5. Renumber entries within each cleaned job
tasks <- tasks |>
  arrange(job_id, date, entry_start_time, gulper_id) |>
  group_by(job_id) |>
  mutate(entry_number = row_number()) |>
  ungroup()

# 6. Checks
stopifnot(
  nrow(tasks) == raw_rows - nrow(drop_rows),
  n_distinct(tasks$job_id) == 36,
  !any(tasks$task == "Equipment" & tasks$subtask == "Repair", na.rm = TRUE),
  abs(sum(tasks$duration_seconds) - (raw_seconds - sum(drop_rows$duration_seconds))) < 1e-6,
  all(tasks |> group_by(job_id) |> summarise(x = any(task == "Extraction")) |> pull(x)),
  tasks |>
    arrange(job_id, gulper_id, date, entry_start_time) |>
    group_by(job_id, gulper_id, date) |>
    mutate(ok = is.na(lag(entry_end_time)) | as.numeric(entry_start_time - lag(entry_end_time)) >= -1) |>
    pull(ok) |> all()
)

# 7. Write
clean <- tasks |>
  select(job_id, date, session, entry_number, gulper_id, task, subtask,
         entry_start_time, entry_end_time, duration_seconds, flags,
         job_id_raw, entry_number_raw)
write_csv(clean, "data/all_tasks_clean.csv", na = "")

cleaning_log <- bind_rows(log) |> arrange(row, action)
write_csv(cleaning_log, "data-review/cleaning_log.csv", na = "")

cat(sprintf("raw rows %d -> clean rows %d; dropped %d; recoded %d; jobs %d (raw ids %d)\n",
            raw_rows, nrow(clean), nrow(drop_rows), nrow(recode_rows),
            n_distinct(clean$job_id), n_distinct(clean$job_id_raw)))
print(count(cleaning_log, action))
print(clean |> filter(flags != "") |> tidyr::separate_rows(flags, sep = ";") |> count(flags))
