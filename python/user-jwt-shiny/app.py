import os

import jwt
from jwt import PyJWKClient
from shiny import App, Inputs, Outputs, Session, render, ui

# this app is deployed on localhost
# you may set the RICOCHET_URL as well
ricochet_url = os.environ.get("RICOCHET_URL", "http://localhost:6188")
jwks_url = f"{ricochet_url}/.well-known/jwks.json"

# fetch the signing key(s) from the JWKS endpoint
jwks_client = PyJWKClient(jwks_url)

# this app's own content id. the token's aud must match it
content_id = os.environ.get("RICOCHET_CONTENT_ID")

app_ui = ui.page_fluid(
    ui.h2("Ricochet identity w/ Shiny"),
    ui.h4("Raw X-Ricochet-User header"),
    ui.output_code("raw_header", placeholder=True),
    ui.h4("Verified claims"),
    ui.output_code("claims", placeholder=True),
)


def server(input: Inputs, output: Outputs, session: Session):
    # ricochet adds the X-Ricochet-User header
    token = session.http_conn.headers.get("X-Ricochet-User")

    @render.code
    def raw_header():
        return token or "(no header present)"

    @render.code
    def claims():
        if not token:
            return "no X-Ricochet-User header"

        # verifies signature and expiry
        signing_key = jwks_client.get_signing_key_from_jwt(token)
        decoded = jwt.decode(
            token,
            signing_key.key,
            algorithms=[signing_key.algorithm_name or "RS256"],
            # reject a token if the audience claim doesn't match the content ID
            audience=content_id,
        )

        return "\n".join(f"{key}: {value}" for key, value in decoded.items())


app = App(app_ui, server)
