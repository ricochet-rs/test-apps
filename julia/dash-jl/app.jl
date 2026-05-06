using Dash
using PlotlyJS

#      Status `~/.julia/environments/v1.7/Project.toml`
#  [1b08a953] Dash v1.1.2

function powplot(n)
    x = 0:0.01:1
    y = x .^ n
    p = plot(x, y, mode="lines")
    p.plot
end

app =
    dash(external_stylesheets = ["https://codepen.io/chriddyp/pen/bWLwgP.css"])

app.layout = html_div(style = Dict(:width => "50%")) do
    html_h1("Hello Dash"),
    html_div() do
        html_div("slider", style = (width = "10%", display = "inline-block")),
        html_div(dcc_slider(
            id = "slider",
            min = 0,
            max = 9,
            marks = Dict(i => "$i" for i = 0:9),
            value = 1,
        ),style = (width = "70%", display = "inline-block"))
    end,
    html_br(),
    dcc_graph(id = "power", figure = powplot(1))
end

callback!(app, Output("power", "figure"), Input("slider", "value")) do value
    powplot(value)
end

run_server(app)
