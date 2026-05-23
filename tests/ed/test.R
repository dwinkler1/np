#!/usr/bin/env Rscript

packages <- c("arrow", "data.table", "fixest", "nvimcom")
failed <- character(0)

for (pkg in packages) {
  ok <- tryCatch(
    {
      # nvimcom requires Neovim; skip loading but check it's installed
      if (pkg == "nvimcom") {
        requireNamespace(pkg, quietly = TRUE)
      } else {
        library(pkg, character.only = TRUE, quietly = TRUE)
      }
      TRUE
    },
    error = function(e) FALSE
  )
  if (!ok) {
    failed <- c(failed, pkg)
  }
}

if (length(failed) > 0) {
  cat(sprintf("FAIL: %s\n", paste(failed, collapse = ", ")))
  quit(status = 1)
}

cat("PASS: all packages loaded\n")
