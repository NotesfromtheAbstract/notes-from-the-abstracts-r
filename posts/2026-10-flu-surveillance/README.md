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
cross-check of the clinical-lab numbers. Raw API responses are cached in `data/raw/`.

## Key findings (pulled 2026-10-04)

**Is the data flowing?**
- ILINet coverage kept growing: median providers reporting per week went from 2,938 (2019-20) to
  4,302 (2025-26), the highest in the series.
- Clinical-lab specimens tested fell to 3.16M in 2025-26 from 4.20-4.24M in each of the three
  prior seasons (about 25% lower). 2025-26 is one week short of complete (through week 38 of a
  53-week season), so that explains little of the gap. **This is worth investigating, not a
  finding**: fewer labs reporting, less testing, or a reporting change would all look the same here.
- Region 6 (AR, LA, NM, OK, TX) is moving the other way on outpatient reporting: a median of 227
  ILINet providers per week in 2025-26, its lowest in the seven seasons (279.5 in 2019-20, 250.5 in
  2022-23). Its clinical specimens fell from 553k in 2024-25 to 442k.
- **Release gap:** Delphi's archive has no new ILINet issue between Sep 26, 2025 (week 38 data)
  and Nov 14, 2025 (week 45 data), a 49-day gap. Weeks 39-44 of 2025 were first published in
  bulk on Nov 14. That window lines up with the Oct 1 - Nov 12, 2025 federal government shutdown.
  Every other gap since 2022 was 11 days or less.

**Revisions:**
- 2025 week 52 weighted %ILI was 8.25% at first release and is 8.30% now. Clinical positivity
  for the same week was first published at 32.9% and is 31.7% now.
- Across 2025-26, ILI revisions are small (median 0.01 points, largest +0.06) and almost always
  upward (92% of weeks), consistent with late provider reports. Clinical % positive moves more
  (median 0.11 points, largest -1.44 points for the week ending Feb 14, 2026).
- Since 2022-23, a value published in its own week (lag 0) ends up a median of 0.08 points away
  from today's value for clinical % positive (90th percentile 0.67) and 0.03 points for wILI
  (90th percentile 0.07).

**2025-26 vs prior seasons (2022-23 onward only):**
- National weighted %ILI peaked at 8.30% in week 52 (week ending Dec 27, 2025), above the 6.80% to
  7.84% peaks of 2022-23 to 2024-25. Clinical positivity peaked at 31.7% the same week, essentially
  tied with 2024-25 (31.6%).
- Against their own history, 2025-26 ILI peaks were above the 2022-25 range in Regions 1, 2 and 7
  (Region 2: 13.6% vs a prior max of 9.2%) and below it only in Region 9 (5.81% vs a prior min of 7.29%). Region 6 peaked at
  8.87% wILI (inside its 8.29-10.27% range) and 38.1% positivity (just above its prior max, 37.3%).
- Public health labs: of subtyped influenza A in 2025-26, 84% was A(H3N2) and 16% A(H1N1)pdm09,
  after two seasons where H1N1pdm09 was the larger share (64% in 2023-24, 53% in 2024-25).

**Heading into 2026-27:**
- As of the pull date no 2026-27 weeks exist yet; the season starts with MMWR week 40 (week of
  Oct 4, 2026). The latest week, 2026 week 38, is the tail of 2025-26.
- Week 38 national wILI was 1.74%, and clinical positivity 3.43%. That positivity is the highest
  week-38 value in the seven seasons here (the next highest was 1.25% in 2022), and it has roughly
  doubled in three weeks (1.76% → 2.60% → 3.43%). Region 6 positivity went 1.16% → 1.85% → 3.00%.
  These are the three shaded, preliminary weeks; the week-38 specimen count (33,547) is already
  lower than week 37 (45,011), which suggests reports are still arriving.

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
- Background: CDC [FluView surveillance methods](https://www.cdc.gov/fluview/overview/).

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
- **ILI definition change.** ILINet's case definition changed at MMWR week 40 of 2021, and
  2020-21/2021-22 were also distorted by COVID-19, so the season comparisons use 2022-23 onward only.
- **Regions vs their own baselines.** Regions differ in provider mix and typical ILI levels, so each
  region is compared with its own prior peaks, not with national figures.
- **Public health lab data are descriptive.** PHL specimens are not a random sample (many are
  forwarded for subtyping), so subtype shares describe what was tested, not population prevalence.
- **Release dates** come from Delphi's ingestion of each CDC issue and can trail CDC's own publication
  by a day or more. MMWR 2025 weeks 39-40 have no archived release within four weeks, so they're
  missing from the first-release comparison.
- **CDC database pauses.** An Annals of Internal Medicine audit of the data.cdc.gov catalog
  ([coverage](https://www.ajmc.com/view/unexplained-pauses-hit-nearly-half-of-monthly-updated-cdc-databases-raising-transparency-concerns))
  found 38 of 82 previously monthly-updated databases paused as of Oct 28, 2025, most of them about
  vaccination. The core FluView feeds used here (ILINet, WHO/NREVSS) were not among them, and their
  only interruption in this data is the Sep-Nov 2025 release gap above.
