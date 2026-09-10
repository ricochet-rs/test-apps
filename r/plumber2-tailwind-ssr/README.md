# Plumber2 Pages

Serve penguin pages rendered in R and styled with Tailwind CSS.
The home page links to species summaries, and unknown species return an HTML page with HTTP status 404.

Ricochet runs `app.R` as an `r-service`; the script starts Plumber2 using the supplied `HOST` and `PORT`.
The `_server.yml` file is not used by this deployment.

Run `ricochet deploy r/plumber2-tailwind-ssr` from the repository root to deploy the configured item.
