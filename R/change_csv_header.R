#' Change CSV Header In-Place
#'
#' This function changes the header of a CSV file in-place. It reads the existing header and replaces it with a new header provided by the user. The new header must not be longer than the old header to ensure in-place replacement is possible.
#'
#' @param input_file A character string specifying the path to the input CSV file.
#' @param new_header A character vector specifying the new header to replace the old header. Each element of the vector represents a column name.
#'
#' @details
#' The function reads the first line (header) of the specified CSV file and replaces it with the new header. The new header must not exceed the length of the old header. If the new header is shorter, it will be padded with spaces to match the length of the old header.
#' This function performs the header replacement in-place, meaning it directly modifies the original file without creating a copy.
#'
#' @return NULL. The function is called for its side effects.
#' @keywords internal
#' @examples
#' \dontrun{
#' change_csv_header("path/to/yourfile.csv", c("new_col1", "new_col2", "new_col3"))
#' }
change_csv_header <- function(input_file, new_header) {
  # Read the old header and its length
  infile <- file(input_file, open = "r+")
  old_header <- readLines(infile, n = 1)

  # Create the new header line
  new_header_line <- paste(new_header, collapse = ",")

  # Ensure the new header is not longer than the old header
  old_header_length <- nchar(old_header)
  new_header_length <- nchar(new_header_line)

  if (new_header_length > old_header_length) {
    stop("New header is longer than the old header. In-place replacement is not possible.")
  }

  # Pad the new header with spaces if necessary
  padded_new_header <- paste(new_header_line, strrep(" ", old_header_length - new_header_length), sep = "")

  # Write the new header in place
  seek(infile, where = 0, rw = "write")
  writeLines(padded_new_header, infile, sep = "")

  # Close the file
  close(infile)
}
