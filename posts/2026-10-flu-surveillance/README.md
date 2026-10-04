# Flying Blind Into Flu Season

Companion code for the Notes from the Abstracts post (week of Oct 12, 2026). The question
here is less "how bad was last season?" and more **is federal flu surveillance still flowing
and complete, and what does it show going into 2026-27?**

All numbers come from data pulled on **2026-10-04** (latest published week: MMWR 2026 week 38,
week ending Sep 26, 2026, CDC issue released Oct 2, 2026). Re-running the scripts pulls fresh
data, so values for recent weeks will change.

## What's in here

| Figure | What it shows |
|---|---|
| `figures/01_data_flow_providers_specimens.png` | Median ILINet providers reporting per week, and total clinical-lab specimens tested, by season (national) |
| `figures/02_providers_by_hhs_region.png` | Median ILINet providers per week by HHS region and season |
| `figures/03_revisions_first_vs_latest_2025_26.png` | For each 2025-26 week: latest value minus first-published value (wILI and clinical % positive) |
| `figures/04_revisions_by_lag.png` | How far values published 0-4 weeks after the data week end up from today's value (2022-23 onward) |
| `figures/05_wili_season_overlay_national_region6.png` | Weighted %ILI by season week, 2025-26 vs 2022-23 to 2024-25, national and HHS Region 6 |
| `figures/06_clinical_positivity_overlay_national_region6.png` | Same, for clinical-lab % positive |
| `figures/07_regions_vs_own_baseline.png` | Each region's 2025-26 peak against the range of its own 2022-23 to 2024-25 peaks |
| `figures/08_latest_weeks_preliminary.png` | Last 20 published weeks, national and Region 6; most recent 3 weeks shaded as preliminary |
| `figures/09_public_health_lab_subtypes.png` | Influenza A subtype / B lineage mix from public health labs, by season |
| `figures/10_fluview_release_gaps.png` | Days between consecutive weekly ILINet releases (Delphi issue archive) |

Tidy outputs in `data/` (all CSV): weekly ILINet and clinical-lab series for national + 10 HHS
regions, public health lab counts, season peaks, data-flow summary, first-release vs latest
values, revisions by lag, release calendar, regional baseline comparison, and a Delphi-vs-CDC
cross-check of the clinical-lab numbers. Raw API responses are cached in `data/raw/`; CDC's 2025-26
ILI baselines (hand-transcribed, with source) are in `data/reference/`.

## Key findings (pulled 2026-10-04)

**Is the data flowing?**
- ILINet coverage kept growing: median providers reporting per week went from 2,938 (2019-20) to
  4,302 (2025-26), the highest in the series.
- Clinical-lab specimens tested fell to 3.16M in 2025-26 from 4.20-4.24M in each of the three
  prior seasons (about 25% lower). 2025-26 is one week short of complete (through week 38 of a
  53-week season), so that explains little of the gap. **This is worth investigating, not a
  finding**: fewer labs reporting, less testing, or a reporting change would all look the same here.
  The drop is broad: Region 6 fell 20% (553k in 2024-25 to 442k), close to the national 25%, and
  is not a low for the region (2019-20 and 2020-21 were lower).
- Region 6 (AR, LA, NM, OK, TX) is moving the other way on outpatient reporting: a median of 227
  ILINet providers per week in 2025-26, its lowest in the seven seasons (279.5 in 2019-20). The decline
  is gradual (250.5, 254.5, 247.5, then 227 from 2022-23 to 2025-26), with most of it in the last
  season (-8%).
- **Release gap:** Delphi's archive has no new ILINet issue between Sep 26, 2025 (week 38 data)
  and Nov 14, 2025 (week 45 data), a 49-day gap. Weeks 39-44 of 2025 were first published in
  bulk on Nov 14 (see "Context: the 2025 shutdown" below). No other gap in the Delphi archive since
  2022 comes close: the next longest is 11 days (Aug 9-20, 2025 and Dec 19-30, 2025), followed by
  several 10-day gaps such as Nov 18-28, 2022. These are Delphi ingestion dates, so a 10-11 day gap
  usually means a holiday or a late ingest, not a missed CDC week.

**Revisions:**
- 2025 week 52 weighted %ILI was 8.25% at first release and is 8.30% now. Clinical positivity
  for the same week was first published at 32.9% and is 31.7% now.
- The two systems revise in opposite directions. Across the 51 weeks of 2025-26 with an archived
  first release, wILI was revised **up** in 92% of weeks (median 0.01 points; 0.5% of the value),
  consistent with late provider reports. Clinical % positive was revised **down** in 67% of weeks
  (34 of 51; 68% if the not-yet-revised latest week is excluded), and by more: median 0.11 points,
  3.7% of the value, largest -1.44 points (week ending Feb 14, 2026). Summed over the season, revisions
  are 3.5% of the positivity values and 0.6% of the ILI values.
- Since 2022-23, a value published in its own week (lag 0) ends up a median of 0.08 points away
  from today's value for clinical % positive (90th percentile 0.67) and 0.03 points for wILI
  (90th percentile 0.07).

**2025-26 vs prior seasons (2022-23 onward only):**
- National weighted %ILI peaked at 8.30% in week 52 (week ending Dec 27, 2025), above the 6.80% to
  7.84% peaks of 2022-23 to 2024-25 and well above CDC's 2025-26 national baseline of 3.1%. Clinical
  positivity peaked at 31.7% the same week, essentially tied with 2024-25 (31.6%).
- Regions are compared with their own history and their own CDC baselines, because CDC says "it is
  not appropriate to apply the national baseline to regional data"
  ([CDC surveillance methods](https://www.cdc.gov/fluview/overview/index.html)). 2025-26 ILI peaks
  were above the 2022-25 range in Regions 1, 2 and 7 (Region 2: 13.6% vs a prior max of 9.2%;
  baseline 4.5%) and below it only in Region 9 (5.81% vs a prior min of 7.29%). Region 6 peaked at
  8.87% wILI (inside its 8.29-10.27% range; baseline 4.1%) and 38.1% positivity (just above its prior
  max, 37.3%).
- Public health labs: of subtyped influenza A in 2025-26, 84% was A(H3N2) and 16% A(H1N1)pdm09,
  after two seasons where H1N1pdm09 was the larger share (64% in 2023-24, 53% in 2024-25). See the
  subtype caveats below the context sections.

**Heading into 2026-27:**
- As of the pull date no 2026-27 weeks exist yet; the season starts with MMWR week 40 (week of
  Oct 4, 2026). The latest week, 2026 week 38, is the tail of 2025-26. CDC's week 38 report says
  "Seasonal influenza activity remains low nationally, but is increasing"
  ([week 38 report](https://www.cdc.gov/fluview/surveillance/2026-week-38.html)).
- Week 38 national wILI was 1.74% (below the 3.1% baseline), and clinical positivity 3.43%. **That 3.43%
  is a first release based on 33,547 specimens.** Week 38 in the three prior seasons ended up with
  57,000-63,000 specimens (56,976 in 2025, 63,235 in 2024, 61,602 in 2023; 67,455 in 2022), and even
  their first releases had 45,194, 46,909 and 42,904. So this week is thin and likely to be revised,
  and clinical positivity has more often been revised down than up.
- With that caveat, positivity has risen for three weeks (1.76% → 2.60% → 3.43%), and 3.43% is above
  every earlier week 38 in this data (the highest was 1.25% in 2022). Region 6 went 1.16% → 1.85% →
  3.00%; its wILI (1.80%) is below its 4.1% baseline.
- **Rerun after Fri Oct 9, 2026**, when week 39 posts. Week 39 closes the 2025-26 season, which has a
  week 53 (2025 had 53 MMWR weeks), so 2025-26 will have 53 weeks in total.

## Context: the 2025 shutdown and the release gap

- The federal funding lapse ran from Oct 1 to Nov 12, 2025 ([CRS R48832](https://www.congress.gov/crs-product/R48832)).
- CDC's national flu data were not updated during the lapse. The first post-shutdown FluView data
  went out Nov 14, 2025, covering the week ending Nov 8, after what Becker's called "a nearly
  two-month blackout in national reporting"
  ([Becker's Hospital Review](https://www.beckershospitalreview.com/quality/public-health/cdc-flu-data-updated-for-the-first-time-in-2-months-5-notes/)).
  Delphi's archive agrees: the next issue after Sep 26 was ingested Nov 14 and carried weeks 39-45.
- **The networks kept collecting; CDC paused analysis and publishing.** The backfilled weeks show full
  participation: 4,325-4,343 ILINet providers per week for weeks 40-44 of 2025, versus 4,032 in week 39.
  Some components were not backfilled right away: CDC's week 44 report says NCHS mortality data for
  weeks 40-44 "were not available for inclusion"
  ([week 44 report](https://www.cdc.gov/fluview/surveillance/2025-week-44.html)), and the week 47 report
  extends that to weeks 39-47.
- Since Nov 14, 2025, ILINet and WHO/NREVSS have published weekly; figure 10 shows no further gaps
  longer than 11 days.
- **Texas.** The Texas DSHS respiratory virus report for 2025 week 42 (Oct 12-18, 2025) says: "Since
  September 29, 2025, CDC has reported subtype final/antigenic characterization results from Zero (0)
  Influenza A (H1N1), Zero (0) Influenza A (H3N2), and Zero (0) Influenza B virus received from the
  Texas Department of State Health Services (DSHS) Laboratory and the City of Houston Department of
  Health" ([DSHS week 42 report, PDF](https://www.dshs.texas.gov/sites/default/files/IDCU/disease/respiratory_virus_surveillance/2025/2025-week42-trvsreport.pdf)).

## Context: how severe was 2025-26?

These come from CDC's weekly reports, not from this repo's data.
- FluSurv-NET counted 31,513 laboratory-confirmed influenza hospitalizations between Oct 1, 2025 and
  Sep 26, 2026, a cumulative rate of 90.0 per 100,000. A total of 195 influenza-associated pediatric
  deaths had been reported for the season as of week 38
  ([week 38 report](https://www.cdc.gov/fluview/surveillance/2026-week-38.html)).
- CDC's in-season severity framework "classified the season as moderate across all ages," with the
  pediatric age group "classified as having high severity" and adults and older adults moderate
  ([week 20 report](https://www.cdc.gov/fluview/surveillance/2026-week-20.html), the last full report
  of the season).

## Data sources

- **ILINet** (U.S. Outpatient Influenza-like Illness Surveillance Network) and **WHO/NREVSS
  clinical laboratories**, via the [Delphi Epidata API](https://cmu-delphi.github.io/delphi-epidata/)
  endpoints [`fluview`](https://cmu-delphi.github.io/delphi-epidata/api/fluview.html) and
  [`fluview_clinical`](https://cmu-delphi.github.io/delphi-epidata/api/fluview_clinical.html).
  Delphi mirrors CDC FluView and keeps every weekly release ("issue"), which is what makes the
  revision and release-gap analyses possible.
- **WHO/NREVSS public health laboratories** (subtypes and lineages) and a second copy of the
  clinical-lab file, downloaded from [CDC FluView Interactive](https://gis.cdc.gov/grasp/fluview/fluportaldashboard.html).
  The clinical-lab numbers from Delphi and CDC matched exactly for all 4,015 region-weeks.
- **ILI baselines** for 2025-26 (national 3.1%, Region 6 4.1%, and the other regions) from CDC's
  [U.S. Influenza Surveillance: Purpose and Methods](https://www.cdc.gov/fluview/overview/index.html):
  the mean %ILI during non-influenza weeks of 2022-23 to 2024-25 plus two standard deviations. They are
  drawn as reference lines in figures 05, 07 and 08.

`cdcfluview` was archived from CRAN, so the scripts call the APIs directly with `httr`.

## How to run

Requires R (4.3+), the tidyverse, `httr`, `jsonlite`, `scales` and `ragg`. For the brand fonts,
install the Google Fonts [Jost](https://fonts.google.com/specimen/Jost) and
[Karla](https://fonts.google.com/specimen/Karla).

```sh
cd posts/2026-10-flu-surveillance
Rscript run_all.R          # or: Rscript 01_fetch.R && Rscript 02_clean.R && Rscript 03_plots.R
```

`01_fetch.R` makes 12 Delphi requests. Anonymous Delphi access is limited to 60 requests per
hour; set a free API key in `DELPHI_API_KEY` if you hit the limit.

## Caveats

- **ILI is syndromic, not flu-specific.** It counts visits for fever plus cough or sore throat,
  which RSV, COVID-19 and other viruses also cause. Use clinical-lab % positive for flu timing and
  public health labs for subtypes.
- **Use percentages, not counts.** Provider and lab participation changes from year to year (see
  figures 01 and 02), so raw counts of ILI visits or positive tests aren't comparable across seasons.
- **Recent weeks get backfilled.** The newest weeks are preliminary and are revised as late reports
  arrive (figures 03 and 04). The last three weeks are shaded in figure 08 for this reason.
- **ILI definition change.** Since week 40 of 2021, ILINet's definition no longer includes "without a
  known cause other than influenza," and 2020-21/2021-22 were also distorted by COVID-19, so the season
  comparisons use 2022-23 onward only.
- **Baselines are season-specific.** The CDC baselines drawn in the figures are for 2025-26; earlier
  seasons had their own baselines. Each region is compared with its own baseline and its own prior
  peaks, never with national figures.
- **Public health lab subtype data are descriptive.** PHL specimens are not a random sample (many are
  forwarded after testing positive at a clinical lab), so subtype shares describe what was tested,
  not population prevalence. Separately, CDC's 2025-26 "Right Size" guidance asks each public health
  lab to submit to CDC, every other week if available, 4 A(H1N1)pdm09, 6 A(H3N2) and 4 influenza B
  specimens for genetic and antigenic characterization, so "the number of viruses characterized will
  not reflect the actual proportion of circulating viruses"
  ([CDC surveillance methods](https://www.cdc.gov/fluview/overview/index.html)). That cap applies to
  CDC's characterization data, not to the PHL subtype counts in figure 09.
- **Release dates** come from Delphi's ingestion of each CDC issue and can trail CDC's own publication
  by a day or more. MMWR 2025 weeks 39-40 have no archived release within four weeks, so they're
  missing from the first-release comparison.
- **CDC database pauses.** An Annals of Internal Medicine study audited CDC's public database catalog
  on Oct 28, 2025 and found 38 of 82 databases that had been updated at least monthly were paused.
  Most covered vaccination for influenza, COVID-19 or RSV; others covered RSV disease burden,
  nirsevimab effectiveness, respiratory illnesses treated in emergency departments, and provisional
  overdose deaths. The audit date fell during the shutdown (day 27), though the authors say most
  pauses began in March-April 2025
  ([Medscape](https://www.medscape.com/viewarticle/many-cdc-databases-significantly-paused-2025-2026a10002lt)).
  The ILINet and WHO/NREVSS feeds used here resumed after the shutdown and have published weekly since.
