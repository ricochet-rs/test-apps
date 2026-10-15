get_about <- function() {
  layout(
    title = "About",
    current = "about",
    tags$section(
      class = "section container narrow prose",
      tags$h1("About"),
      tags$p(
        "My first coffee job was in high school, at the kids' cafe in the Bay",
        "Area Discovery Museum, just under the Golden Gate Bridge.",
        "We poured",
        tags$a(
          href = "https://www.equatorcoffees.com/",
          "Equator Coffees",
          .noWS = "after"
        ),
        ", and it is still my favorite roaster.",
        "I am wearing their hat right now."
      ),
      tags$p(
        "In college, I walked half a mile through the snow to open",
        tags$a(href = "https://montealto.com/", "Cafe Monte Alto"),
        "in Plymouth, New Hampshire, by 5:30 in the morning.",
        "Eddie and Micky, the zestiest couple I know, ran it as a cafe and a",
        "roaster, and I served Jay Moskowitz (may he rest in peace) across",
        "its counter.",
        "That is where I fell for espresso drinks and learned latte art."
      ),
      tags$p(
        "For my 27th birthday, I bought a Rancilio Silvia Pro X.",
        "I make at least one cortado on it every day."
      ),
      tags$p(
        "Jackalope is not a real roaster.",
        "It is a demo application to demonstrate the difference between Shiny",
        "and server-side rendering with plumber2."
      ),
      tags$p(link_button("Taste the lineup", "products"))
    )
  )
}
