#' Estimate the Nearest Opportunity
#'
#' This function estimates the nearest opportunity based on given travel matrix,
#' travel cost, and weights.
#'
#' @param travel_matrix A directory path to the travel matrix, which can be in CSV or Parquet format.
#'                      Default is `NULL`.
#' @param travel_cost The cost of travel, which will be used to determine the shortest time expressions.
#'                    It must be a valid column name from the travel matrix.
#' @param weights A dataframe containing weights, which will be written to the database.
#'                It must contain an 'id' column and one or more weight columns.
#' @param additional_group Optional. A column name for additional grouping in the SQL query.
#'                         Default is `NULL`.
#' #' @param csv_null_string A string indicating how null values are stored in a CSV file. Default "NA".
#'
#' @return A dataframe containing the nearest opportunities based on the given travel matrix,
#'         travel cost, and weights.
#'
#' @importFrom duckdb duckdb
#' @importFrom DBI dbConnect dbWriteTable dbGetQuery dbDisconnect
#' @export
#'
#' @examples
#' \dontrun{
#' result <- estimate_nearest_opportunity(
#'   travel_matrix = "/path/to/travel_matrix",
#'   travel_cost = "cost_column",
#'   weights = data.frame(id = 1:3, weight1 = c(10, 20, 30))
#' )
#' }
#'
estimate_nearest_opportunity <- function(
    travel_matrix = NULL,
    travel_cost = NULL,
    weights = NULL,
    additional_group = NULL,
    csv_null_string = "NA"
) {
  # Establish DuckDB connection
  conn <- DBI::dbConnect(duckdb::duckdb())

  # Check if TTM is a CSV or Parquet file, if not format as directory
  if(grepl("\\.csv$|\\.parquet$", travel_matrix)){
    # Enclose file path with single quotation
    travel_matrix <- paste0("'", travel_matrix, "'")
  } else {
    # Format travel matrix directory
    travel_matrix <- format_tm_directory(travel_matrix)
  }

  # Write weights at destination to the database
  DBI::dbWriteTable(conn, 'weights', weights, overwrite = TRUE)

  # Generate shortest_time expressions for each weight column
  weight_cols <- setdiff(names(weights), "id")
  shortest_time_expressions <- lapply(weight_cols, function(name_weight) {
    paste0(
      "MIN(CASE WHEN b.", name_weight, " > 0 THEN a.",
      travel_cost, " ELSE NULL END) as nearest_", name_weight
    )
  })

  # Flatten the list of shortest_time expressions
  shortest_time_expressions <- unlist(shortest_time_expressions)

  # Create the SQL query
  if(is.null(additional_group)){
    shortest_time_query <- paste0(
      "SELECT a.from_id, ",
      paste(shortest_time_expressions, collapse = ", "), "
      FROM ", travel_matrix, " AS a
      LEFT JOIN weights AS b ON a.to_id = b.id
      GROUP BY a.from_id
      ORDER BY a.from_id;"
    )
  } else {
    additional_group <- paste(paste0("a.", additional_group), collapse = ', ')
    shortest_time_query <- paste0(
      "SELECT a.from_id, ", additional_group, ", ",
      paste(shortest_time_expressions, collapse = ", "), "
      FROM ", travel_matrix, " AS a
      LEFT JOIN weights AS b ON a.to_id = b.id
      GROUP BY a.from_id, ", additional_group, "
      ORDER BY ", additional_group, ", a.from_id;"
    )
  }

  # If TTM is in CSV format, use explicit read_csv function
  if (grepl("\\.csv'$", travel_matrix)) {
    shortest_time_query <- gsub(
      paste0("FROM ", travel_matrix, " AS a"),
      paste0("FROM read_csv(", travel_matrix, ", auto_detect=true, header=true,  nullstr='", csv_null_string, "') AS a"),
      shortest_time_query
    )
  }

  # Run the query
  nearest_opportunity <- DBI::dbGetQuery(conn, shortest_time_query)

  # Close connection
  DBI::dbDisconnect(conn, shutdown=TRUE)

  return(nearest_opportunity)
}
