# ricochet test items

This repository contains applications, scripts, and documents that can be used to test deployments to ricochet.

## Set up 

1. Install R (for Mac follow https://cran.r-project.org/index.html)
2. Install Positron (follow instructions at https://positron.posit.co/download.html)
3. Clone https://github.com/ricochet-rs/test-apps


## Install R packages

These applications require a number of R packages to run locally. 

Install packages by running: 

```r
install.packages(
  c(
    "tidyverse",
    "readxl",
    "ambiorix",
    "shiny",
    "plumber",
    "DT",
    "gt",
    "RcppSimdJson",
    "remotes",
    "b64",
    "usethis"
  )
)
```

This may take a few minutes.

If asked to compile code **say no**.


## Install the R `{ricochet}` package

To deploy items we will use the `{ricochet}` R package. 

```r
# install ricochet
remotes::install_url("https://docs.ricochet.rs/pkgs/ricochet-r.tar.gz")
```

## Deploying an item

In order to deploy an item you need to first create an API key in ricochet. 

- First create an account by logging in to [dev.ricochet.rs](https://dev.ricochet.rs). 
- Then navigate to your dashboard, then API Keys.
- Then create a new API key.
- Edit your R environ file with `usethis::edit_r_environ()`. Set `RICOCHET_API_KEY=your-api-key`.
- Restart your R session.

