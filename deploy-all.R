# source("clean-ricochet-toml-ids.R")

library(ricochet)
deploy("bookdown-test")
deploy("plumb-default")

deploy("quarto-dashboard")

deploy("waiting")

deploy("sleepy")
deploy("ambiorix-hello-world")

deploy("test-apps/quarto-shiny/")

deploy("test-apps/quarto")

deploy("dash-jl")

deploy("test-apps/ambiorix-api")

deploy(path = "test-apps/srvrless-hello")

deploy("test-apps/polls-538")

deploy("svi-dashboard")

deploy("jl-hello-world")
