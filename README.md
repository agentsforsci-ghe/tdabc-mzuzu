# tdabc-mzuzu

Task timing data from pit latrine emptying operations in Mzuzu, Malawi.

## Overview

This repository contains task-level timing data collected during pit latrine emptying (manual sludge removal) operations in Mzuzu, Malawi. The data was collected using the **Gulper Timer** field application and will be analyzed using **Time-Driven Activity-Based Costing (TDABC)** to understand operational costs and safety across pit emptiers.

## Data Source

- **Location:** Mzuzu, Malawi
- **Collection Method:** Gulper Timer mobile app (ridealong field observations)
- **Time Period:** May–September 2026
- **Worker Anonymization:** Workers are identified by anonymous gulper IDs only; no personal identifiers are included

## Dataset Description

`data/all_tasks.csv` contains 10,784 records of individual tasks and subtasks performed during pit latrine emptying operations, as exported from the app (raw, never edited).

`data/all_tasks_clean.csv` is the cleaned version used by the analyses (10,778 records, 36 jobs). It is produced by `data-review/clean.R` from the raw file: six accidental taps under 2 seconds are dropped, the Equipment subtask "Repair" is recoded to "Repairing", and job IDs are corrected from field knowledge (2026-06-12_01 and 2026-06-13_01 are one two-day job; the two recording sessions in 2026-06-14_02 are two jobs, 2026-06-14_02a and 2026-06-14_02b). Every change is listed in `data-review/cleaning_log.csv`, and `data-review/README.md` explains the review and the decisions.

### Columns

| Column | Description |
|--------|-------------|
| `entry_number` | Sequential entry identifier (in the raw file it restarts at 1 where a second recording session was filed under the same job ID) |
| `gulper_id` | Anonymous identifier for the pit emptier (worker) |
| `task` | Main task category (e.g., Fluidizing, Extraction, Communication, Rest) |
| `subtask` | Specific subtask within the main task (e.g., Adding water, Mixing, Removing sludge) |
| `entry_start_time` | Start time of the task (HH:MM:SS) |
| `entry_end_time` | End time of the task (HH:MM:SS) |
| `duration_seconds` | Task duration in seconds |
| `job_id` | Identifier linking tasks to a specific pit emptying job |

The cleaned file has the same columns plus `date` (from the raw job ID), `session` (recording session within the raw job ID), `flags` (semicolon-separated: `long_entry`, `long_gap_before`, `timer_suspect`; empty if none), `job_id_raw` and `entry_number_raw` (the original values).

## Key Features

- **Non-sensitive data:** Anonymized worker IDs; no personal or identifying information
- **Detailed timing:** Second-level precision for activity duration analysis
- **Multi-worker operations:** Captures simultaneous work by multiple gulpers on the same job
- **Safety-relevant tasks:** Includes communication, rest, and task breakdowns that relate to worker safety and fatigue

## Use Cases

This data is designed for:
- Time-driven activity-based costing (TDABC) analysis
- Operational efficiency studies
- Safety and fatigue assessment
- Work process mapping and improvement
- Cost attribution to specific activities

## Ethical Considerations

- All workers are identified by anonymous IDs to protect privacy
- No recruitment data, personal identifiers, or sensitive information is included
- Data is non-sensitive and suitable for public sharing
- Consent was obtained from Mzuzu City Council and participating workers

## Context

This work is part of a doctoral research project at the **Global Health Engineering (GHE)** group at ETH Zürich, in partnership with **Mzuzu City Council** and **Mzuzu University**. The research focuses on the professionalization of informal pit latrine emptying services in Mzuzu.

## How to Cite

If you use this data, please cite it as:

> Casserly, P. (2026). Task timing data from pit latrine emptying operations in Mzuzu, Malawi. Retrieved from https://github.com/agentsforsci-ghe/tdabc-mzuzu

## Contact

For questions about the data or this project, contact the researcher or refer to the [Global Health Engineering group](https://ghe.ethz.ch/).

---

*Last updated: September 2026*
