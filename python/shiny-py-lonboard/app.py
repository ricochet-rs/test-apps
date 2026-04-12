from pathlib import Path

import geopandas as gpd
import numpy as np
import pandas as pd
from lonboard import Map, ScatterplotLayer
from lonboard.colormap import apply_continuous_cmap
from lonboard.layer_extension import DataFilterExtension
from matplotlib.colors import LinearSegmentedColormap
from shiny import reactive
from shiny.express import input, render, ui
from shinywidgets import reactive_read, render_widget

DATA_PATH = Path(__file__).parent / "data" / "king-county-housing.parquet"

df = pd.read_parquet(DATA_PATH)
gdf = gpd.GeoDataFrame(
    df,
    geometry=gpd.points_from_xy(df["long"], df["lat"]),
    crs="EPSG:4326",
)

PRICE_MIN = float(gdf["price"].min())
PRICE_MAX = float(gdf["price"].max())
SQFT_MIN = float(gdf["sqft_living"].min())
SQFT_MAX = float(gdf["sqft_living"].max())
BEDS_MAX = int(gdf["bedrooms"].max())
BATHS_MAX = float(gdf["bathrooms"].max())

# Color: clamp normalization at $1.5M so anything above is fully red
COLOR_CAP = 1_500_000.0
prices = gdf["price"].to_numpy(dtype=float)
normalized = np.clip((prices - PRICE_MIN) / (COLOR_CAP - PRICE_MIN), 0.0, 1.0)
cmap = LinearSegmentedColormap.from_list("price", ["#2c7bb6", "#ffffbf", "#d7191c"])
colors = apply_continuous_cmap(normalized, cmap, alpha=0.75)

# filter_value columns: price, bedrooms, bathrooms, sqft_living
filter_values = np.column_stack(
    [
        gdf["price"].to_numpy(dtype=float),
        gdf["bedrooms"].to_numpy(dtype=float),
        gdf["bathrooms"].to_numpy(dtype=float),
        gdf["sqft_living"].to_numpy(dtype=float),
    ]
)

extension = DataFilterExtension(filter_size=4)

layer = ScatterplotLayer.from_geopandas(
    gdf,
    extensions=[extension],
    get_filter_value=filter_values,
    filter_range=[
        [PRICE_MIN, PRICE_MAX],
        [0, BEDS_MAX],
        [0, BATHS_MAX],
        [SQFT_MIN, SQFT_MAX],
    ],
    get_fill_color=colors,
    get_radius=100,
    radius_min_pixels=2,
    radius_max_pixels=10,
    pickable=True,
)

BED_CHOICES = {"Any": 0, "1": 1, "2": 2, "3": 3, "4": 4, "5+": 5}
BATH_CHOICES = {"Any": 0.0, "1": 1.0, "1.5": 1.5, "2": 2.0, "2.5": 2.5, "3+": 3.0}

HIDDEN_COLS = {"id", "lat", "long", "geometry"}
DISPLAY_LABELS = {
    "date": "Date",
    "price": "Price",
    "bedrooms": "Bedrooms",
    "bathrooms": "Bathrooms",
    "sqft_living": "Sqft Living",
    "sqft_lot": "Sqft Lot",
    "floors": "Floors",
    "waterfront": "Waterfront",
    "view": "View",
    "condition": "Condition",
    "grade": "Grade",
    "sqft_above": "Sqft Above",
    "sqft_basement": "Sqft Basement",
    "yr_built": "Yr Built",
    "yr_renovated": "Yr Renovated",
    "zipcode": "Zipcode",
    "sqft_living15": "Sqft Living (15)",
    "sqft_lot15": "Sqft Lot (15)",
}

ui.page_opts(title="King County Housing", fillable=True)

with ui.sidebar(width=300):
    ui.h5("Filters")

    with ui.layout_columns(col_widths=6):
        ui.input_numeric(
            "price_min",
            "Min price ($)",
            value=int(PRICE_MIN),
            min=int(PRICE_MIN),
            max=int(PRICE_MAX),
            step=10_000,
        )
        ui.input_numeric(
            "price_max",
            "Max price ($)",
            value=int(PRICE_MAX),
            min=int(PRICE_MIN),
            max=int(PRICE_MAX),
            step=10_000,
        )

    with ui.layout_columns(col_widths=6):
        ui.input_numeric(
            "sqft_min",
            "Min sqft",
            value=int(SQFT_MIN),
            min=int(SQFT_MIN),
            max=int(SQFT_MAX),
            step=100,
        )
        ui.input_numeric(
            "sqft_max",
            "Max sqft",
            value=int(SQFT_MAX),
            min=int(SQFT_MIN),
            max=int(SQFT_MAX),
            step=100,
        )

    ui.input_select(
        "bedrooms", "Min bedrooms", choices=list(BED_CHOICES.keys()), selected="Any"
    )
    ui.input_select(
        "bathrooms", "Min bathrooms", choices=list(BATH_CHOICES.keys()), selected="Any"
    )


@reactive.effect
def _update_filter():
    price_min = input.price_min() or PRICE_MIN
    price_max = input.price_max() or PRICE_MAX
    sqft_min = input.sqft_min() or SQFT_MIN
    sqft_max = input.sqft_max() or SQFT_MAX
    beds_min = BED_CHOICES[input.bedrooms()]
    baths_min = BATH_CHOICES[input.bathrooms()]

    layer.filter_range = [
        [price_min, price_max],
        [beds_min, BEDS_MAX],
        [baths_min, BATHS_MAX],
        [sqft_min, sqft_max],
    ]


with ui.card(full_screen=True):
    ui.card_header("King County Home Sales")

    with ui.layout_columns(col_widths=[3, 9], fillable=True):
        with ui.card(full_screen=False):
            ui.card_header("Selected Property")

            @render.ui
            def detail():
                idx = reactive_read(layer, "selected_index")
                if idx is None:
                    return ui.p(
                        "Click a point on the map to see details.", class_="text-muted"
                    )

                row = gdf.iloc[idx]
                rows = []
                for col, label in DISPLAY_LABELS.items():
                    if col not in gdf.columns:
                        continue
                    val = row[col]
                    if col == "date":
                        val = pd.Timestamp(val).strftime("%B %d, %Y")
                    elif col == "price":
                        val = f"${val:,.0f}"
                    elif col in (
                        "sqft_living",
                        "sqft_lot",
                        "sqft_above",
                        "sqft_basement",
                        "sqft_living15",
                        "sqft_lot15",
                    ):
                        val = f"{val:,.0f} sqft"
                    rows.append(
                        ui.tags.tr(
                            ui.tags.td(
                                label,
                                style="font-weight: 500; padding: 4px 8px; color: #555;",
                            ),
                            ui.tags.td(str(val), style="padding: 4px 8px;"),
                        )
                    )
                return ui.tags.table(
                    ui.tags.tbody(*rows),
                    style="width: 100%; border-collapse: collapse; font-size: 0.9rem;",
                )

        with ui.card(full_screen=False):

            @render_widget
            def map():
                return Map(
                    layers=[layer],
                    view_state={
                        "longitude": -122.2,
                        "latitude": 47.5,
                        "zoom": 9,
                    },
                    show_side_panel=False,
                )
