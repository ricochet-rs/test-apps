# Serverless runtime for R 

ricochet provides a serverless function runtime for R.

To use ricochet's serverless function runtime, create an R script that contains function definitions stored in a list object called `routes`.

Every function in the `routes` list object will be available by its name. If no names are provided, the function object name is used instead. 

For example we have a file `hello-world.R`:

<div class="code-with-filename">

**hello-world.R**

``` r
hello_world <- function() {
  "hello, world!"
}

add2 <- function(x, y) {
  x + y
}

# alternatively specify per-route (de)serializers
routes <- list(
  "add-2" = add2,
  "hello" = hello_world
)
```

</div>

ricochet will create either a `GET` or `POST` endpoint for each route
specified. If a function has no arguments, a `GET` endpoint is created.
If one or more arguments are present, a `POST` endpoint is created.


Once deployed to ricochet, the functions can be accessed via http. 

The `/hello` endpoint can be accessed using a basic `GET` request:

``` r
library(httr2)

request("https://ricochet.rs/srvrless/hello") |> 
  req_perform() |> 
  resp_body_json()
#> [1] "hello, world!"
```

Or you can access the `add-2` endpoint using a `POST` request:

``` r
request("https://ricochet.rs/srvrless/add-2") |> 
  req_body_json(list(x = 10, y = 5)) |> 
  req_perform() |> 
  resp_body_json()
#> [1] 15
```