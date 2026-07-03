# user-jwt-shiny

Capture the current user's information. 

Ricochet injects an `X-Ricochet-User` header holding a JSON Web Token (JWT) that decodes into a list of the caller's claims: `sub`, `name`, `email`, `role`, `groups`, and `aud` (the content id).


To capture and decode the JWT you must: 

1. Read the public key from the `.well-known/jwks.json` path
1. Grab the header from the `session` variable `session$request$HTTP_X_RICOCHET_USER`
1. Decode the JWT using `jose::jwt_decode_sig()`
1. Verify the audience (the content ID)

Verification of the JWT falls onto the application developer.
The `aud` claim is set to the content ID it is signed for.

Deploy it like any Shiny app and open it while logged in.
