get_root <- function(request, response) {
  response$status <- 302L
  response$set_header("Location", "./survey")
  Break
}
