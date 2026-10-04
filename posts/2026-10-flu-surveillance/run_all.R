# Run the whole pipeline from this post's folder:  Rscript run_all.R
for (f in c("01_fetch.R", "02_clean.R", "03_plots.R")) {
  message("== ", f)
  source(f, local = new.env())
}
