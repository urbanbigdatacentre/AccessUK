#' Aggregate Destinations by LSOA Geometries in the UK
#'
#' This function aggregates destinations represented on statistical geometries.
#' It uses 2011 Census LSOA geometries or equivalent sources from InfuseUK.
#' Currently, the function only handles destinations represented by SF points.
#' Thus, it returns the count of points at each location.
#'
#' @param destinations An SF object containing point geometries representing the destinations.
#'
#' @return A data frame containing the count of points at each LSOA location.
#' @examples
#' \dontrun{
#' # Create the data frame with destinations
#' destinations <- data.frame(
#'   lon = c(-1.57, -1.99, -2.76, -1.11, -1.49, -2.56, -0.421, -1.47, -0.163, -1.99),
#'   lat = c(53.8, 51.4, 51.5, 53.5, 52.9, 51.5, 51.5, 52.5, 51.5, 51.4)
#' )
#'
#' # Convert the data frame to an sf object
#' destinations <- sf::st_as_sf(destinations, coords = c("lon", "lat"), crs = 4326)
#'
#' # Run function
#' aggregate_destinations(destinations)
#' }
#'
#' @importFrom sf st_as_sf st_geometry_type st_crs st_transform st_intersection st_read
#' @keywords internal
aggregate_destinations <- function(destinations = NULL, quiet = FALSE) {

  # Check if destinations is SF
  if (!inherits(destinations, "sf")) {
    stop('The object representing destinations needs to be an SF object.')
  }

  # Check if destinations is POINTS
  geom_type <- sf::st_geometry_type(destinations, by_geometry = FALSE)
  geom_type <- as.vector(geom_type)
  if (any(geom_type != 'POINT') | length(geom_type) > 1) {
    stop('Currently, this function handles point geometries at destinations.')
  }

  # Check destination CRS, or transform to 27700
  destinations_crs <- sf::st_crs(destinations)
  if (destinations_crs$input != "EPSG:27700") {
    message("Transforming destinations CRS to BNG EPSG:27700")
    destinations <- sf::st_transform(destinations, crs = 27700)
  }

  # Download or get directory for LSOA geometries
  lsoa_dir <- download_lsoa_geoms(quiet = FALSE)

  # Read LSOA geometries
  geoms_path <- list.files(lsoa_dir, pattern = 'shp', full.names = TRUE)
  lsoa_geoms <- sf::st_read(geoms_path, quiet = TRUE)

  # Intersect points and geometries
  intersection <- sf::st_intersection(destinations, lsoa_geoms)

  # Count points
  point_count <- table(intersection$geo_code)
  point_count <- data.frame(
    id = names(point_count),
    n = as.vector(point_count)
  )

  # Message about data usage
  if (!quiet) message("This function uses UK Data Service data. Please read the Terms and Conditions file")

  # Return counts
  return(point_count)
}
