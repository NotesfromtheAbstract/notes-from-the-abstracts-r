# Notes from the Abstracts: R code

Companion analysis code for [Notes from the Abstracts](https://notesfromtheabstracts.com), a blog about health information management, medical coding, and epidemiology.

## Layout

- `posts/` has one folder per post, named `YYYY-MM-short-slug/`. Each has its own README, scripts, data (or instructions to fetch it), and figures.
- `R/` holds shared helper functions and the blog's chart theme, reused across posts.

## Running the code

Requires R (4.3 or newer) and the tidyverse. Open a post's folder and run its scripts in numbered order.

## Posts

- [`posts/2026-10-flu-surveillance/`](posts/2026-10-flu-surveillance/): *Flying Blind Into Flu Season*. Is federal flu surveillance (ILINet, WHO/NREVSS) still flowing, how much it gets revised, and how 2025-26 compared.

## Chart style

`R/theme_blog.R` defines `theme_blog()`, the `nfta_colors` palette and `scale_*_nfta()` helpers, using the colours and fonts (Jost, Karla) from notesfromtheabstracts.com's stylesheet.
