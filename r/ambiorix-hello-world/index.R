library(ambiorix)

app <- Ambiorix$new()

app$get("/", \(req, res) {
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

app$start(
  host = Sys.getenv("AMBIORIX_HOST", "127.0.0.1"),
  port = as.integer(Sys.getenv("AMBIORIX_PORT", "3000"))
)
