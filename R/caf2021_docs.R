#' Open the CAF 2021 documentation bundled with the package
#'
#' Three documents from INE Chile are shipped inside this package's
#' `inst/extdata/` folder for offline reference:
#' \describe{
#'   \item{dictionary}{Variable dictionary (`.xlsx`) -- the authoritative
#'     codebook for the UPA, ESTABLECIMIENTO, PREDIO, and HOGAR tables.}
#'   \item{methodology}{Methodological document (`.pdf`) describing
#'     sample design, definitions, and operative procedures.}
#'   \item{questionnaire}{Census questionnaire facsimile (`.pdf`).}
#' }
#'
#' These are the only CAF 2021 documents accessible by direct URL from
#' INE; the **microdata files themselves are served through an
#' interactive SharePoint widget and must be downloaded manually** from
#' \url{https://www.ine.gob.cl/estadisticas-por-tema/agricultura-y-medio-ambiente/censo-agropecuario}
#' (section *Bases de datos*).
#'
#' @param which One of "dictionary", "methodology", "questionnaire", or
#'   "all" (default). With "all", returns a named character vector of
#'   the three file paths.
#'
#' @return A file path (or named vector of paths) to the bundled
#'   document(s).
#' @export
#' @examples
#' caf2021_docs("dictionary")
#' \dontrun{
#' # Open the variable dictionary in Excel
#' shell.exec(caf2021_docs("dictionary"))
#' }
caf2021_docs <- function(which = c("all","dictionary","methodology","questionnaire")) {
  which <- match.arg(which)
  paths <- c(
    dictionary    = system.file("extdata", "caf2021_dictionary.xlsx",
                                package = "JPselection"),
    methodology   = system.file("extdata", "caf2021_methodology.pdf",
                                package = "JPselection"),
    questionnaire = system.file("extdata", "caf2021_questionnaire.pdf",
                                package = "JPselection")
  )
  missing <- paths == ""
  if (any(missing)) {
    warning("Some bundled docs are missing: ",
            paste(names(paths)[missing], collapse = ", "))
  }
  if (which == "all") return(paths)
  paths[[which]]
}
