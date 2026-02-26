import os

from dash import Dash, html

app = Dash(__name__)

app.layout = html.Div([
    html.H1("Hello from Dash!"),
    html.P("This is a test Dash app deployed on Ricochet."),
])

if __name__ == "__main__":
    host = os.environ.get("HOST", "0.0.0.0")
    port = int(os.environ.get("PORT", "8050"))
    app.run(host=host, port=port)
