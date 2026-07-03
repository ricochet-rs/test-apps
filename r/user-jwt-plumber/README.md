# user-jwt-plumber

Capture the current user's information in a Plumber API.

Ricochet injects an `X-Ricochet-User` header holding a JSON Web Token (JWT) that decodes into a list of the caller's claims: `sub`, `name`, `email`, `role`, `groups`, and `aud` (the content id).

To capture and decode the JWT you must:

1. Read the public key from the `.well-known/jwks.json` path
1. Grab the header from the request object `req$HTTP_X_RICOCHET_USER`
1. Decode the JWT using `jose::jwt_decode_sig()`
1. Verify the audience (the content ID)

Verification of the JWT falls onto the application developer.
The `aud` claim is set to the content ID it is signed for.

This API exposes two routes. `/headers` echoes the raw header so you can confirm the proxy attached it. `/whoami` verifies the token and returns the caller's claims, responding 401 when the token is missing or invalid and 403 when the audience does not match this content.

Deploy it like any Plumber API and call it while logged in.
