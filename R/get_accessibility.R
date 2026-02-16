#' Access the Accessibility Indicators Dataset for GB
#'
#' This function checks for the accessibility indicators dataset in the data directory,
#' downloads it if necessary, and then loads the desired dataset based on the provided service and mode.
#' The function can also subset the data based on provided origin locations.
#'
#' @param from Vector of origin LSOA/DZ codes. If NULL (default), all locations are returned.
#' @param service Character string specifying the desired service (e.g., "employment", "supermarket", "school"). Default is "employment".
#' @param mode Character string specifying the transportation mode. Can be "public_transport" (default) or "car".
#'
#' @return A data frame containing the data from the desired dataset.
#'
#' @importFrom duckdb duckdb
#' @importFrom DBI dbConnect dbGetQuery dbDisconnect
#' @importFrom utils data
#'
#' @export
#' @examples
#' \dontrun{
#'
#'   get_accessibility(from = "S01006616", service = 'employment', mode = "public_transport")
#'
#'   Or use a vector for multiple origins
#'
#'   glasgow_cc = c("S01010272", "S01010265")
#'   get_accessibility(from = glasgow_cc)
#' }
get_accessibility <- function(
    from = NULL,
    service = 'employment',
    mode = "public_transport"
  ){

  # Check if data directory exists and has data, if not, download the data
  data_dir <- download_accessibility_data()

  # Check mode
  if(mode == "public_transport"){
    mode <- "pt"
  } else if (mode == "car"){
    mode <- "car"
  } else {
    stop("Mode requested not available. It should be \"car\" or \"public_transport\"")
  }

  # List of files
  all_files <- list.files(data_dir, recursive = TRUE, full.names = TRUE)
  # Search file
  access_file <- grep(mode, all_files, value = TRUE)
  access_file <- grep(service, access_file, value = TRUE)

  # Check if file exists
  if (!file.exists(access_file)) {
    stop("The desired indicator does not exist, choose from the modes and services available.")
  }

  # Read data using DuckDB
  con <- DBI::dbConnect(duckdb::duckdb())

  # Define if reading all the DF or just a subset
  if(!is.null(from)){
    # Convert the vector to a comma-separated string
    rows_string <- paste(sprintf("'%s'", from), collapse = ",")
    query <- paste0("SELECT * FROM '", access_file, "' WHERE geo_code in (", rows_string, ");")

  } else {
    query <- paste0("SELECT * FROM '", access_file, ";")
  }

  # Run query
  access_indices <- DBI::dbGetQuery(con, query)

  # Identify columns that do not start with 'geo'
  non_geo_cols <- !grepl("^geo", colnames(access_indices))

  # Apply as.numeric to those columns
  access_indices[ , non_geo_cols] <- lapply(access_indices[ , non_geo_cols], as.numeric)

  # Close connection
  DBI::dbDisconnect(con, shutdown=TRUE)

  # Return the data frame
  return(access_indices)
}
