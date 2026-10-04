# Shared ggplot2 theme and brand palette for Notes from the Abstracts charts.
#
# Colours and fonts come from the live site's CSS (light theme, `:root` custom
# properties in https://notesfromtheabstracts.com/assets/styles-a9a7XFMU.css,
# fetched 2026-10-04). The site defines its colours in OKLCH; the hex values below
# are exact OKLCH -> sRGB conversions of those values, not eyeballed. Only --card /
# --popover (#fffaec) fell slightly outside sRGB and were clipped.
#
# Fonts (Google Fonts, loaded by the site's <link> to fonts.googleapis.com):
#   --font-display: "Jost"  (headings h1-h4)  -> chart titles
#   --font-body:    "Karla" (body text)       -> everything else
# Both must be installed locally for the charts to render in the brand fonts
# (e.g. from https://fonts.google.com/specimen/Jost and /specimen/Karla). If they
# are missing, systemfonts falls back to the default sans and a warning is shown.

nfta_colors <- c(
  background       = "#fff5e1",  # --background       oklch(97.3% .028 86)
  foreground       = "#171717",  # --foreground/--ink  oklch(20.5% 0 0)
  card             = "#fffaec",  # --card             oklch(98.7% .02 86) (gamut-clipped)
  primary          = "#ad5851",  # --primary/--chart-1 oklch(56% .112 26); also the "Epidemiology" category colour
  secondary        = "#4f9593",  # --secondary/--chart-2 oklch(62.5% .071 192); "HIM" category colour
  accent           = "#e7b140",  # --accent/--chart-3 oklch(79% .14 82)
  tertiary         = "#88c0e1",  # --tertiary         oklch(78% .075 235)
  muted            = "#f2e7d0",  # --muted            oklch(93% .032 84)
  muted_foreground = "#594d48",  # --muted-foreground oklch(43% .018 45)
  destructive      = "#b63132",  # --destructive      oklch(52% .17 25)
  success          = "#1d7d3e",  # --success          oklch(52% .13 150)
  chart_5          = "#69aa77",  # --chart-5          oklch(68% .1 150)
  link             = "#1f1f1f"   # a:not([class]) { color: #1f1f1f }
)

nfta_fonts <- c(display = "Jost", body = "Karla")

# Discrete palette: the site's own --chart-1..5 order, then tertiary.
nfta_discrete <- unname(nfta_colors[c("primary", "secondary", "accent", "foreground",
                                      "chart_5", "tertiary")])

nfta_pal <- function(n = length(nfta_discrete)) {
  if (n > length(nfta_discrete)) stop("nfta palette has ", length(nfta_discrete), " colours; asked for ", n)
  nfta_discrete[seq_len(n)]
}

# Discrete scales (pass `values = ` to override the mapping, e.g. named vectors).
scale_colour_nfta <- function(..., values = nfta_discrete) ggplot2::scale_colour_manual(..., values = values)
scale_color_nfta  <- scale_colour_nfta
scale_fill_nfta   <- function(..., values = nfta_discrete) ggplot2::scale_fill_manual(..., values = values)

# Continuous scales: brand muted -> secondary (teal) by default; low/high/mid overridable.
scale_fill_nfta_c <- function(..., low = nfta_colors[["muted"]], high = nfta_colors[["secondary"]]) {
  ggplot2::scale_fill_gradient(..., low = low, high = high)
}
scale_colour_nfta_c <- function(..., low = nfta_colors[["muted"]], high = nfta_colors[["secondary"]]) {
  ggplot2::scale_colour_gradient(..., low = low, high = high)
}
scale_color_nfta_c <- scale_colour_nfta_c

theme_blog <- function(base_size = 12) {
  ink <- nfta_colors[["foreground"]]
  ggplot2::theme_minimal(base_size = base_size, base_family = nfta_fonts[["body"]]) +
    ggplot2::theme(
      text             = ggplot2::element_text(colour = ink),
      axis.text        = ggplot2::element_text(colour = nfta_colors[["muted_foreground"]]),
      plot.title       = ggplot2::element_text(family = nfta_fonts[["display"]], face = "bold",
                                               size = ggplot2::rel(1.35), colour = ink),
      plot.subtitle    = ggplot2::element_text(colour = ink, margin = ggplot2::margin(b = 8)),
      plot.caption     = ggplot2::element_text(colour = nfta_colors[["muted_foreground"]], hjust = 0,
                                               size = ggplot2::rel(0.75), lineheight = 1.1),
      strip.text       = ggplot2::element_text(family = nfta_fonts[["display"]], face = "bold",
                                               colour = ink, hjust = 0),
      plot.title.position   = "plot",
      plot.caption.position = "plot",
      plot.background  = ggplot2::element_rect(fill = nfta_colors[["background"]], colour = NA),
      panel.background = ggplot2::element_rect(fill = nfta_colors[["background"]], colour = NA),
      legend.background = ggplot2::element_rect(fill = nfta_colors[["background"]], colour = NA),
      legend.key       = ggplot2::element_rect(fill = nfta_colors[["background"]], colour = NA),
      panel.grid.major = ggplot2::element_line(colour = nfta_colors[["muted"]], linewidth = 0.5),
      panel.grid.minor = ggplot2::element_blank(),
      legend.position  = "bottom",
      plot.margin      = ggplot2::margin(14, 18, 10, 14)
    )
}
