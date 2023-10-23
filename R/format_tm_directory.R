#' Format Travel Matrix Directory
#'
#' Check for the presence of csv or parquet files in the specified directory and
#' format the directory path accordingly.
#'
#' @param travel_matrix A character string specifying the path to the directory
#'        containing the travel matrix files.
#'
#' @return A character string with the formatted directory path, either pointing
#'         to parquet or csv files.
#'
#' @examples
#' \dontrun{
#'   formatted_path <- format_travel_matrix_directory("path/to/directory")
#'   print(formatted_path)
#' }
#'
#'
format_tm_directory <- function(travel_matrix) {
  list_files <- list.files(travel_matrix, recursive = TRUE, full.names = TRUE)
  if (sum(grepl('\\.parquet$', list_files)) > 0) {
    travel_matrix <- file.path(travel_matrix, "*.parquet")
  } else if (sum(grepl('\\.csv$', list_files)) > 0) {
    travel_matrix <- file.path(travel_matrix, "*.csv")
  } else {
    stop("No parquet or csv files found in the specified directory.")
  }
  travel_matrix <- paste0("'", travel_matrix, "'")
  return(travel_matrix)
}
