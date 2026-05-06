library(plumber)

#* @get /list-headers
function(req) {
  cbind(names(req$HEADERS), req$HEADERS)
}
