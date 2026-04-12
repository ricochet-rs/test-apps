# King County Housing Prices

An interactive map of King County home sales built with [Shiny for Python](https://shiny.posit.co/py/) and [lonboard](https://developmentseed.org/lonboard/).

View live at https://try.ricochet.rs/app/shiny-lonboard/

The data is from [Kaggle](https://www.kaggle.com/datasets/harlfoxem/housesalesprediction).

## Clone the app

Clone this example using sparse checkout:

```bash
git clone --filter=blob:none --sparse https://github.com/ricochet-rs/test-apps.git
cd test-apps
git sparse-checkout set python/shiny-py-lonboard
cd python/shiny-py-lonboard
```

Install dependencies and run locally:

```bash
uv sync
uv run shiny run app.py
```

## Deploy to Ricochet

1. Install the CLI

```bash
curl -fsSL https://raw.githubusercontent.com/ricochet-rs/cli/main/install.sh | sh
```

2. Add the try server

```bash
ricochet servers add try https://try.ricochet.rs
```

3. Authenticate

```bash
ricochet login -S try
```

4. Deploy

```bash
ricochet deploy
```
