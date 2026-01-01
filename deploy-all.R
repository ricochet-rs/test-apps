# source("clean-ricochet-toml-ids.R")

library(ricochet)

Sys.setenv(
  "RICOCHET_API_KEY" = "rico_em3i5yjpRhD_8CEFMjnRCKkRFpFkJSzt4SxgzjpHehKPm"
)
Sys.setenv("RICOCHET_HOST" = "http://localhost:6188")

ricochet::deploy("sleepy")

deploy("bookdown-test")
deploy("plumb-default")

deploy("quarto-dashboard")

ricochet::deploy("waiting")


deploy("ambiorix-hello-world")

deploy("quarto-shiny")

deploy("dash-jl")

deploy("ambiorix-api")

deploy(path = "srvrless-hello")

ricochet::deploy("polls-538")

deploy("svi-dashboard")

deploy("jl-hello-world")

# python
library(ricochet)

Sys.setenv(
  "RICOCHET_API_KEY" = "rico_Lq6QJFKbwq5_EvG6io1354LsyGTC5cH3MuJ8TpTob248T"
)
Sys.setenv("RICOCHET_HOST" = "http://localhost:3334")
deploy("python/sleep")
