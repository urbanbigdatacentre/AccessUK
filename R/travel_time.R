#' Retrieve Travel Time Matrix Data
#'
#' Retrieves the travel time matrix (TTM) data by public transport based on a given origin.
#'
#' @param from Vector of origin LSOA/DZ codes to get the travel time to all other. If NULL (default), all locations are returned.
#'
#' @return A data frame of the travel time matrix for the given origin.
#'
#' @importFrom duckdb duckdb
#' @importFrom DBI dbConnect dbGetQuery dbDisconnect
#' @importFrom utils data
#'
#' @export
#' @examples
#' \dontrun{
#' travel_time(from = "S01006616")
#' }
travel_time <- function(from = NULL) {
  data_dir <- system.file("data", package = "AccessUK")

  # Check if data directory exists and has data
  if (!dir.exists(data_dir) || length(list.files(data_dir)) == 0) {
    download_accessibility_data()
  }

  # List of files
  all_files <- list.files(data_dir, recursive = TRUE, full.names = TRUE)
  # Search TTM file
  ttm_file <- grep('ttm_pt', all_files, value = TRUE)

  # Read data using DuckDB
  con <- DBI::dbConnect(duckdb::duckdb())

  # Define if reading all the DF or just a subset
  if(!is.null(from)){
    # Convert the vector to a comma-separated string
    rows_string <- paste(sprintf("'%s'", from), collapse = ",")
    query <- paste0("
      SELECT *
      FROM read_csv(
              '", ttm_file, "',
              header=true,
              auto_detect=true,
              allow_quoted_nulls=true,
              nullstr='NA'
              )
      WHERE fromId in (", rows_string, ");
    ")
    ttm <- DBI::dbGetQuery(con, query)
  } else {
    query <- paste0("SELECT * FROM read_csv_auto('", ttm_file, "', header=true);")
    ttm <- DBI::dbGetQuery(con, query)
  }

  # Close connection
  DBI::dbDisconnect(con, shutdown=TRUE)

  return(ttm)
}
