#' Download and Extract Accessibility Indicators Dataset for GB
#'
#' This function downloads the accessibility indicators dataset for Great Britain from Zenodo,
#' extracts the content, and then removes the ZIP file.
#'
#' @return NULL Invisibly. The function is called for its side effects.
#' @export
#' @examples
#' download_extract_GB_data()

download_accessibility_data <- function() {
  if (getOption("timeout") == 60L) {
    opts = options(timeout = 3600)
    on.exit(options(opts), add = TRUE)
  }
  # Define URLs and paths
  url <- "https://zenodo.org/record/8037156/files/accessibility_indicators_gb.zip?download=1"
  zip_file <- "accessibility_indicators_gb.zip"
  data_dir <- "data"
  
  # Check if the data directory exists, if not, create it
  if (!dir.exists(data_dir)) {
    dir.create(data_dir)
  }
  
  # Download the file
  download.file(url, destfile = file.path(data_dir, zip_file), timeout = 20*60)
  
  # Unzip the file
  unzip(file.path(data_dir, zip_file), exdir = data_dir)
  
  # Remove the ZIP file
  file.remove(file.path(data_dir, zip_file))
  
  # Return invisibly
  invisible(NULL)
}
