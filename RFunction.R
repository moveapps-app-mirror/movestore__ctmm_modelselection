library(ctmm)
library(purrr)
library(dplyr)

rFunction = function(data) {

  g <- lapply(data, \(x) ctmm.guess(x, interactive = FALSE))
  f1 <- map2(data, g, ~ ctmm.select(.x, .y))
  saveRDS(f1, file = appArtifactPath("models.rds"))


  xx <- map(f1, ~ summary(.x))

  # Overall summary
  all.inds <- summary(f1)
  x1 <- as.data.frame(all.inds)
  x2 <- data.frame(
    name = names(xx),
    DOF_diffusion = sapply(xx, function(x) x$DOF["diffusion"]),
    DOF_speed = sapply(xx, function(x) x$DOF["speed"]),
    model = sapply(xx, function(x) x$name)
  )
  x1$name <- rownames(x1)
  out1 <- merge(x1, x2, by = "name")
  names(out1) <- c("id", "IC", "RMSPE", "DOF", "DOF_diffusion", "DOF_speed", "model")
  write.csv(out1, file = appArtifactPath("model_summary.csv"), row.names = FALSE)

  # Individual summary
  xx <- map(xx, ~ .x$CI)
  lens <- map_int(xx, nrow)
  xx <- do.call(rbind, xx)
  xx |> as_tibble() |>
    mutate(id = rep(names(f1), lens), unit = rownames(xx)) |>
    select(id, unit, low, est, high) |>
    write.csv(appArtifactPath("ctmm_select_summary.csv"), row.names = FALSE)
  return(list(f1, data))
}
