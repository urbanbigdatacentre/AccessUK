
#' Download and extract Accessibility Indicators Dataset for GB
#'
#' Downloads the accessibility indicators dataset for Great Britain from Zenodo.
#' If Zenodo download fails or is too slow, falls back to an alternative URL.
#'
#' @param force_update Logical; re-download even if data exists.
#' @param data_dir Directory where data should be stored.
#' @param quiet Logical; suppress messages when TRUE.
#' @param timeout Numeric; total timeout per attempt in seconds (default 3600).
#' @param low_speed_limit Numeric; abort if speed < this (Mb/sec) for low_speed_time (default 512 bytes/sec).
#' @param low_speed_time Numeric; duration in seconds to trigger low-speed abort (default 120).
#' @param max_attempts Integer; number of attempts per source (default 2).
#'
#' @return Path to the extracted data directory invisibly.
#' @export
download_accessibility_data <- function(
    force_update = FALSE,
    data_dir = system.file(package = "AccessUK"),
    quiet = FALSE,
    timeout = 3600,
    low_speed_limit = 5,   # 5 MB/s
    low_speed_time = 120,    # 2 minutes
    max_attempts = 2
) {
  # Validate inputs
  checkmate::assert_logical(force_update)
  checkmate::assert_logical(quiet)
  checkmate::assert_number(timeout, lower = 30)
  checkmate::assert_number(low_speed_limit, lower = 1)
  checkmate::assert_number(low_speed_time, lower = 10)
  checkmate::assert_int(max_attempts, lower = 1)

  # Set timeout globally
  old_options <- options()
  on.exit(options(old_options), add = TRUE)
  options(timeout = max(timeout, getOption("timeout")))

  # Prepare directories
  data_dir <- file.path(data_dir, "data")
  if (!dir.exists(data_dir)) dir.create(data_dir, recursive = TRUE)

  accessibility_dir <- file.path(data_dir, "accessibility_indicators_gb")
  if (dir.exists(accessibility_dir) && !force_update) {
    if (!quiet) message("Using cached accessibility data.")
    return(invisible(data_dir))
  }

  # URLs
  zenodo_url <- "https://zenodo.org/record/8037156/files/accessibility_indicators_gb.zip?download=1"
  fallback_url <- "https://ubdcdcstageadmin.blob.core.windows.net/dc-os/26/open-release-ptai-2021_28062022.zip?se=2025-12-02T12%3A04%3A16Z&sp=r&sv=2025-01-05&sr=b&sig=ME4EMW4xgpz5vi5UOIMcRFlrX3/bQSYDPbFoy3EXul0%3D"
  zip_file <- file.path(data_dir, "accessibility_indicators_gb.zip")

  # Transform MB to Kb
  low_speed_limit <- low_speed_limit * 1024 * 1024

  # Helper: download with retry and low-speed detection
  download_attempt <- function(url, destfile, label) {
    for (i in seq_len(max_attempts)) {
      if (!quiet) message(sprintf("Downloading from %s (attempt %d)...", label, i))
      h <- curl::new_handle()
      curl::handle_setopt(
        h,
        timeout = timeout,
        low_speed_time = low_speed_time,
        low_speed_limit = low_speed_limit
      )
      ok <- TRUE
      try({
        curl::curl_download(url, destfile = destfile, mode = "wb", handle = h)
      }, silent = TRUE) -> err
      if (file.exists(destfile) && file.info(destfile)$size > 0) return(TRUE)
      Sys.sleep(2 ^ i) # simple backoff
    }
    FALSE
  }

  # Try Zenodo first
  if (!quiet) message("Downloading accessibility data from Zenodo...")
  success <- download_attempt(zenodo_url, zip_file, "Zenodo")

  # Fallback if Zenodo fails
  if (!success) {
    if (!quiet) message("Zenodo download failed or too slow. Trying alternative source...")
    success <- download_attempt(fallback_url, zip_file, "UBDC Azure Blob")
    if (!success) stop("Failed to download data from both sources.")
  }

  # Unzip and clean up
  unzip(zip_file, exdir = data_dir)
  file.remove(zip_file)

  # Adjust headers in TTM
  ttm_path <- list.files(data_dir, pattern = "ttm_pt", recursive = TRUE, full.names = TRUE)
  new_header <- c("from_id", "to_id", "travel_time_p25", "travel_time_p50", "travel_time_p75")
  change_csv_header(ttm_path, new_header)

  invisible(data_dir)
}


