# Ricochet test apps

Applications, scripts, and documents for testing deployments to Ricochet.

## App catalog

Each row gives a short name, a description, and the deployment features the item exercises.
Directory names are stable; configured items use the same display name and summary in `_ricochet.toml`.

| App | Name | Description | Scope |
| --- | --- | --- | --- |
| [r/ambiorix-api](r/ambiorix-api/) | Ambiorix CRUD | Manage an in-memory member list. | REST routes; multipart forms; CRUD |
| [r/ambiorix-hello-world](r/ambiorix-hello-world/) | Ambiorix Counter | Serve a page with a click counter. | HTML serving; browser JavaScript |
| [r/bookdown-test](r/bookdown-test/) | Bookdown | Render a multi-chapter example book. | R Markdown; book assets; daily rendering |
| [r/diff-entrypoints](r/diff-entrypoints/) | Entrypoints | Switch between two histogram apps. | Shiny; a.R versus b.R entrypoints |
| [r/geocode-shiny](r/geocode-shiny/) | Geocoding | Find places from search text. | Shiny; Leaflet; ArcGIS geocoding |
| [r/hello-golem](r/hello-golem/) | Golem | Serve the Golem welcome app. | Shiny package loading; bundled assets |
| [r/list-paths](r/list-paths/) | File Browser | List files in a selected directory. | Shiny; filesystem isolation inspection |
| [r/persistent-sqlite](r/persistent-sqlite/) | SQLite | Save and display messages in SQLite. | Shiny; persistent storage across instances |
| [r/plumb-default](r/plumb-default/) | Plumber Formats | Serve sample API responses and downloads. | JSON; PNG; PDF; text; HTML; binary |
| [r/plumb-file](r/plumb-file/) | Plumber Uploads | Accept uploads and read CSV files. | Multipart requests; file parsing |
| [r/plumber-headers](r/plumber-headers/) | Plumber Headers | Display incoming request headers. | HTTP proxy header forwarding |
| [r/plumber2-tailwind-ssr](r/plumber2-tailwind-ssr/) | Plumber2 Pages | Serve penguin pages styled with Tailwind CSS. | R server; HTML rendering; species routes |
| [r/polls-538](r/polls-538/) | Election Polls | Plot Harris and Trump polling trends. | R batch job; bundled JSON; persistent PNG output |
| [r/quarto-dashboard](r/quarto-dashboard/) | Quarto Dashboard | Summarize labor and delivery statistics. | Static dashboard; Excel data; themes and assets |
| [r/quarto-report](r/quarto-report/) | Quarto R Report | Plot penguin body mass and bill length. | Quarto R execution; HTML report rendering |
| [r/quarto-shiny](r/quarto-shiny/) | Quarto Shiny | Adjust an Old Faithful histogram. | Quarto document; reactive Shiny server |
| [r/rev-geocode-shiny](r/rev-geocode-shiny/) | Reverse Geocoding | Find an address by clicking a map. | Shiny; Leaflet; ArcGIS reverse geocoding |
| [r/rmd-parameterized](r/rmd-parameterized/) | R Markdown Params | Render supplied report parameters. | R Markdown; parameter handling |
| [r/rmd-shiny-prerendered](r/rmd-shiny-prerendered/) | Prerendered Shiny | Adjust a prerendered histogram. | R Markdown; Shiny server chunks; no deployment config |
| [r/shiny-delayed-quit](r/shiny-delayed-quit/) | Shiny Exit | Exit shortly after a session connects. | Process termination; session disconnect; reaping |
| [r/sleepy](r/sleepy/) | R Sleep | Log timestamps for five minutes. | Long-running R job; log streaming |
| [r/srvrless-hello](r/srvrless-hello/) | R Functions | Expose R functions as HTTP endpoints. | Serverless routes; JSON and CSV serialization |
| [r/svi-dashboard](r/svi-dashboard/) | SVI Map | Explore Washington social vulnerability data. | Shiny; geodatabase assets; maps and county summaries |
| [r/user-jwt-plumber](r/user-jwt-plumber/) | Plumber JWT | Verify and return the caller's identity. | Proxy JWT header; signature and audience checks |
| [r/user-jwt-shiny](r/user-jwt-shiny/) | Shiny R JWT | Display the caller's verified identity. | Shiny session headers; JWT audience checks |
| [r/waiting](r/waiting/) | Shiny Logs | Show a histogram and emit recurring logs. | Shiny reactivity; live logs; alternate app directory |
| [python/dash-hello](python/dash-hello/) | Dash Python | Display a Dash greeting. | Python Dash startup; HTML layout |
| [python/fastapi-hello](python/fastapi-hello/) | FastAPI | Serve API docs and a health endpoint. | ASGI; OpenAPI docs; proxy root path |
| [python/flask-hello](python/flask-hello/) | Flask | Serve greeting and health JSON. | WSGI; Flask routing |
| [python/marimo-high-dim-data](python/marimo-high-dim-data/) | Marimo Tables | Explore selectable and styled tables. | Reactive notebook; table widgets; no deployment config |
| [python/python-sleep](python/python-sleep/) | Python Sleep | Log progress through nine timed iterations. | Python batch job; log streaming; completion |
| [python/quarto-py-hello](python/quarto-py-hello/) | Quarto Python | Render a sine plot and a calculation. | Quarto; Jupyter execution; HTML output |
| [python/shiny-py-lonboard](python/shiny-py-lonboard/) | Housing Map | Explore King County house prices. | Shiny; Lonboard widgets; spatial filtering; Parquet |
| [python/shiny-py-penguins](python/shiny-py-penguins/) | Shiny Penguins | Compare penguin bill lengths by species. | Shiny Express; reactive plotnine histograms |
| [python/streamlit-hello](python/streamlit-hello/) | Streamlit | Greet a user by name. | Streamlit startup; text input; reruns |
| [python/user-jwt-shiny](python/user-jwt-shiny/) | Shiny Python JWT | Display the caller's verified identity. | Shiny session headers; PyJWT signature and audience checks |
| [julia/dash-jl](julia/dash-jl/) | Dash Julia | Adjust a power curve with a slider. | Dash callbacks; Plotly; proxy base path |
| [julia/genie-simple](julia/genie-simple/) | Genie Todos | Add, filter, and complete session todos. | GenieFramework; Stipple reactivity; session state |
| [julia/jl-hello-world](julia/jl-hello-world/) | Julia Penguins | Inspect and plot penguin measurements. | Julia batch execution; data and plotting packages |
| [julia/quarto-jl](julia/quarto-jl/) | Quarto Julia | Render function and penguin plots. | Quarto Julia engine; figures; static HTML assets |
| [julia/user-jwt-http-jl](julia/user-jwt-http-jl/) | HTTP Julia JWT | Verify identity and echo WebSocket messages. | HTTP.jl routes; JWT validation; WebSocket upgrades |

## Development

Use `just deploy-all` to deploy every item with an `_ricochet.toml` to your Ricochet server.
Use `just deploy-all server=SERVER` to select a server, or `just deploy-all-dev` to use `ricochet-dev`.
The `r/rmd-shiny-prerendered` and `python/marimo-high-dim-data` examples have no deployment config and are skipped by these recipes.

Use `just clean-ids` to remove saved content IDs from the deployment configs before deploying them as new items.
This command requires R and the `cli` and `tomledit` packages.
