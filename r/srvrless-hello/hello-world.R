hello_world <- function() {
  "hello, world!"
}

add2 <- function(x, y) {
  x + y
}

routes <- list(
  "add-2" = add2,
  "hello" = hello_world,
  penguins = list(
    fn = \() penguins[1:5, ],
    serialize = "csv"
  ),
  nrow = list(
    fn = function(.df) {
      nrow(.df)
    },
    deserialize = "csv"
  )
)
