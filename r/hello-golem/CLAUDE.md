Resolve `run_app()` through `pkgload::pkg_env("myapp")` in `app.R` so Shiny's automatic sourcing of `R/` cannot shadow the package function and its namespace imports.
Exclude `dev/` from renv dependency discovery and declare startup dependencies in `DESCRIPTION` so both implicit and explicit snapshots describe the runtime environment.
