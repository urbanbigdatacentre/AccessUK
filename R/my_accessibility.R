#' Compute Accessibility Estimates
#'
#' This function computes custom accessibility estimates using precomputed travel time matrices from the PTAI dataset and user-inputted destination data.
#' It can handle destinations represented by SF points or pre-aggregated weights by LSOA.
#'
#' @param destinations An SF object containing "POINT" geometries only or a data frame with weights aggregated by LSOA.
#'                     If the object is not SF, it is assumed to be weights aggregated by LSOA. This parameter is required.
#' @param time_cut A numeric vector specifying the time thresholds for the accessibility computation.
#'                 This parameter is required and cannot be empty.
#' @param additional_group Optional. A character string specifying an additional grouping variable.
#'
#' @details
#' If `destinations` is an SF object, the function aggregates destinations by LSOA.
#' In the background, it uses 2011 geometries sourced from InFuse UK Data Service layers.
#' Please read the user Terms and Conditions.
#'
#' @return A data frame containing the computed accessibility estimates.
#'
#' @export
#' @examples
#' \dontrun{
#' # Example usage with SF points
#' destinations <- sf::st_as_sf(data.frame(
#'   lon = c(-1.57, -1.99, -2.76, -1.11, -1.49, -2.56, -0.421, -1.47, -0.163, -1.99),
#'   lat = c(53.8, 51.4, 51.5, 53.5, 52.9, 51.5, 51.5, 52.5, 51.5, 51.4)
#' ), coords = c("lon", "lat"), crs = 4326)
#'
#' # Run function
#' my_accessibility(
#'   destinations = destinations,
#'   time_cut = c(30, 45, 60)
#' )
#'
#' # Example usage with aggregated data
#' weights_aggregated <- data.frame(
#'   id = c("E01000825", "E01000824", "E01000812"),
#'   n = c(10, 20, 30)
#' )
#'
#' my_accessibility(
#'   destinations = weights_aggregated,
#'   time_cut = c(30, 45, 60)
#' )
#' }
#'
#' @importFrom sf st_as_sf st_geometry_type st_crs st_transform st_intersection st_read
#' @importFrom checkmate assert_logical
#
my_accessibility <- function(
    destinations,
    time_cut,
    additional_group = NULL
) {
  # Ensure required arguments are provided
  stopifnot(!is.null(destinations), !is.null(time_cut))

  # If the destinations object is not SF, it is assumed to be a weights type aggregated by LSOA
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

  # Run accessibility function
  my_access <- AccessUK::estimate_accessibility(
    travel_matrix = ttm_path,
    travel_cost = 'travel_time_p50',
    weights = destinations_aggregated,
    time_cut = time_cut,
    additional_group = additional_group
  )

  # Return custom accessibility estimates
  return(my_access)
}
