using HTTP
using JSON3
using JWTs

# Serve on the port Ricochet assigns, falling back to 8081 for local runs
port = parse(Int, get(ENV, "RICOCHET_PORT", "8081"))

# The proxy that launched this app serves its verification key as a JWKS
ricochet_url = get(ENV, "RICOCHET_URL", "http://localhost:6188")

# this app's own content id. the token's aud must match it
content_id = get(ENV, "RICOCHET_CONTENT_ID", "")

# Keys are fetched lazily and cached, and refreshed early on an unknown kid.
# The audience is checked separately below so a mismatch can answer 403.
verifier = JWTs.Verifier(;
    jwks_uri = "$ricochet_url/.well-known/jwks.json",
    algorithms = ["RS256"],
)

function respond(http::HTTP.Stream, status::Int, content_type::String, body::String)
    HTTP.setstatus(http, status)
    HTTP.setheader(http, "Content-Type" => content_type)
    HTTP.startwrite(http)
    write(http, body)
end

respond_json(http::HTTP.Stream, status::Int, payload) =
    respond(http, status, "application/json", JSON3.write(payload))

# Echo the raw identity header, unverified
function headers_route(http::HTTP.Stream)
    respond_json(http, 200, (
        x_ricochet_user = HTTP.header(http.message, "X-Ricochet-User", nothing),
        user_agent = HTTP.header(http.message, "User-Agent", nothing),
    ))
end

# Verify the signed identity token and return the caller's claims
function whoami_route(http::HTTP.Stream)
    token = HTTP.header(http.message, "X-Ricochet-User", "")
    isempty(token) && return respond_json(http, 401, (error = "no X-Ricochet-User header",))

    # verifies signature and expiry
    claims = try
        JWTs.claims(JWTs.verify(verifier, token))
    catch err
        err isa JWTs.JWTError || rethrow()
        return respond_json(http, 401, (error = "invalid or expired token",))
    end

    # reject a token minted for different content
    aud = get(claims, "aud", nothing)
    audiences = aud isa AbstractString ? [aud] : something(aud, [])
    content_id in audiences ||
        return respond_json(http, 403, (error = "token audience does not match this content",))

    return respond_json(http, 200, claims)
end

# A WebSocket handshake arrives on the same port as plain HTTP, so one listener
# dispatches on whether the request asks to upgrade
HTTP.listen("0.0.0.0", port) do http::HTTP.Stream
    if WebSockets.isupgrade(http.message)
        WebSockets.upgrade(http) do ws
            for msg in ws
                WebSockets.send(ws, msg)
            end
        end
        return
    end

    path = HTTP.URI(http.message.target).path
    if path == "/"
        respond(http, 200, "text/plain", "Hello")
    elseif path == "/json"
        respond_json(http, 200, (message = "Hello", method = http.message.method, port = port))
    elseif path == "/headers"
        headers_route(http)
    elseif path == "/whoami"
        whoami_route(http)
    else
        respond(http, 404, "text/plain", "Not found")
    end
end
