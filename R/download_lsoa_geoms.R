#' Download Lower Layer Super Output Areas and Data Zones 2011 geographies
#'
#' This function downloads the 2011 Lower Layer Super Output Areas and Data Zones
#' geographies for all of the UK from InFuse. It also extracts the content, and then removes the ZIP file.
#'
#' @param force_update Logical, whether to re-download the data if it already exists.
#' @param data_dir The directory where the data should be stored. Default is "data" in the package's installation directory.
#' @param quiet Logical, suppresses messages when set to TRUE.
#'
#' @return Path to the extracted data directory invisibly.
#' @examples
#' \dontrun{
#' download_lsoa_geoms()
#' }

download_lsoa_geoms <- function(force_update = FALSE, data_dir = system.file(package = "AccessUK"), quiet = FALSE) {
  # Check input
  checkmate::assert_logical(force_update)
  checkmate::assert_logical(quiet)

  # Update timeout option temporarily
  old_options <- options()
  on.exit(options(old_options), add = TRUE)
  options(timeout = max(3600, getOption("timeout")))

  # Out directory
  data_dir <- file.path(data_dir, 'data/lsoa_geoms/')

  # Define URLs and paths
  url <- "https://borders.ukdataservice.ac.uk/ukborders/easy_download/prebuilt/shape/infuse_lsoa_lyr_2011_clipped.zip"
  zip_file <- file.path(data_dir, "lsoa_geoms.zip")

  # Check if data directory exists and create it if it does not
  if (!dir.exists(data_dir)) {
    dir.create(data_dir, recursive = TRUE)
  }

  # Check if data already exists and handle force_update
  if (dir.exists(data_dir) && !force_update && length(list.files(data_dir, pattern = "\\.shp$")) > 0) {
    message("Using cached LSOA geometries data in ", data_dir)
    return(invisible(data_dir))
  }

  # Download the file
  if (!quiet) message("Downloading LSOA geometries to ", zip_file)
  utils::download.file(url, destfile = zip_file, mode = 'wb', quiet = quiet)

  # Unzip the file
  unzip(zip_file, exdir = data_dir)

  # Remove the ZIP file
  file.remove(zip_file)

  # Message about data usage
  if (!quiet) message("This function uses UK Data Service data. Please read the Terms and Conditions file")

  # Return the data directory path invisibly
  return(invisible(data_dir))
}
