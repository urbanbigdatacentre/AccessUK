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
#' accessibility(service = 'employment', mode = "public_transport")
#' }
accessibility <- function(from = NULL, service = 'employment', mode = "public_transport") {
  data_dir <- system.file("data", package = "AccessUK")

  # Check if data directory exists and has data
  if (!dir.exists(data_dir) || length(list.files(data_dir)) == 0) {
    download_accessibility_data()
  }

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
    access_indices <- DBI::dbGetQuery(con, query)
  } else {
    query <- paste0("SELECT * FROM '", access_file, ";")
    access_indices <- DBI::dbGetQuery(con, query)
  }

  # Close connection
  DBI::dbDisconnect(con, shutdown=TRUE)

  # Return the data frame
  return(access_indices)
}
