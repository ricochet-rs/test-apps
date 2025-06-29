# source("dev/clean-ricochet-yaml.R")

deploy("test-apps/bookdown-test")

deploy("test-apps/rmd-538")

deploy("test-apps/waiting/")

deploy("test-apps/ambiorix-hello-world")

deploy("test-apps/quarto-shiny/")

deploy("test-apps/quarto")

deploy("test-apps/ambiorix-api")

deploy(path = "test-apps/srvrless-hello")

deploy("test-apps/polls-538")

deploy("test-apps/svi-dashboard")
