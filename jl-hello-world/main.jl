using Tidier #exports TidierPlots.jl and others
using DataFrames
using PalmerPenguins

penguins = dropmissing(DataFrame(PalmerPenguins.load()));
@glimpse penguins

ggplot(penguins, @aes(x=bill_length_mm, y=bill_depth_mm, color = species))+
    geom_point()