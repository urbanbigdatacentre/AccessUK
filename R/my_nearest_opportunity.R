#' Compute Custom Nearest Opportunity Measures
#'
#' This function computes custom nearest opportunity estimates using precomputed travel time matrices from the PTAI dataset and user-imputed destination data.
#' It can handle destinations represented by SF points or pre-aggregated weights by LSOA.
#'
#' @param destinations An SF object containing "POINT" geometries only or a data frame with weights aggregated by LSOA.
#'                     If the object is not SF, it is assumed to be weights aggregated by LSOA. This parameter is required.
#' @param additional_group Optional. A column name for additional grouping in the SQL query. Default is `NULL`.
#'
#' @return A data frame containing the nearest opportunities based on the PTAI travel matrix, travel cost, and weights.
#' @details
#' If `destinations` is an SF object, the function aggregates destinations by LSOA.
#' In the background, it uses 2011 geometries sourced from InFuse UK Data Service layers. Please read the user Terms and Conditions.
#'
#' @examples
#' \dontrun{
#' # Example usage with SF points
#' destinations <- sf::st_as_sf(data.frame(
#'   lon = c(-1.57, -1.99, -2.76, -1.11, -1.49),
#'   lat = c(53.8, 51.4, 51.5, 53.5, 52.9)
#' ), coords = c("lon", "lat"), crs = 4326)
#'
#' # Run function
#' nearest_opportunities <- my_nearest_opportunity(
#'   destinations = destinations
#' )
#'
#' # Example usage with aggregated data
#' weights_aggregated <- data.frame(
#'   id = c("E01000825", "E01000824", "E01000812"),
#'   weight = c(10, 20, 30)
#' )
#'
#' nearest_opportunities <- my_nearest_opportunity(
#'   destinations = weights_aggregated
#' )
#' }
#'
#' @importFrom sf st_as_sf st_geometry_type st_crs st_transform st_intersection st_read
#' @importFrom checkmate assert_logical
#' @export
my_nearest_opportunity <- function(
    destinations,
    additional_group = NULL
) {
  # Ensure required arguments are provided
  stopifnot(!is.null(destinations))

  # Determine destination type
  if (!any(grepl("sf", class(destinations)))) {
    destination_type <- 'aggregated'
  } else {
    destination_type <- 'point'
  }

  # Check if accessibility directory exists and has data, if not, download the data
  data_dir <- download_accessibility_data()
  # Set PTAI TTM file path
  ttm_path <- list.files(data_dir, pattern = 'ttm_pt', recursive = TRUE, full.names = TRUE)

  if (destination_type == 'point') {
    # Aggregate destinations by LSOA
    destinations_aggregated <- aggregate_destinations(destinations)
  } else if (destination_type == 'aggregated') {
    destinations_aggregated <- destinations
  }

  # Run nearest opportunity function
  my_nearest <- AccessUK::estimate_nearest_opportunity(
    travel_matrix = ttm_path,
    travel_cost = 'travel_time_p50',
    weights = destinations_aggregated,
    additional_group = additional_group
  )

  # Return custom nearest opportunity estimates
  return(my_nearest)
}
