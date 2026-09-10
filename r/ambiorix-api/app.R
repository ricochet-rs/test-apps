library(ambiorix)

# let's hardcode a list of members:
members <- data.frame(
  id = as.character(1:3),
  name = c("John Doe", "Bob Williams", "Shannon Jackson"),
  email = c("john@gmail.com", "bob@gmail.com", "shannon@gmail.com"),
  status = c("active", "inactive", "active")
)

app <- ambiorix::Ambiorix$new()

app$get("/", \(req, res) {
  res$json(list(
    name = "Ambi API",
    description = "Create, read, update, and delete members.",
    endpoints = list(
      counter = "./counter",
      members = "./api/members",
      example_member = "./api/members/1"
    )
  ))
})

app$get("/counter", \(req, res) {
  res$send(
    '
    <!doctype html>
    <html lang="en">
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title>Ambiorix Counter</title>
        <style>
          :root { color-scheme: light dark; font-family: system-ui, sans-serif; }
          body { min-height: 100vh; margin: 0; display: grid; place-items: center; background: #f3f0ff; color: #241b35; }
          main { width: min(28rem, calc(100% - 3rem)); padding: 3rem; text-align: center; background: white; border-radius: 1.5rem; box-shadow: 0 1.5rem 4rem #553c7b26; }
          p { color: #655879; }
          output { display: block; margin: 1.5rem; font-size: 4rem; font-weight: 750; }
          button { padding: 0.8rem 1.2rem; border: 0; border-radius: 999px; background: #7048a8; color: white; font: inherit; font-weight: 650; cursor: pointer; }
          button:hover { background: #583488; }
        </style>
      </head>
      <body>
        <main>
          <h1>Hello from Ambiorix</h1>
          <p>This counter verifies that the preview serves an interactive application.</p>
          <output id="count">0</output>
          <button id="increment" type="button">Increment counter</button>
        </main>
        <script>
          const count = document.querySelector("#count");
          document.querySelector("#increment").addEventListener("click", () => {
            count.value = Number(count.value) + 1;
          });
        </script>
      </body>
    </html>
  '
  )
})

# gets all members:
app$get("/api/members", \(req, res) {
  res$json(members)
})

# get a single member:
app$get("/api/members/:id", \(req, res) {
  # get the supplied id:
  member_id <- req$params$id

  # filter member with that id:
  found <- members |> dplyr::filter(id == member_id)

  # if a member with that id was found, return the member:
  if (nrow(found) > 0) {
    return(res$json(found))
  }

  # otherwise, change response status to 400 (Bad Request)
  # and provide a message:
  msg <- list(msg = sprintf("No member with the id of %s", member_id))
  res$set_status(400L)$json(msg)
})

# create a new member:
app$post("/api/members", \(req, res) {
  # parse form-data:
  body <- parse_multipart(req)

  name <- body$name
  email <- body$email
  status <- body$status

  # require all member details:
  if (is.null(name) || is.null(email) || is.null(status)) {
    msg <- list(msg = "Please include a name, email & status")
    return(res$set_status(400L)$json(msg))
  }

  # details of the new member:
  new_member <- data.frame(
    id = uuid::UUIDgenerate(),
    name = name,
    email = email,
    status = status
  )

  # save new member:
  members <<- dplyr::bind_rows(members, new_member)

  # respond with a message and details of the newly created member:
  response <- list(
    msg = "Member created successfully!",
    member = new_member
  )

  res$json(response)
})

#' Coalescing operator to specify a default value
#'
#' @return the first non-\code{NULL} value
#' @name op-null-defaul
"%||%" <- function(x, y) {
  if (is.null(x)) y else x
}

# update member
app$put("/api/members/:id", \(req, res) {
  # get the supplied id:
  member_id <- req$params$id

  # filter member with that id:
  found <- members |> dplyr::filter(id == member_id)

  # if a member with that id is NOT found, change response status
  # and provide a message:
  if (nrow(found) == 0) {
    msg <- list(msg = sprintf("No member with the id of %s", member_id))
    return(res$set_status(400L)$json(msg))
  }

  # otherwise, proceed to update member:
  body <- parse_multipart(req)

  # only update provided fields:
  found$name <- body$name %||% found$name
  found$email <- body$email %||% found$email
  found$status <- body$status %||% found$status

  members[members$id == found$id, ] <- found

  response <- list(
    msg = "Member updated successfully",
    member = found
  )
  res$json(response)
})

# delete member:
app$delete("/api/members/:id", \(req, res) {
  # get the supplied id:
  member_id <- req$params$id

  # filter member with that id:
  found <- members |> dplyr::filter(id == member_id)

  # if a member with that id is NOT found, change response status
  # and provide a message:
  if (nrow(found) == 0) {
    msg <- list(msg = sprintf("No member with the id of %s", member_id))
    return(res$set_status(400L)$json(msg))
  }

  # otherwise, proceed to delete member:
  members <<- members |> dplyr::filter(id != member_id)

  response <- list(
    msg = "Member deleted successfully",
    members = members
  )
  res$json(response)
})

app$start()
