# 02_clean.R -- Tidy the cached raw files into analysis-ready CSVs in data/.
# Run from this post's folder after 01_fetch.R:  Rscript 02_clean.R

suppressPackageStartupMessages(library(tidyverse))
library(jsonlite)

# MMWR week helpers -------------------------------------------------------------
# MMWR week 1 is the Sunday-start week containing January 4. Some years (2020, 2025)
# have a week 53, so season weeks are counted in days from week 40, not by week number.
mmwr_week1_start <- function(year) {
  jan4 <- as.Date(paste0(year, "-01-04"))
  jan4 - as.integer(format(jan4, "%u")) %% 7
}
mmwr_week_start <- function(year, week) mmwr_week1_start(year) + 7 * (week - 1)

add_season_cols <- function(df) {
  df |>
    mutate(
      year        = as.integer(epiweek %/% 100),
      week        = as.integer(epiweek %% 100),
      week_start  = mmwr_week_start(year, week),
      week_end    = week_start + 6,
      season_start_year = if_else(week >= 40, year, year - 1L),
      season      = sprintf("%d-%02d", season_start_year, (season_start_year + 1L) %% 100L),
      season_week = as.integer((week_start - mmwr_week_start(season_start_year, 40)) / 7) + 1L,
      # ILINet's ILI case definition changed at MMWR week 2021-40 (the phrase "without a
      # known cause other than influenza" was dropped), so only 2021-22 onward is
      # definitionally comparable; 2020-21/2021-22 are also distorted by COVID-19.
      comparable_baseline = season_start_year >= 2022
    )
}
region_label <- function(x) {
  recode(x, nat = "National", !!!setNames(paste("Region", 1:10), paste0("hhs", 1:10)))
}
read_delphi <- function(file) {
  ep <- fromJSON(file.path("data/raw/delphi", file))$epidata
  if (!is.data.frame(ep)) return(tibble())
  as_tibble(ep) |> mutate(region = region_label(region), release_date = as.Date(release_date))
}

# 1. ILINet (latest values) -------------------------------------------------------
ili <- read_delphi("fluview_latest.json") |>
  transmute(region, epiweek, issue, release_date, lag, num_ili, num_patients, num_providers,
            wili = as.numeric(wili), ili = as.numeric(ili)) |>
  add_season_cols() |>
  arrange(region, epiweek)

# 2. Clinical labs (latest values) ----------------------------------------------
clin <- read_delphi("fluview_clinical_latest.json") |>
  transmute(region, epiweek, issue, release_date, lag, total_specimens, total_a, total_b,
            pct_positive = percent_positive, pct_a = percent_a, pct_b = percent_b) |>
  add_season_cols() |>
  arrange(region, epiweek)

stopifnot(!anyDuplicated(ili[c("region", "epiweek")]), !anyDuplicated(clin[c("region", "epiweek")]))
write_csv(ili,  "data/ilinet_weekly.csv")
write_csv(clin, "data/clinical_labs_weekly.csv")

latest_week <- max(ili$epiweek)
pull_season <- {
  d <- as.Date(readLines("data/raw/pulled_on.txt")[1]); y <- as.integer(format(d, "%Y"))
  sy <- if (d >= mmwr_week_start(y, 40)) y else y - 1L
  sprintf("%d-%02d", sy, (sy + 1L) %% 100L)
}

# 3. Public health labs (CDC FluView download) -----------------------------------
read_cdc <- function(file) {
  read_csv(file.path("data/raw/cdc", file), skip = 1, na = c("X", "XX", ""),
           show_col_types = FALSE, name_repair = "minimal")
}
phl <- bind_rows(read_cdc("national_ICL_NREVSS_Public_Health_Labs.csv"),
                 read_cdc("hhs_ICL_NREVSS_Public_Health_Labs.csv")) |>
  transmute(region = if_else(`REGION TYPE` == "National", "National", REGION),
            epiweek = YEAR * 100L + WEEK,
            total_specimens = `TOTAL SPECIMENS`,
            a_h1n1pdm09 = `A (2009 H1N1)`, a_h3 = `A (H3)`,
            a_not_subtyped = `A (Subtyping not Performed)`, a_h3n2v = H3N2v, a_h5 = `A (H5)`,
            b_lineage_nd = B, b_victoria = BVic, b_yamagata = BYam) |>
  add_season_cols() |>
  arrange(region, epiweek)
write_csv(phl, "data/public_health_labs_weekly.csv")

# CDC's own clinical-lab file, kept as a cross-check on the Delphi mirror.
clin_cdc <- bind_rows(read_cdc("national_ICL_NREVSS_Clinical_Labs.csv"),
                      read_cdc("hhs_ICL_NREVSS_Clinical_Labs.csv")) |>
  transmute(region = if_else(`REGION TYPE` == "National", "National", REGION),
            epiweek = YEAR * 100L + WEEK, total_specimens_cdc = `TOTAL SPECIMENS`,
            pct_positive_cdc = `PERCENT POSITIVE`)
xcheck <- inner_join(clin |> select(region, epiweek, total_specimens, pct_positive),
                     clin_cdc, by = c("region", "epiweek")) |>
  mutate(spec_diff = total_specimens - total_specimens_cdc,
         pct_diff = pct_positive - pct_positive_cdc)
message(sprintf("Delphi vs CDC clinical-lab cross-check: %d region-weeks matched, %d differ in specimens, max |%%pos diff| = %.3f",
                nrow(xcheck), sum(xcheck$spec_diff != 0, na.rm = TRUE), max(abs(xcheck$pct_diff), na.rm = TRUE)))
write_csv(xcheck, "data/crosscheck_delphi_vs_cdc_clinical.csv")

# 4. Data flow: reporting volume by season -----------------------------------------
flow <- ili |>
  group_by(region, season, comparable_baseline) |>
  summarise(weeks = n(), last_epiweek = max(epiweek),
            median_providers = median(num_providers), min_providers = min(num_providers),
            max_providers = max(num_providers), total_patient_visits = sum(num_patients),
            .groups = "drop") |>
  left_join(clin |> group_by(region, season) |>
              summarise(clinical_specimens = sum(total_specimens), clinical_weeks = n(),
                        .groups = "drop"), by = c("region", "season")) |>
  left_join(phl |> group_by(region, season) |>
              summarise(phl_specimens = sum(total_specimens, na.rm = TRUE), .groups = "drop"),
            by = c("region", "season")) |>
  mutate(season_complete = last_epiweek %% 100 == 39)
write_csv(flow, "data/data_flow_by_season.csv")

# 5. Revisions: first release vs latest -------------------------------------------
lags <- 0:4
early_ili <- map_dfr(lags, \(l) read_delphi(sprintf("fluview_lag%d.json", l))) |>
  transmute(region, epiweek, lag, issue, value = as.numeric(wili), metric = "Weighted %ILI")
early_clin <- map_dfr(lags, \(l) read_delphi(sprintf("fluview_clinical_lag%d.json", l))) |>
  transmute(region, epiweek, lag, issue, value = percent_positive, metric = "Clinical % positive")
latest_vals <- bind_rows(
  ili  |> transmute(region, epiweek, latest_issue = issue, latest = wili, metric = "Weighted %ILI"),
  clin |> transmute(region, epiweek, latest_issue = issue, latest = pct_positive, metric = "Clinical % positive")
)
revisions_long <- bind_rows(early_ili, early_clin) |>
  inner_join(latest_vals, by = c("region", "epiweek", "metric")) |>
  mutate(revision = latest - value) |>
  add_season_cols()
write_csv(revisions_long, "data/revisions_by_lag.csv")

first_release <- revisions_long |>
  group_by(region, metric, epiweek) |>
  slice_min(lag, n = 1, with_ties = FALSE) |>
  ungroup() |>
  rename(first_value = value, first_lag = lag, first_issue = issue)
write_csv(first_release, "data/revisions_first_vs_latest.csv")

# 6. Season peaks and regional comparison against each region's own baseline ------
peaks <- ili |>
  group_by(region, season, comparable_baseline) |>
  summarise(peak_wili = max(wili), peak_wili_epiweek = epiweek[which.max(wili)],
            peak_wili_week_end = week_end[which.max(wili)], .groups = "drop") |>
  left_join(clin |> group_by(region, season) |>
              summarise(peak_pct_positive = max(pct_positive),
                        peak_pos_epiweek = epiweek[which.max(pct_positive)],
                        peak_pos_week_end = week_end[which.max(pct_positive)],
                        .groups = "drop"),
            by = c("region", "season"))
write_csv(peaks, "data/season_peaks.csv")

focus <- "2025-26"
baseline_seasons <- c("2022-23", "2023-24", "2024-25")
regional <- peaks |>
  filter(season %in% baseline_seasons) |>
  group_by(region) |>
  summarise(base_min_wili = min(peak_wili), base_max_wili = max(peak_wili),
            base_mean_wili = mean(peak_wili),
            base_min_pos = min(peak_pct_positive), base_max_pos = max(peak_pct_positive),
            base_mean_pos = mean(peak_pct_positive), .groups = "drop") |>
  inner_join(peaks |> filter(season == focus) |>
               select(region, peak_wili, peak_wili_epiweek, peak_pct_positive, peak_pos_epiweek),
             by = "region") |>
  mutate(wili_vs_base_max = peak_wili - base_max_wili,
         pos_vs_base_max = peak_pct_positive - base_max_pos)
write_csv(regional, "data/regional_2025_26_vs_own_baseline.csv")

# 7. Public health lab subtype mix by season -------------------------------------
phl_season <- phl |>
  group_by(region, season) |>
  summarise(across(c(total_specimens, a_h1n1pdm09:b_yamagata), \(x) sum(x, na.rm = TRUE)),
            weeks = n(), .groups = "drop") |>
  mutate(total_positive = a_h1n1pdm09 + a_h3 + a_not_subtyped + a_h3n2v + a_h5 +
           b_lineage_nd + b_victoria + b_yamagata,
         a_subtyped = a_h1n1pdm09 + a_h3 + a_h3n2v + a_h5,
         share_h3_of_subtyped_a = a_h3 / a_subtyped,
         share_h1_of_subtyped_a = a_h1n1pdm09 / a_subtyped,
         share_b_of_positive = (b_lineage_nd + b_victoria + b_yamagata) / total_positive)
write_csv(phl_season, "data/public_health_labs_by_season.csv")

# Console summary --------------------------------------------------------------
message("Latest ILINet week: ", latest_week, " (issue ", max(ili$issue), ", released ",
        max(ili$release_date), "). Season of pull date: ", pull_season,
        "; its weeks in data: ", sum(ili$season == pull_season))
options(width = 200)
print(flow |> filter(region == "National"), n = Inf)
print(peaks |> filter(region == "National"), n = Inf)
print(regional, n = Inf)
print(phl_season |> filter(region == "National") |>
        select(season, total_positive, a_subtyped, share_h3_of_subtyped_a, share_h1_of_subtyped_a, share_b_of_positive))
