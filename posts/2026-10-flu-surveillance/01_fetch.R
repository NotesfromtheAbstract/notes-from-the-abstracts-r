# 01_fetch.R -- Download the raw surveillance data for this post and cache it in data/raw/.
#
# Sources
#   * Delphi Epidata API (Carnegie Mellon), a versioned mirror of CDC FluView:
#       - fluview          ILINet outpatient ILI (weighted %ILI, providers, patients)
#       - fluview_clinical WHO/NREVSS clinical labs (specimens tested, % positive, A vs B)
#     Delphi keeps every weekly "issue" (release), which lets us measure revisions.
#   * CDC FluView Interactive (gis.cdc.gov) WHO/NREVSS download, for the public health
#     lab file (influenza A subtypes and B lineages), which Delphi does not carry.
#
# Run from this post's folder:  Rscript 01_fetch.R
# Each run overwrites the cache, so re-running pulls the latest (revised) numbers.

library(httr)
library(jsonlite)

dir.create("data/raw/delphi", recursive = TRUE, showWarnings = FALSE)
dir.create("data/raw/cdc", recursive = TRUE, showWarnings = FALSE)

ua <- user_agent("notes-from-the-abstracts-r (github.com/NotesfromtheAbstract/notes-from-the-abstracts-r)")
delphi   <- "https://api.delphi.cmu.edu/epidata"
regions  <- c("nat", paste0("hhs", 1:10))
# 2019-20 season starts at MMWR week 2019-40; ask through the end of 2027 so new
# weeks are picked up automatically. The API returns only weeks that exist.
all_weeks <- "201940-202752"

# Delphi helper: GET, check, cache raw JSON, return the rows.
delphi_get <- function(endpoint, file, ...) {
  q <- list(...)
  # Anonymous clients get 60 requests/hour; this script makes 12 Delphi calls.
  # If you have a (free) Delphi API key, set DELPHI_API_KEY to lift the limit.
  if (nzchar(Sys.getenv("DELPHI_API_KEY"))) q$api_key <- Sys.getenv("DELPHI_API_KEY")
  Sys.sleep(1)
  resp <- GET(sprintf("%s/%s/", delphi, endpoint), query = q, ua, timeout(120))
  if (status_code(resp) == 429)
    stop("Delphi rate limit hit (60 requests/hour without a key). Retry after ",
         headers(resp)[["retry-after"]], " seconds, or set DELPHI_API_KEY.")
  stop_for_status(resp)
  txt <- content(resp, as = "text", encoding = "UTF-8")
  parsed <- fromJSON(txt)
  # result 1 = success, -2 = no rows (allowed for lag queries), anything else = error
  if (!parsed$result %in% c(1, -2))
    stop(endpoint, ": API returned result=", parsed$result, " (", parsed$message, ")")
  writeLines(txt, file.path("data/raw/delphi", file))
  n <- if (is.data.frame(parsed$epidata)) nrow(parsed$epidata) else 0
  message(sprintf("  %-40s %5d rows", file, n))
  invisible(n)
}

message("Delphi: latest values, national + 10 HHS regions")
reg <- paste(regions, collapse = ",")
delphi_get("fluview",          "fluview_latest.json",          regions = reg, epiweeks = all_weeks)
delphi_get("fluview_clinical", "fluview_clinical_latest.json", regions = reg, epiweeks = all_weeks)

# Earlier releases, for the revision analysis. `lag` = weeks between the data week
# and the release, so lag 0 is the first-published value. A few weeks have no lag-0
# issue in Delphi's archive, so lags 0-4 are pulled and 02_clean.R uses the earliest.
message("Delphi: first and early releases (lags 0-4), national + HHS Region 6, 2022-23 onward")
for (l in 0:4) {
  delphi_get("fluview",          sprintf("fluview_lag%d.json", l),
             regions = "nat,hhs6", epiweeks = "202240-202752", lag = l)
  delphi_get("fluview_clinical", sprintf("fluview_clinical_lag%d.json", l),
             regions = "nat,hhs6", epiweeks = "202240-202752", lag = l)
}

# CDC FluView Interactive: WHO/NREVSS download (clinical + public health labs) ------
message("CDC FluView: WHO/NREVSS public health + clinical lab files")
cdc_hdr <- add_headers(Origin = "https://gis.cdc.gov",
                       Referer = "https://gis.cdc.gov/grasp/fluview/fluportaldashboard.html")
init <- fromJSON(content(GET("https://gis.cdc.gov/flu2/GetPhase02InitApp?appVersion=Public",
                             ua, cdc_hdr, timeout(60)), as = "text", encoding = "UTF-8"))
season_ids <- sort(init$seasons$seasonid[init$seasons$seasonid >= 59])   # 59 = 2019-20
writeLines(toJSON(init$seasons, pretty = TRUE), "data/raw/cdc/fluview_seasons.json")

cdc_download <- function(region_type_id, subregions, tag) {
  body <- list(
    AppVersion   = "Public",
    DatasourceDT = list(list(ID = 1, Name = "WHO_NREVSS")),
    RegionTypeId = region_type_id,
    SubRegionsDT = subregions,
    SeasonsDT    = lapply(season_ids, function(i) list(ID = i, Name = as.character(i)))
  )
  zip <- tempfile(fileext = ".zip")
  resp <- POST("https://gis.cdc.gov/flu2/PostPhase02DataDownload", ua, cdc_hdr,
               encode = "json", body = body, timeout(120), write_disk(zip, overwrite = TRUE))
  stop_for_status(resp)
  files <- unzip(zip, exdir = tempdir(), overwrite = TRUE)
  for (f in files) {
    dest <- file.path("data/raw/cdc", sprintf("%s_%s", tag, basename(f)))
    file.copy(f, dest, overwrite = TRUE)
    message(sprintf("  %s", dest))
  }
}
cdc_download(3, list(list(ID = 0, Name = "")), "national")                                   # 3 = national
cdc_download(1, lapply(1:10, function(i) list(ID = i, Name = as.character(i))), "hhs")       # 1 = HHS regions

# Record when the data were pulled (used in chart captions).
writeLines(format(Sys.Date(), "%Y-%m-%d"), "data/raw/pulled_on.txt")
message("Pulled on ", Sys.Date())
