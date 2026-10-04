# Shared ggplot2 theme for blog charts
theme_blog <- function(base_size = 12) {
  ggplot2::theme_minimal(base_size = base_size) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(face = "bold"),
      plot.caption = ggplot2::element_text(color = "grey40", hjust = 0),
      panel.grid.minor = ggplot2::element_blank(),
      legend.position = "bottom"
    )
}
