#' Export a fitted `jpfit` object to Excel, LaTeX, or CSV
#'
#' Writes the four publication-ready tables produced by [jp_fit()] -- the
#' probit selection equation, the mean production function (with and
#' without selectivity correction), and the with/without risk-function
#' comparison -- to a single Excel workbook (one sheet per table), one
#' LaTeX file (booktabs-style `tabular` environments), or a folder of
#' CSV files.
#'
#' Excel export requires the `openxlsx` package. If it is not installed,
#' install with `install.packages("openxlsx")`. LaTeX and CSV exports use
#' base R only.
#'
#' @param fit A `jpfit` object returned by [jp_fit()].
#' @param file Output destination. Format is autodetected from its
#'   extension (`.xlsx`, `.tex`, `.csv`) unless `format` is supplied. For
#'   `format = "csv"`, `file` is a directory and one CSV per table is
#'   written into it.
#' @param format One of "auto" (default), "xlsx", "tex", or "csv".
#' @param digits Number of digits to display in numeric cells (default 3).
#' @param caption_prefix Character. Inserted at the front of every
#'   table caption / sheet name to identify this fit (default uses the
#'   selection variable name).
#' @param overwrite Logical. Overwrite existing files (default `TRUE`).
#'
#' @return Invisibly, the path(s) written.
#' @export
#' @examples
#' \dontrun{
#' farms <- simulate_kiti_data(seed = 42)
#' fit <- jp_fit(
#'   data = farms, selection_var = "vegetables",
#'   selection_covariates = c("rainfall","irrigated","dist_town",
#'                            "dist_coast","experience"),
#'   output_var = "revenue",
#'   input_vars   = c("fertilizers","pesticides","labor","water"),
#'   shifter_vars = c("machinery","rainfall","irrigated",
#'                    "dist_town","dist_coast","experience"),
#'   bootstrap_reps = 100
#' )
#' jp_export(fit, "results_vegetables.xlsx")
#' jp_export(fit, "results_vegetables.tex")
#' jp_export(fit, "results_vegetables_csv/")
#' }
jp_export <- function(fit,
                      file,
                      format = c("auto","xlsx","tex","csv"),
                      digits = 3,
                      caption_prefix = NULL,
                      overwrite = TRUE) {
  stopifnot(inherits(fit, "jpfit"))
  format <- match.arg(format)

  if (is.null(caption_prefix)) {
    caption_prefix <- fit$config$selection_var
  }

  if (format == "auto") {
    ext <- tolower(tools::file_ext(file))
    format <- if (ext == "xlsx") "xlsx"
              else if (ext == "tex") "tex"
              else if (ext == "csv") "csv"
              else if (ext == "" && (dir.exists(file) ||
                                     grepl("[/\\\\]$", file))) "csv"
              else stop("Cannot infer format from '", file,
                        "'. Pass format = 'xlsx', 'tex', or 'csv'.",
                        call. = FALSE)
  }

  tabs <- .jp_export_tables(fit, digits = digits)

  # Ensure parent directory exists for file-output backends.
  if (format %in% c("xlsx", "tex")) {
    parent <- dirname(file)
    if (nzchar(parent) && !dir.exists(parent)) {
      dir.create(parent, recursive = TRUE)
    }
  }

  switch(format,
    xlsx = .export_xlsx(tabs, file, caption_prefix, overwrite),
    tex  = .export_tex( tabs, file, caption_prefix, overwrite),
    csv  = .export_csv( tabs, file, caption_prefix, overwrite)
  )
}

# ---------------------------------------------------------------------------
# Build the tables once; each backend renders them
# ---------------------------------------------------------------------------
.jp_export_tables <- function(fit, digits = 3) {
  cfg <- fit$config

  # Step 1: probit
  s <- summary(fit$selection$model)$coefficients
  probit <- data.frame(
    Variable    = rownames(s),
    Coefficient = round(s[, "Estimate"],   digits),
    Std.Error   = round(s[, "Std. Error"], digits),
    z           = round(s[, "z value"],    digits),
    p.Value     = round(s[, "Pr(>|z|)"],   3),
    Sig         = .sig_stars(s[, "Pr(>|z|)"]),
    row.names   = NULL,
    check.names = FALSE
  )

  # Step 2: mean function (with selectivity)
  mean_with    <- .mean_to_df(fit$mean_with$coefficients, digits)
  mean_without <- .mean_to_df(fit$mean_without$coefficients, digits)

  # Step 3: risk function (with vs without, side-by-side)
  rw <- fit$risk_with$coefficients
  ro <- fit$risk_without$coefficients
  keep <- setdiff(rownames(rw), "(Intercept)")
  risk <- data.frame(
    Input        = keep,
    Coef_with    = round(rw[keep, "Coefficient"], digits),
    SE_with      = round(rw[keep, "Std.Error"],   digits),
    t_with       = round(rw[keep, "t.Statistic"], digits),
    p_with       = round(rw[keep, "p.Value"],     3),
    Coef_without = round(ro[keep, "Coefficient"], digits),
    SE_without   = round(ro[keep, "Std.Error"],   digits),
    t_without    = round(ro[keep, "t.Statistic"], digits),
    p_without    = round(ro[keep, "p.Value"],     3),
    row.names    = NULL,
    check.names  = FALSE
  )

  # Summary metadata
  meta <- data.frame(
    Field = c("Selection variable", "Selection covariates",
              "Output variable", "Inputs", "Shifters",
              "Sample size (total)", "Sample size (selected)",
              "Bootstrap replications",
              paste("Adjusted R-squared (mean fn, with selectivity)"),
              paste("Adjusted R-squared (mean fn, without selectivity)")),
    Value = c(cfg$selection_var,
              paste(cfg$selection_covariates, collapse = ", "),
              cfg$output_var,
              paste(cfg$input_vars,   collapse = ", "),
              paste(cfg$shifter_vars, collapse = ", "),
              format(cfg$n_total),
              format(cfg$n_selected),
              format(cfg$bootstrap_reps),
              sprintf("%.3f", fit$mean_with$adj_r2),
              sprintf("%.3f", fit$mean_without$adj_r2)),
    stringsAsFactors = FALSE
  )

  list(
    summary      = meta,
    probit       = probit,
    mean_with    = mean_with,
    mean_without = mean_without,
    risk         = risk
  )
}

.mean_to_df <- function(coef_tab, digits = 3) {
  data.frame(
    Variable    = rownames(coef_tab),
    Coefficient = round(coef_tab$Coefficient, digits),
    Std.Error   = round(coef_tab$Std.Error,   digits),
    t           = round(coef_tab$t.Statistic, digits),
    p.Value     = round(coef_tab$p.Value,     3),
    Sig         = .sig_stars(coef_tab$p.Value),
    row.names   = NULL,
    check.names = FALSE
  )
}

.sig_stars <- function(p) {
  ifelse(is.na(p), "",
  ifelse(p < 0.01, "***",
  ifelse(p < 0.05, "**",
  ifelse(p < 0.10, "*", ""))))
}

# ---------------------------------------------------------------------------
# Backend: Excel (openxlsx)
# ---------------------------------------------------------------------------
.export_xlsx <- function(tabs, file, caption_prefix, overwrite) {
  if (!requireNamespace("openxlsx", quietly = TRUE)) {
    stop("Excel export requires the 'openxlsx' package. ",
         "Install it with: install.packages(\"openxlsx\")", call. = FALSE)
  }
  if (file.exists(file) && !overwrite) {
    stop("File exists and overwrite = FALSE: ", file, call. = FALSE)
  }

  wb <- openxlsx::createWorkbook()

  header_style <- openxlsx::createStyle(
    textDecoration = "bold", fgFill = "#1F4E78", fontColour = "white",
    halign = "center", border = "bottom", borderStyle = "medium"
  )
  title_style <- openxlsx::createStyle(
    textDecoration = "bold", fontSize = 13
  )
  num_style <- openxlsx::createStyle(numFmt = "0.000")

  sheets <- list(
    list(name = "Summary",            df = tabs$summary,
         title = paste0("JPselection results -- ", caption_prefix)),
    list(name = "Step1_Probit",       df = tabs$probit,
         title = "Step 1. Probit selection equation"),
    list(name = "Step2_Mean_withIMR", df = tabs$mean_with,
         title = "Step 2. Mean production function (with selectivity correction)"),
    list(name = "Step2_Mean_noIMR",   df = tabs$mean_without,
         title = "Step 2. Mean production function (without selectivity correction)"),
    list(name = "Step3_Risk",         df = tabs$risk,
         title = "Step 3. Risk function: with vs. without selectivity correction")
  )

  for (s in sheets) {
    openxlsx::addWorksheet(wb, s$name)
    openxlsx::writeData(wb, s$name, s$title, startRow = 1, startCol = 1)
    openxlsx::addStyle(wb, s$name, title_style, rows = 1, cols = 1)

    openxlsx::writeData(wb, s$name, s$df, startRow = 3, startCol = 1,
                        headerStyle = header_style)

    num_cols <- which(vapply(s$df, is.numeric, logical(1)))
    if (length(num_cols) > 0) {
      openxlsx::addStyle(wb, s$name, num_style,
                         rows = 4:(3 + nrow(s$df)), cols = num_cols,
                         gridExpand = TRUE)
    }
    openxlsx::setColWidths(wb, s$name, cols = seq_len(ncol(s$df)),
                           widths = "auto")
  }

  openxlsx::saveWorkbook(wb, file, overwrite = overwrite)
  message("Wrote Excel workbook: ", file)
  invisible(file)
}

# ---------------------------------------------------------------------------
# Backend: LaTeX (pure base R, booktabs-style)
# ---------------------------------------------------------------------------
.export_tex <- function(tabs, file, caption_prefix, overwrite) {
  if (file.exists(file) && !overwrite) {
    stop("File exists and overwrite = FALSE: ", file, call. = FALSE)
  }

  label_safe <- gsub("[^A-Za-z0-9]", "_", caption_prefix)

  pieces <- c(
    "% Generated by JPselection::jp_export()",
    "% Requires LaTeX packages: booktabs",
    "%   \\usepackage{booktabs}",
    "",
    .tex_table(
      tabs$probit,
      caption = sprintf("Step 1. Probit selection equation (%s).",
                        caption_prefix),
      label   = sprintf("tab:jpselect_probit_%s", label_safe),
      align   = c("l", rep("r", ncol(tabs$probit) - 2), "l")
    ),
    "",
    .tex_table(
      tabs$mean_with,
      caption = sprintf(paste("Step 2. Mean production function with",
                              "selectivity correction (%s)."),
                        caption_prefix),
      label   = sprintf("tab:jpselect_mean_with_%s", label_safe),
      align   = c("l", rep("r", ncol(tabs$mean_with) - 2), "l")
    ),
    "",
    .tex_table(
      tabs$mean_without,
      caption = sprintf(paste("Step 2. Mean production function without",
                              "selectivity correction (%s)."),
                        caption_prefix),
      label   = sprintf("tab:jpselect_mean_without_%s", label_safe),
      align   = c("l", rep("r", ncol(tabs$mean_without) - 2), "l")
    ),
    "",
    .tex_risk_table(
      tabs$risk,
      caption = sprintf(paste("Step 3. Risk function: with vs. without",
                              "selectivity correction (%s)."),
                        caption_prefix),
      label   = sprintf("tab:jpselect_risk_%s", label_safe)
    )
  )

  writeLines(pieces, file)
  message("Wrote LaTeX file: ", file)
  invisible(file)
}

# Generic booktabs tabular. df is a data frame; align is a vector of l/r/c.
.tex_table <- function(df, caption, label, align) {
  stopifnot(length(align) == ncol(df))
  esc <- function(x) {
    x <- as.character(x)
    x <- gsub("\\\\", "\\\\textbackslash{}", x)
    x <- gsub("&",  "\\\\&", x)
    x <- gsub("%",  "\\\\%", x)
    x <- gsub("_",  "\\\\_", x)
    x <- gsub("#",  "\\\\#", x)
    x <- gsub("\\$","\\\\$", x)
    x <- gsub("~",  "\\\\textasciitilde{}", x)
    x <- gsub("\\^","\\\\textasciicircum{}", x)
    x
  }
  header <- paste(esc(names(df)), collapse = " & ")
  body <- apply(df, 1, function(r) paste(esc(r), collapse = " & "))
  c(
    "\\begin{table}[ht]",
    "\\centering",
    sprintf("\\caption{%s}", esc(caption)),
    sprintf("\\label{%s}",   label),
    sprintf("\\begin{tabular}{%s}", paste(align, collapse = "")),
    "\\toprule",
    paste0(header, " \\\\"),
    "\\midrule",
    paste0(body,   " \\\\"),
    "\\bottomrule",
    "\\end{tabular}",
    "\\end{table}"
  )
}

# Specialised: two-block side-by-side for the risk-function comparison.
.tex_risk_table <- function(df, caption, label) {
  esc <- function(x) gsub("_", "\\\\_", as.character(x))
  body <- vapply(seq_len(nrow(df)), function(i) {
    paste0(
      esc(df$Input[i]),                          " & ",
      df$Coef_with[i],                           " & ",
      df$SE_with[i],                             " & ",
      df$t_with[i],                              " & & ",
      df$Coef_without[i],                        " & ",
      df$SE_without[i],                          " & ",
      df$t_without[i],                           " \\\\"
    )
  }, character(1))

  c(
    "\\begin{table}[ht]",
    "\\centering",
    sprintf("\\caption{%s}", esc(caption)),
    sprintf("\\label{%s}",   label),
    "\\begin{tabular}{lrrrcrrr}",
    "\\toprule",
    " & \\multicolumn{3}{c}{With selectivity correction} & & \\multicolumn{3}{c}{Without selectivity correction} \\\\",
    "\\cmidrule(lr){2-4} \\cmidrule(lr){6-8}",
    "Input & Coef. & SE & $t$ & & Coef. & SE & $t$ \\\\",
    "\\midrule",
    body,
    "\\bottomrule",
    "\\end{tabular}",
    "\\end{table}"
  )
}

# ---------------------------------------------------------------------------
# Backend: CSV (one file per table in a folder)
# ---------------------------------------------------------------------------
.export_csv <- function(tabs, dir, caption_prefix, overwrite) {
  if (!dir.exists(dir)) dir.create(dir, recursive = TRUE)

  pfx <- gsub("[^A-Za-z0-9]", "_", caption_prefix)
  paths <- c(
    file.path(dir, paste0("00_summary_",       pfx, ".csv")),
    file.path(dir, paste0("01_step1_probit_",  pfx, ".csv")),
    file.path(dir, paste0("02_step2_mean_with_",    pfx, ".csv")),
    file.path(dir, paste0("02_step2_mean_without_", pfx, ".csv")),
    file.path(dir, paste0("03_step3_risk_",    pfx, ".csv"))
  )
  if (any(file.exists(paths)) && !overwrite) {
    stop("Some files exist and overwrite = FALSE", call. = FALSE)
  }

  write.csv(tabs$summary,      paths[1], row.names = FALSE)
  write.csv(tabs$probit,       paths[2], row.names = FALSE)
  write.csv(tabs$mean_with,    paths[3], row.names = FALSE)
  write.csv(tabs$mean_without, paths[4], row.names = FALSE)
  write.csv(tabs$risk,         paths[5], row.names = FALSE)

  message("Wrote CSV files to: ", dir)
  invisible(paths)
}
