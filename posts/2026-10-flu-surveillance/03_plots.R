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
revsum   <- rd("revision_summary_2025_26.csv")
baselines <- read_csv("data/reference/cdc_ili_baselines_2025_26.csv", show_col_types = FALSE)
src_base <- "2025-26 ILI baselines: CDC, cdc.gov/fluview/overview/index.html"

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
nc <- nfta_colors  # brand palette from ../../R/theme_blog.R
pal_season <- c("2022-23" = nc[["tertiary"]], "2023-24" = nc[["secondary"]],
                "2024-25" = nc[["foreground"]], "2025-26" = nc[["primary"]])
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
  mutate(name = fct_inorder(name)) |>
  mutate(label = if_else(str_detect(name, "millions"), sprintf("%.2fM", value), comma(value, 1)))
p1 <- ggplot(flow_nat, aes(season, value, fill = season == focus)) +
  geom_col(width = 0.7) +
  geom_text(aes(label = label), vjust = -0.4, size = 3.3, family = nfta_fonts[["body"]], colour = nc[["foreground"]]) +
  facet_wrap(~name, scales = "free_y") +
  scale_fill_manual(values = c(`TRUE` = nc[["primary"]], `FALSE` = nc[["secondary"]]), guide = "none") +
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
                colour = median_providers > 600),
            size = 3.2, family = nfta_fonts[["body"]]) +
  scale_colour_manual(values = c(`TRUE` = nc[["background"]], `FALSE` = nc[["foreground"]]), guide = "none") +
  scale_fill_nfta_c(name = "Median providers/week", labels = comma) +
  labs(x = NULL, y = NULL,
       title = "ILINet reporting depth varies a lot by HHS region",
       subtitle = "Median number of ILINet providers reporting per week, by HHS region and season",
       caption = cap(src_ili, "Region 6 = AR, LA, NM, OK, TX. Provider counts reflect the latest release; late reports keep arriving for recent weeks.")) +
  theme_blog() + theme(panel.grid = element_blank(), legend.key.width = unit(1.5, "cm"), legend.title = element_text(vjust = 0.8))
save_png(p2, "02_providers_by_hhs_region.png")

# 3. Revisions: first release vs latest, 2025-26, national --------------------------
rev25 <- first |>
  filter(region == "National", season == focus) |>
  mutate(direction = if_else(revision >= 0, "Revised up", "Revised down"))
rev25_lab <- rev25 |> group_by(metric) |>
  summarise(lab = sprintf("Median |revision| %.2f pts; largest %+.2f pts (week ending %s)",
                          median(abs(revision)), revision[which.max(abs(revision))],
                          format(week_end[which.max(abs(revision))], "%b %d, %Y")), .groups = "drop")
p3 <- ggplot(rev25, aes(week_end, revision, fill = direction)) +
  geom_hline(yintercept = 0, colour = nc[["foreground"]], linewidth = 0.4) +
  geom_col(width = 6) +
  geom_text(data = rev25_lab, aes(x = min(rev25$week_end), y = Inf, label = lab), inherit.aes = FALSE,
            hjust = 0, vjust = 1.3, size = 3.1, family = nfta_fonts[["body"]], colour = nc[["muted_foreground"]]) +
  facet_wrap(~metric, scales = "free_y", ncol = 1) +
  scale_fill_manual(values = c("Revised up" = nc[["primary"]], "Revised down" = nc[["secondary"]]), name = NULL) +
  scale_y_continuous(labels = \(x) sprintf("%+.2f", x), expand = expansion(mult = c(0.1, 0.35))) +
  scale_x_date(date_breaks = "1 month", date_labels = "%b\n%Y") +
  labs(x = "Week ending", y = "Latest minus first release (pct. points)",
       title = "First release vs. today: how much 2025-26 numbers moved",
       subtitle = with(revsum, sprintf(paste0(
         "National, 2025-26. First release = earliest archived Delphi issue (lag 0 where available, else lag 1-4).\n2025 weeks 39-40 are not shown (no release within 4 weeks; see fig. 10). ",
         "wILI was revised up in %s of weeks\n(median relative change %s); clinical %% positive was revised down in %s of weeks (median relative change %s)."),
         percent(share_revised_up[metric == "Weighted %ILI"], 1), percent(median_relative_revision[metric == "Weighted %ILI"], 0.1),
         percent(share_revised_down[metric == "Clinical % positive"], 1), percent(median_relative_revision[metric == "Clinical % positive"], 0.1))),
       caption = cap(paste0(src_ili, ";\n", src_clin))) +
  theme_blog()
save_png(p3, "03_revisions_first_vs_latest_2025_26.png")

# 4. Revisions by lag: absolute change from each early release to latest -----------
rev_lag <- revlag |>
  filter(region == "National", epiweek < .env$latest - 4) |>   # skip weeks too new to have settled
  mutate(lag = factor(lag), abs_rev = abs(revision))
rev_lag_sum <- rev_lag |> group_by(metric, lag) |>
  summarise(med = median(abs_rev), p90 = quantile(abs_rev, 0.9), n = n(), .groups = "drop")
p4 <- ggplot(rev_lag, aes(lag, abs_rev)) +
  geom_boxplot(outlier.alpha = 0.4, outlier.colour = nc[["muted_foreground"]], fill = nc[["tertiary"]], colour = nc[["foreground"]], width = 0.6) +
  geom_text(data = rev_lag_sum, aes(y = Inf, label = sprintf("median\n%.2f", med)),
            vjust = 1.2, size = 3, lineheight = 0.9, colour = nc[["muted_foreground"]], family = nfta_fonts[["body"]]) +
  facet_wrap(~metric, scales = "free_y") +
  scale_y_continuous(expand = expansion(mult = c(0.02, 0.18))) +
  labs(x = "Weeks after the data week when the value was published (lag)",
       y = "Absolute change to latest value (percentage points)",
       title = "Recent weeks get revised; first-release lab positivity moves the most",
       subtitle = "National, MMWR 2022 week 40 onward. Each box: |latest value - value published at that lag| across weeks.",
       caption = cap(paste0(src_ili, ";\n", src_clin))) +
  theme_blog()
save_png(p4, "04_revisions_by_lag.png")

# 5/6. Season overlays (2022-23 onward), National and Region 6 ----------------------
overlay <- function(df, y, ylab, title, src, show_baseline = FALSE) {
  bl <- baselines |> filter(region %in% two_regions) |>
    mutate(label = sprintf("CDC 2025-26 baseline %.1f%%", baseline_wili))
  ggplot(df |> filter(region %in% two_regions, season %in% c(baseline, focus)),
         aes(season_week, {{ y }}, colour = season, linewidth = season, group = season)) +
    { if (show_baseline) list(
        geom_hline(data = bl, aes(yintercept = baseline_wili),
                   colour = nc[["muted_foreground"]], linetype = "22", linewidth = 0.5),
        geom_text(data = bl, aes(x = 52, y = baseline_wili, label = label), inherit.aes = FALSE,
                  hjust = 1, vjust = -0.5, size = 3, family = nfta_fonts[["body"]],
                  colour = nc[["muted_foreground"]])) } +
    geom_line() +
    facet_wrap(~region, labeller = as_labeller(region_lab)) +
    scale_colour_manual(values = pal_season, name = "Season") +
    scale_linewidth_manual(values = lw_season, guide = "none") +
    scale_y_continuous(labels = label_percent(scale = 1), limits = c(0, NA)) +
    x_season +
    labs(x = xlab_season, y = ylab, title = title,
         subtitle = paste0("2025-26 (red) vs. the three prior seasons. Earlier seasons are left out: ILINet's ILI ",
                           "definition changed in week 40 of 2021,\nand 2020-21/2021-22 were distorted by COVID-19."),
         caption = cap(src, if (show_baseline) paste0(src_base, ". Each panel uses its own baseline; CDC: the national baseline should not be applied to regional data.") else NULL)) +
    theme_blog() +
    guides(colour = guide_legend(override.aes = list(linewidth = 1.3)))
}
save_png(overlay(ili, wili, "Weighted %ILI",
                 "Outpatient influenza-like illness: 2025-26 vs. recent seasons", src_ili, show_baseline = TRUE),
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
  geom_linerange(aes(xmin = lo, xmax = hi), linewidth = 4, colour = nc[["tertiary"]]) +
  geom_point(aes(x = val, colour = above), size = 3) +
  geom_point(data = baselines |> mutate(metric = "Peak weighted %ILI",
                                        region = factor(region, levels(reg_long$region))),
             aes(x = baseline_wili, shape = "CDC 2025-26 ILI baseline"),
             colour = nc[["muted_foreground"]], size = 3) +
  scale_shape_manual(values = c("CDC 2025-26 ILI baseline" = 124), name = NULL) +
  facet_wrap(~metric, scales = "free_x") +
  scale_colour_manual(values = c(`TRUE` = nc[["primary"]], `FALSE` = nc[["foreground"]]),
                      labels = c(`TRUE` = "2025-26 peak above prior range", `FALSE` = "2025-26 peak within/below range"),
                      name = NULL) +
  scale_x_continuous(labels = label_percent(scale = 1)) +
  labs(x = NULL, y = NULL,
       title = "Each region against its own history",
       subtitle = "Dot = 2025-26 season peak. Bar = range of peaks in 2022-23, 2023-24 and 2024-25 for the same region.",
       caption = cap(paste0(src_ili, ";\n", src_clin), src_base)) +
  theme_blog()
save_png(p7, "07_regions_vs_own_baseline.png")

# 8. Latest weeks, provisional ------------------------------------------------------
recent <- bind_rows(
  ili  |> transmute(region, week_end, epiweek, metric = "Weighted %ILI", value = wili),
  clin |> transmute(region, week_end, epiweek, metric = "Clinical % positive", value = pct_positive)
) |>
  filter(region %in% two_regions, week_end > max(week_end) - 7 * 20) |>
  mutate(region = factor(recode(region, !!!region_lab), unname(region_lab)),
         metric = factor(metric, c("Weighted %ILI", "Clinical % positive")))
shade_from <- max(recent$week_end) - 7 * 3 + 0.5
bl8 <- baselines |> filter(region %in% two_regions) |>
  mutate(region = factor(recode(region, !!!region_lab), unname(region_lab)),
         metric = factor("Weighted %ILI", levels(recent$metric)))
p8 <- ggplot(recent, aes(week_end, value, colour = region)) +
  geom_hline(data = bl8, aes(yintercept = baseline_wili, colour = region), linetype = "22",
             linewidth = 0.5, show.legend = FALSE) +
  geom_text(data = bl8, aes(x = min(recent$week_end), y = baseline_wili,
                            label = sprintf("%s 2025-26 baseline %.1f%%", if_else(str_detect(region, "Region"), "Region 6", "National"), baseline_wili)),
            hjust = 0, vjust = -0.5, size = 3, family = nfta_fonts[["body"]], show.legend = FALSE) +
  annotate("rect", xmin = shade_from, xmax = max(recent$week_end) + 3.5, ymin = -Inf, ymax = Inf,
           fill = nc[["muted"]], alpha = 1) +
  geom_line(linewidth = 1) + geom_point(size = 1.5) +
  facet_wrap(~metric, scales = "free_y") +
  scale_colour_manual(values = c(nc[["secondary"]], nc[["primary"]]), name = NULL) +
  scale_y_continuous(labels = label_percent(scale = 1), limits = c(0, NA)) +
  scale_x_date(date_breaks = "1 month", date_labels = "%b %d") +
  labs(x = "Week ending", y = NULL,
       title = "Heading into 2026-27: the latest weeks",
       subtitle = with(clin |> filter(region == "National", epiweek == max(epiweek)), sprintf(paste0(
         "Last 20 published weeks. Shaded = most recent 3 weeks, preliminary.\nThe latest week is a first release: national positivity %.1f%% from %s specimens (first releases for week 38 in 2023-2025 had 43-47k).\n",
         "No 2026-27 weeks (MMWR week 40+) were published as of the pull date."),
         pct_positive, comma(total_specimens))),
       caption = cap(paste0(src_ili, ";\n", src_clin), src_base)) +
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
            position = position_stack(vjust = 0.5), size = 3, colour = nc[["background"]], family = nfta_fonts[["body"]]) +
  scale_fill_manual(values = c("A(H1N1)pdm09" = nc[["secondary"]], "A(H3N2)" = nc[["primary"]],
                               "A(H3N2)v" = nc[["accent"]], "A(H5)" = nc[["destructive"]],
                               "A, not subtyped" = nc[["muted_foreground"]],
                               "B/Victoria" = nc[["success"]], "B/Yamagata" = nc[["chart_5"]],
                               "B, lineage not determined" = nc[["tertiary"]]), name = NULL) +
  scale_y_continuous(labels = percent, expand = expansion(mult = c(0, 0.02))) +
  labs(x = NULL, y = "Share of positive specimens",
       title = "Which flu viruses public health labs found, by season",
       subtitle = with(filter(phl, region == "National", season == focus),
                       sprintf(paste0("National share of influenza-positive specimens tested by public health labs. Descriptive only: PHL testing is not a random sample.\n",
                                      "%s: of subtyped influenza A, %s were A(H3N2) and %s A(H1N1)pdm09."),
                               focus, percent(share_h3_of_subtyped_a, 1), percent(share_h1_of_subtyped_a, 1))),
       caption = cap(src_phl, paste0("Not a random sample: PHLs often receive specimens already positive at clinical labs. Separately, CDC's 2025-26 'Right Size' guidance asks each PHL to send CDC,\n",
                                      "every other week, up to 4 A(H1N1)pdm09, 6 A(H3N2) and 4 B specimens for characterization (cdc.gov/fluview/overview); that limits CDC's genetic data, not the PHL counts shown here."))) +
  theme_blog() + guides(fill = guide_legend(nrow = 2))
save_png(p9, "09_public_health_lab_subtypes.png")

# 10. Release calendar: was FluView published every week? -----------------------
rel <- rd("fluview_release_calendar.csv") |> filter(!is.na(days_since_prev))
gap <- rel |> slice_max(days_since_prev, n = 1)
p10 <- ggplot(rel, aes(release_date, days_since_prev)) +
  geom_hline(yintercept = 7, colour = nc[["muted_foreground"]], linetype = "22") +
  geom_segment(aes(xend = release_date, y = 0, yend = days_since_prev),
               colour = if_else(rel$days_since_prev > 14, nc[["primary"]], nc[["secondary"]]), linewidth = 0.7) +
  geom_point(aes(colour = days_since_prev > 14), size = 1.6) +
  annotate("text", x = gap$release_date, y = gap$days_since_prev, hjust = 1.05, vjust = 0.4,
           family = nfta_fonts[["body"]], size = 3.3, colour = nc[["foreground"]],
           label = sprintf("%d days with no new release,\nending %s (MMWR %d-%02d issue)",
                           gap$days_since_prev, format(gap$release_date, "%b %d, %Y"),
                           gap$issue %/% 100, gap$issue %% 100)) +
  scale_colour_manual(values = c(`TRUE` = nc[["primary"]], `FALSE` = nc[["secondary"]]), guide = "none") +
  scale_y_continuous(breaks = c(0, 7, 14, 28, 42, 49), expand = expansion(mult = c(0, 0.08))) +
  scale_x_date(date_breaks = "6 months", date_labels = "%b\n%Y") +
  labs(x = "Release date", y = "Days since previous release",
       title = "Is the data still flowing? One long break in weekly releases",
       subtitle = "Each spike = one weekly ILINet/FluView issue as archived by Delphi; height = days since the previous issue (dashed line = 7 days).\nDates are when Delphi ingested each release and can trail CDC publication.\nThe long gap spans the Oct 1-Nov 12, 2025 federal funding lapse (CRS R48832).",
       caption = cap(src_ili, "Release dates from Delphi's issue archive (lag 0-4 pulls), MMWR 2022 week 40 onward.")) +
  theme_blog()
save_png(p10, "10_fluview_release_gaps.png")
