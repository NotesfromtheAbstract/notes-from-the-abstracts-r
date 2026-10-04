# 03_plots.R -- Figures for "Flying Blind Into Flu Season". Saves PNGs to figures/.
# Run from this post's folder after 02_clean.R:  Rscript 03_plots.R

suppressPackageStartupMessages({ library(tidyverse); library(scales) })
source("../../R/theme_blog.R")
dir.create("figures", showWarnings = FALSE)

pulled_on <- readLines("data/raw/pulled_on.txt")[1]
rd <- function(f) read_csv(file.path("data", f), show_col_types = FALSE)
ili      <- rd("ilinet_weekly.csv")
clin     <- rd("clinical_labs_weekly.csv")
phl      <- rd("public_health_labs_by_season.csv")
flow     <- rd("data_flow_by_season.csv")
first    <- rd("revisions_first_vs_latest.csv")
revlag   <- rd("revisions_by_lag.csv")
regional <- rd("regional_2025_26_vs_own_baseline.csv")

latest <- max(ili$epiweek)
latest_lbl <- sprintf("MMWR %d week %d", latest %/% 100, latest %% 100)
src_ili  <- "CDC ILINet via Delphi Epidata API (api.delphi.cmu.edu/epidata/fluview)"
src_clin <- "WHO/NREVSS clinical labs (CDC FluView) via Delphi Epidata API (api.delphi.cmu.edu/epidata/fluview_clinical)"
src_phl  <- "WHO/NREVSS public health labs, CDC FluView Interactive (gis.cdc.gov/grasp/fluview/fluportaldashboard.html)"
cap <- function(src, extra = NULL) {
  paste0("Source: ", src, ". Data pulled ", pulled_on, "; latest week ", latest_lbl, ".",
         if (!is.null(extra)) paste0("\n", extra))
}

save_png <- function(p, file) {
  ggsave(file.path("figures", file), p, width = 1600 / 150, height = 900 / 150,
         dpi = 150, units = "in", device = ragg::agg_png, bg = "white")
  message("Saved figures/", file)
}

# Season-week axis: week 1 = MMWR week 40. Month labels are approximate (+/- 1 week),
# which is unavoidable because some seasons have 53 MMWR weeks.
season_breaks <- c(1, 5, 9, 14, 18, 22, 27, 31, 35, 40, 44, 48)
season_labels <- c("Oct", "Nov", "Dec", "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep")
x_season <- scale_x_continuous(breaks = season_breaks, labels = season_labels,
                               expand = expansion(mult = 0.01))
xlab_season <- "Season week (week 1 = MMWR week 40); month labels approximate"

baseline <- c("2022-23", "2023-24", "2024-25")
focus    <- "2025-26"
pal_season <- c("2022-23" = "#9ecae1", "2023-24" = "#4292c6", "2024-25" = "#08519c", "2025-26" = "#e6550d")
lw_season  <- c("2022-23" = 0.7, "2023-24" = 0.7, "2024-25" = 0.7, "2025-26" = 1.4)
two_regions <- c("National", "Region 6")
region_lab  <- c("National" = "National", "Region 6" = "HHS Region 6 (AR, LA, NM, OK, TX)")

# 1. Data flow: providers and specimens by season (national) ---------------------
flow_nat <- flow |>
  filter(region == "National") |>
  transmute(season, season_complete, last_epiweek,
            `Median ILINet providers reporting per week` = median_providers,
            `Clinical lab specimens tested per season (millions)` = clinical_specimens / 1e6) |>
  pivot_longer(-c(season, season_complete, last_epiweek)) |>
  mutate(label = if_else(str_detect(name, "millions"), sprintf("%.2fM", value), comma(value, 1)))
p1 <- ggplot(flow_nat, aes(season, value, fill = season == focus)) +
  geom_col(width = 0.7) +
  geom_text(aes(label = label), vjust = -0.4, size = 3.3) +
  facet_wrap(~name, scales = "free_y") +
  scale_fill_manual(values = c(`TRUE` = "#e6550d", `FALSE` = "#6baed6"), guide = "none") +
  scale_y_continuous(expand = expansion(mult = c(0, 0.12)), labels = comma) +
  labs(x = NULL, y = NULL,
       title = "Is the data still flowing? More ILINet providers, fewer lab specimens",
       subtitle = "National. 2025-26 runs through the latest published week (one week short of a full season).",
       caption = cap(paste0(src_ili, ";\n", src_clin))) +
  theme_blog() + theme(axis.text.x = element_text(angle = 0))
save_png(p1, "01_data_flow_providers_specimens.png")

# 2. Regional reporting: median providers per week by HHS region and season -------
prov_reg <- flow |>
  filter(region != "National") |>
  mutate(region = factor(region, paste("Region", 1:10)))
p2 <- ggplot(prov_reg, aes(season, fct_rev(region), fill = median_providers)) +
  geom_tile(colour = "white") +
  geom_text(aes(label = comma(median_providers, 1),
                colour = median_providers > quantile(median_providers, 0.7)), size = 3.2) +
  scale_colour_manual(values = c(`TRUE` = "white", `FALSE` = "grey15"), guide = "none") +
  scale_fill_distiller(palette = "Blues", direction = 1, name = "Median providers/week", labels = comma) +
  labs(x = NULL, y = NULL,
       title = "ILINet reporting depth varies a lot by HHS region",
       subtitle = "Median number of ILINet providers reporting per week, by HHS region and season",
       caption = cap(src_ili, "Region 6 = AR, LA, NM, OK, TX. Provider counts reflect the latest release; late reports keep arriving for recent weeks.")) +
  theme_blog() + theme(panel.grid = element_blank(), legend.key.width = unit(1.5, "cm"))
save_png(p2, "02_providers_by_hhs_region.png")

# 3. Revisions: first release vs latest, 2025-26, national --------------------------
rev25 <- first |>
  filter(region == "National", season == focus) |>
  select(metric, week_end, `First release` = first_value, `Latest release` = latest) |>
  pivot_longer(c(`First release`, `Latest release`), names_to = "release")
p3 <- ggplot(rev25, aes(week_end, value, colour = release, linetype = release)) +
  geom_line(linewidth = 0.9) +
  facet_wrap(~metric, scales = "free_y") +
  scale_colour_manual(values = c("First release" = "grey45", "Latest release" = "#e6550d"), name = NULL) +
  scale_linetype_manual(values = c("First release" = "22", "Latest release" = "solid"), name = NULL) +
  scale_y_continuous(labels = label_percent(scale = 1), limits = c(0, NA)) +
  scale_x_date(date_breaks = "2 months", date_labels = "%b\n%Y") +
  labs(x = "Week ending", y = NULL,
       title = "First release vs. today: how much 2025-26 numbers moved",
       subtitle = "National. 'First release' = earliest archived issue for each week (lag 0 where available, else lag 1-4).",
       caption = cap(paste0(src_ili, ";\n", src_clin))) +
  theme_blog()
save_png(p3, "03_revisions_first_vs_latest_2025_26.png")

# 4. Revisions by lag: absolute change from each early release to latest -----------
rev_lag <- revlag |>
  filter(region == "National", epiweek < latest - 4) |>   # skip weeks too new to have settled
  mutate(lag = factor(lag), abs_rev = abs(revision))
rev_lag_sum <- rev_lag |> group_by(metric, lag) |>
  summarise(med = median(abs_rev), p90 = quantile(abs_rev, 0.9), n = n(), .groups = "drop")
p4 <- ggplot(rev_lag, aes(lag, abs_rev)) +
  geom_boxplot(outlier.alpha = 0.4, fill = "#c6dbef", colour = "#08519c", width = 0.6) +
  geom_text(data = rev_lag_sum, aes(y = p90, label = sprintf("median %.2f pts", med)),
            vjust = -1.2, size = 3.1, colour = "grey25") +
  facet_wrap(~metric, scales = "free_y") +
  labs(x = "Weeks after the data week when the value was published (lag)",
       y = "Absolute change to latest value (percentage points)",
       title = "Recent weeks get revised, and the newest week moves the most",
       subtitle = "National, MMWR 2022 week 40 onward. Each box: |latest value - value published at that lag| across weeks.",
       caption = cap(paste0(src_ili, ";\n", src_clin))) +
  theme_blog()
save_png(p4, "04_revisions_by_lag.png")

# 5/6. Season overlays (2022-23 onward), National and Region 6 ----------------------
overlay <- function(df, y, ylab, title, src) {
  ggplot(df |> filter(region %in% two_regions, season %in% c(baseline, focus)),
         aes(season_week, {{ y }}, colour = season, linewidth = season, group = season)) +
    geom_line() +
    facet_wrap(~region, labeller = as_labeller(region_lab)) +
    scale_colour_manual(values = pal_season, name = "Season") +
    scale_linewidth_manual(values = lw_season, guide = "none") +
    scale_y_continuous(labels = label_percent(scale = 1), limits = c(0, NA)) +
    x_season +
    labs(x = xlab_season, y = ylab, title = title,
         subtitle = paste0("2025-26 (orange) vs. the three prior seasons. Earlier seasons are left out: ILINet's ILI ",
                           "definition changed in week 40 of 2021,\nand 2020-21/2021-22 were distorted by COVID-19."),
         caption = cap(src)) +
    theme_blog() +
    guides(colour = guide_legend(override.aes = list(linewidth = 1.3)))
}
save_png(overlay(ili, wili, "Weighted %ILI",
                 "Outpatient influenza-like illness: 2025-26 vs. recent seasons", src_ili),
         "05_wili_season_overlay_national_region6.png")
save_png(overlay(clin, pct_positive, "% of specimens positive",
                 "Clinical lab flu test positivity: 2025-26 vs. recent seasons", src_clin),
         "06_clinical_positivity_overlay_national_region6.png")

# 7. Regions vs their own baselines -------------------------------------------------
reg_long <- bind_rows(
  regional |> transmute(region, metric = "Peak weighted %ILI", lo = base_min_wili,
                        hi = base_max_wili, val = peak_wili),
  regional |> transmute(region, metric = "Peak clinical % positive", lo = base_min_pos,
                        hi = base_max_pos, val = peak_pct_positive)
) |>
  mutate(region = factor(region, rev(c("National", paste("Region", 1:10)))),
         above = val > hi)
p7 <- ggplot(reg_long, aes(y = region)) +
  geom_linerange(aes(xmin = lo, xmax = hi), linewidth = 4, colour = "#c6dbef") +
  geom_point(aes(x = val, colour = above), size = 3) +
  facet_wrap(~metric, scales = "free_x") +
  scale_colour_manual(values = c(`TRUE` = "#e6550d", `FALSE` = "#08519c"),
                      labels = c(`TRUE` = "2025-26 peak above prior range", `FALSE` = "2025-26 peak within/below range"),
                      name = NULL) +
  scale_x_continuous(labels = label_percent(scale = 1)) +
  labs(x = NULL, y = NULL,
       title = "Each region against its own history",
       subtitle = "Dot = 2025-26 season peak. Bar = range of peaks in 2022-23, 2023-24 and 2024-25 for the same region.",
       caption = cap(paste0(src_ili, ";\n", src_clin))) +
  theme_blog()
save_png(p7, "07_regions_vs_own_baseline.png")

# 8. Latest weeks, provisional ------------------------------------------------------
recent <- bind_rows(
  ili  |> transmute(region, week_end, epiweek, metric = "Weighted %ILI", value = wili),
  clin |> transmute(region, week_end, epiweek, metric = "Clinical % positive", value = pct_positive)
) |>
  filter(region %in% two_regions, week_end > max(week_end) - 7 * 20) |>
  mutate(region = recode(region, !!!region_lab),
         metric = factor(metric, c("Weighted %ILI", "Clinical % positive")))
shade_from <- max(recent$week_end) - 7 * 3 + 0.5
p8 <- ggplot(recent, aes(week_end, value, colour = region)) +
  annotate("rect", xmin = shade_from, xmax = max(recent$week_end) + 3.5, ymin = -Inf, ymax = Inf,
           fill = "grey85", alpha = 0.6) +
  geom_line(linewidth = 1) + geom_point(size = 1.5) +
  facet_wrap(~metric, scales = "free_y") +
  scale_colour_manual(values = c("#08519c", "#e6550d"), name = NULL) +
  scale_y_continuous(labels = label_percent(scale = 1), limits = c(0, NA)) +
  scale_x_date(date_breaks = "1 month", date_labels = "%b %d") +
  labs(x = "Week ending", y = NULL,
       title = "Heading into 2026-27: the latest weeks",
       subtitle = paste0("Last 20 published weeks. Shaded = most recent 3 weeks, preliminary and likely to be revised. ",
                         "No 2026-27 season weeks (MMWR week 40+) were published as of the pull date."),
       caption = cap(paste0(src_ili, ";\n", src_clin))) +
  theme_blog()
save_png(p8, "08_latest_weeks_preliminary.png")

# 9. Public health lab subtype mix by season (national) ----------------------------
phl_mix <- phl |>
  filter(region == "National") |>
  transmute(season,
            `A(H1N1)pdm09` = a_h1n1pdm09, `A(H3N2)` = a_h3, `A, not subtyped` = a_not_subtyped,
            `A(H5)` = a_h5, `A(H3N2)v` = a_h3n2v,
            `B/Victoria` = b_victoria, `B/Yamagata` = b_yamagata, `B, lineage not determined` = b_lineage_nd) |>
  pivot_longer(-season, names_to = "virus", values_to = "n") |>
  group_by(season) |> mutate(share = n / sum(n)) |> ungroup() |>
  filter(n > 0) |>
  mutate(virus = factor(virus, c("A(H1N1)pdm09", "A(H3N2)", "A(H3N2)v", "A(H5)", "A, not subtyped",
                                 "B/Victoria", "B/Yamagata", "B, lineage not determined")))
p9 <- ggplot(phl_mix, aes(season, share, fill = virus)) +
  geom_col(width = 0.75) +
  geom_text(aes(label = if_else(share >= 0.06, percent(share, 1), "")),
            position = position_stack(vjust = 0.5), size = 3, colour = "white") +
  scale_fill_manual(values = c("A(H1N1)pdm09" = "#08519c", "A(H3N2)" = "#e6550d", "A(H3N2)v" = "#fdae6b",
                               "A(H5)" = "#a50f15", "A, not subtyped" = "#969696",
                               "B/Victoria" = "#31a354", "B/Yamagata" = "#a1d99b",
                               "B, lineage not determined" = "#c7e9c0"), name = NULL) +
  scale_y_continuous(labels = percent, expand = expansion(mult = c(0, 0.02))) +
  labs(x = NULL, y = "Share of positive specimens",
       title = "Which flu viruses public health labs found, by season",
       subtitle = "National share of influenza-positive specimens tested by public health labs. Descriptive only: PHL testing is not a random sample.",
       caption = cap(src_phl)) +
  theme_blog() + guides(fill = guide_legend(nrow = 2))
save_png(p9, "09_public_health_lab_subtypes.png")
