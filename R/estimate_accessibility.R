#' Estimate accessibility using DuckDB
#'
#' This function computes cumulative accessibility for various time cuts using DuckDB.
#' It accepts a travel matrix, a column indicating travel cost, weights indicating
#' opportunities at destination, and a vector of time cuts.
#'
#' @param travel_matrix A directory containing one or more `.parquet` or `.csv` files in R5R output format.
#' @param travel_cost A string representing the name of the column to use for $c_ij$.
#' @param weights A data frame with a column 'id' and one or more columns representing the weights of opportunities at destinations.
#' @param time_cut A numeric vector representing the threshold in cumulative accessibility measures, $t$.
#' @param additional_group A string indicating if the output should be grouped by an additional column in the travel_matrix, e.g. time of day.
#'
#' @return A data frame containing computed accessibility values for each time cut and weight column.
#' @import DBI
#' @import duckdb
#' @export
#'
#' @examples
#' \dontrun{
#'   weights_df <- data.frame(id = 1:5, opportunities = runif(5))
#'   result <- estimate_accessibility(
#'     travel_matrix = "path/to/matrix",
#'     travel_cost = "travel_time",
#'     weights = weights_df,
#'     time_cut = c(30, 45)
#'   )
#' }
estimate_accessibility <- function(
    travel_matrix = NULL,
    travel_cost = NULL,
    weights = NULL,
    time_cut = NULL,
    additional_group = NULL
) {
  # Establish DuckDB connection
  conn <- DBI::dbConnect(duckdb::duckdb())

  # Format travel matrix directory depeding on type of file, ie. csv or .parquet
  travel_matrix <- format_tm_directory(travel_matrix)

  # Write weights at destination to the database
  DBI::dbWriteTable(conn, 'weights', weights, overwrite = TRUE)

  # Create SUM() expressions by time_cut for each weight column
  weight_cols <- setdiff(names(weights), "id")
  sum_expressions <- lapply(weight_cols, function(name_weight) {
    lapply(time_cut, function(t_cut) {
      paste0(
        "SUM(CASE WHEN ", travel_cost, " <= ", t_cut,
        " THEN ", name_weight,
        " ELSE 0 END) AS access_", name_weight, '_', t_cut
      )
    })
  })

  # Flatten the list of sum expressions
  sum_expressions <- unlist(sum_expressions)

  # Create the SQL query
  if(is.null(additional_group)){
    cum_access_query <- paste0(
      "SELECT a.from_id, ",
      paste(sum_expressions, collapse = ", "), "
      FROM ", travel_matrix, " AS a
      LEFT JOIN weights AS b ON a.to_id = b.id
      GROUP BY a.from_id
      ORDER BY a.from_id;"
    )
    # Including additonal grouping
  } else {
    additional_group <- paste(paste0("a.", additional_group), collapse = ', ')
    cum_access_query <- paste0(
      "SELECT a.from_id, ", additional_group, ", ",
      paste(sum_expressions, collapse = ", "), "
      FROM ", travel_matrix, " AS a
      LEFT JOIN weights AS b ON a.to_id = b.id
      GROUP BY a.from_id, ", additional_group, "
      ORDER BY ", additional_group, ", a.from_id;"
    )
  }

  # Run the query
  accessibility <- DBI::dbGetQuery(conn, cum_access_query)

  # Close connection
  DBI::dbDisconnect(conn, shutdown=TRUE)

  return(accessibility)
}
