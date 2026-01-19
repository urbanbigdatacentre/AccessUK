#' Download and extract Accessibility Indicators Dataset for GB
#'
#' Downloads the accessibility indicators dataset for Great Britain from Cloudflare R2.
#' Includes retry logic to handle temporary network issues.
#'
#' @param force_update Logical; if TRUE, re-download even if data exists. Default is FALSE.
#' @param data_dir Character; directory where data should be stored.
#'   Default is the package installation directory.
#' @param max_download_attempts Integer; number of download attempts before failing.
#'   Default is 2.
#' @param max_timeout Numeric; maximum timeout in seconds for the download.
#'   Default is 900 (15 min).
#' @param quiet Logical; if TRUE, suppress progress messages. Default is FALSE.
#'
#' @return Path to the extracted data directory (invisibly).
#' @export
#'
#' @examples
#' \dontrun{
#' # Download data (uses cache if already exists)
#' download_accessibility_data()
#'
#' # Force re-download
#' download_accessibility_data(force_update = TRUE)
#' }
download_accessibility_data <- function(
    force_update = FALSE,
    data_dir = system.file(package = "AccessUK"),
    max_download_attempts = 2L,
    max_timeout = 900,
    quiet = FALSE
) {
  # Check input
  checkmate::assert_logical(force_update, len = 1)
  checkmate::assert_logical(quiet, len = 1)
  checkmate::assert_int(max_download_attempts, lower = 1)
  checkmate::assert_number(max_timeout, lower = 30)

  # Update timeout option temporarily
  old_options <- options()
  on.exit(options(old_options), add = TRUE)
  options(timeout = max(max_timeout, getOption("timeout")))

  # Out directory
  data_dir <- file.path(data_dir, 'data')

  # Check if data directory exists, and if not, create it
  if (!dir.exists(data_dir)) {
    dir.create(data_dir, recursive = TRUE)
  }

  # Check if data already exists and handle force_update
  accessibility_dir <- file.path(data_dir, 'accessibility_indicators_gb')
  if (dir.exists(accessibility_dir) && !force_update) {
    if (!quiet) message("Using cached accessibility data.")
    return(invisible(data_dir))
  }

  # Define URLs and paths
  cloudflare_url <- "https://pub-ae0a5e06f7384f5db5345414997d9f7c.r2.dev/accessibility_indicators_gb.zip"
  zip_file <- file.path(data_dir, "accessibility_indicators_gb.zip")

  # Download the file with retry logic
  if (!quiet) {
    message("Downloading accessibility data.\nThis can take a few minutes the first time it is run.")
  }

  download_success <- FALSE

  for (attempt in seq_len(max_download_attempts)) {
    result <- try(
      utils::download.file(
        url = cloudflare_url,
        destfile = zip_file,
        mode = 'wb'
      ),
      silent = TRUE
    )

    if (!inherits(result, "try-error") && file.exists(zip_file)) {
      download_success <- TRUE
      break
    }

    if (attempt < max_download_attempts) {
      if (!quiet) {
        message(sprintf("Download attempt %d failed. Retrying in 2 seconds...", attempt))
      }
      Sys.sleep(2)
    }
  }

  if (!download_success) {
    stop(
      "Failed to download data after ", max_download_attempts,
      " attempts. Please check your internet connection or try again later.",
      call. = FALSE
    )
  }

  if (!quiet) message("Download successful. Extracting data...")

  # Unzip the file
  unzip(zip_file, exdir = data_dir)

  # Remove the ZIP file
  file.remove(zip_file)

  # Adjust headers in TTM to make it compatible with new R5R output
  ttm_path <- list.files(
    data_dir,
    pattern = 'ttm_pt',
    recursive = TRUE,
    full.names = TRUE
  )

  # New TTM headers
  new_header <- c("from_id", "to_id", "travel_time_p25", "travel_time_p50", "travel_time_p75")

  # Change names
  change_csv_header(ttm_path, new_header)

  # Return data dir
  invisible(data_dir)
}
