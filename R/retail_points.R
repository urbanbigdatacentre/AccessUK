#' Geolytix Retail Points Dataset
#'
#' This dataset contains information about various retailers in the UK, including their geographic locations, store details, and other attributes.
#' This is a subset based on the Geolytix Retail Points dataset v29_202308. It contains retail points larger than 280m2.
#'
#' @format A tibble with 7,420 rows and 5 variables:
#' \describe{
#'   \item{id_geolytix}{10 digit Geolytix Unique Identifier}
#'   \item{retailer}{Name of the retailer}
#'   \item{long_wgs}{Longitude projection of the store in WGS84}
#'   \item{lat_wgs}{Latitude projection of the store in WGS84}
#'   \item{town}{Geolytix town the store is located within}
#' }
#'
#'
#' @source \href{https://www.geolytix.co.uk}{Geolytix}
#' @references
#' Contains public sector information licensed under the Open Government License v4.0.
#' Contains Ordnance Survey data © Crown copyright and database right 2021.
#' Contains Royal Mail data © Royal Mail copyright and database right 2021.
#' Contains National Statistics data © Crown copyright and database right 2021.
#'
#'
#' This dataset is made available under the Open Government License for public sector information.
#' For more information and the latest downloads, visit \href{https://www.geolytix.co.uk}{Geolytix}.
#'
#' You are free to:
#' \itemize{
#'   \item Copy, publish, distribute, and transmit the Information;
#'   \item Adapt the Information;
#'   \item Exploit the Information commercially, for example, by combining it with other Information or by including it in your own product or application.
#' }
#'
#' You must, where you do any of the above:
#' \itemize{
#'   \item Acknowledge the source of the Information by including any attribution statement specified by the Information Provider(s) and, where possible, provide a link to this license.
#'   \item Ensure that you do not use the Information in a way that suggests any official status or that the Information Provider endorses you or your use of the Information.
#'   \item Ensure that you do not mislead others or misrepresent the Information or its source.
#'   \item Ensure that your use of the Information does not breach the Data Protection Act 1998 or the Privacy and Electronic Communications (EC Directive) Regulations 2003.
#' }
#'
#' @export
#' @examples
#' \dontrun{
#' data(retail_points)
#' head(retail_points)
#' }
"retail_points"
