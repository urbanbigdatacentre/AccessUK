#' Download and Extract Accessibility Indicators Dataset for GB
#'
#' This function downloads the accessibility indicators dataset for Great Britain from Zenodo,
#' extracts the content, and then removes the ZIP file.
#'
#' @param force_update Logical, whether to re-download the data if it already exists.
#' @param data_dir The directory where the data should be stored. Default is "data" in the package's installation directory.
#' @param quiet Logical, suppresses messages when set to TRUE.
#'
#' @return Path to the extracted data directory invisibly.
#' @export
#' @examples
#' download_extract_GB_data()

download_accessibility_data <- function(force_update = FALSE, data_dir = system.file(package = "AccessUK"), quiet = FALSE) {
  # Check input
  checkmate::assert_logical(force_update)
  checkmate::assert_logical(quiet)

  # Update timeout option temporarily
  old_options <- options()
  on.exit(options(old_options), add = TRUE)
  options(timeout = max(3600, getOption("timeout")))

  # Out directory
  data_dir <- file.path(data_dir, 'data')

  # Define URLs and paths
  url <- "https://zenodo.org/record/8037156/files/accessibility_indicators_gb.zip?download=1"
  zip_file <- file.path(data_dir, "accessibility_indicators_gb.zip")

  # Check if data directory exists, and if not, create it
  if (!dir.exists(data_dir)) {
    dir.create(data_dir, recursive = TRUE)
  }

  # Check if data already exists and handle force_update
  if (file.exists(zip_file) && !force_update) {
    if (!quiet) message("Using cached accessibility data from ", zip_file)
    return(data_dir)
  }

  # Download the file
  if (!quiet) message("Downloading accessibility data to ", zip_file)
  utils::download.file(url, destfile = zip_file, mode = 'wb')

  # Unzip the file
  unzip(zip_file, exdir = data_dir)

  # Remove the ZIP file
  file.remove(zip_file)

}
