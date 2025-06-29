library(plumber)

#* @post /upload
upload <- function(req, res) {
  mp <- mime::parse_multipart(req)
  mp
}

#* @post /read_csv
function(req, res) {
  mp <- mime::parse_multipart(req)
  readr::read_csv(mp$file$datapath)
}
