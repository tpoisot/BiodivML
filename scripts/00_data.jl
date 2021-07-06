
import CSV


using DataFrames
using DataFramesMeta


import Cairo, Fontconfig
using Gadfly
import Latexify


include("../lib/theme.jl")


penguin_path = joinpath("data", "penguins")
ispath(penguin_path) || mkpath(penguin_path)


uri_root = "https://portal.edirepository.org/nis/dataviewer?packageid="


identifiers = Dict{String,String}(
    "adelie" => "knb-lter-pal.219.3&entityid=002f3893385f710df69eeebe893144ff",
    "gentoo" => "knb-lter-pal.220.3&entityid=e03b43c924f226486f2f0ab6709d2381",
    "chinstrap" => "knb-lter-pal.221.2&entityid=fe853aa8f7a59aa84cdd3197619ef462"
    )


for entry in identifiers
    penguin, identifier = entry
    datafile = joinpath("data", "penguins", "$(penguin).csv")
    if isfile(datafile)
        nothing
    else
        download(uri_root * identifier, datafile)
    end
end


readdir(joinpath("data", "penguins"))


adelie_csv_file = joinpath("data", "penguins", "adelie.csv")


adelie_csv = CSV.File(adelie_csv_file)


adelie = DataFrame(adelie_csv)


adelie = DataFrame(CSV.File(joinpath("data", "penguins", "adelie.csv")))


adelie = joinpath("data", "penguins", "adelie.csv") |> CSV.File |> DataFrame


adelie = joinpath("data", "penguins", "adelie.csv") |>
    CSV.File |>
    DataFrame


Latexify.latexify(adelie[1:3,1:7], latex=false, env=:mdtable)


colnames = [
    "Species", "Region", "Island", "Culmen Length (mm)", "Culmen Depth (mm)",
    "Flipper Length (mm)", "Body Mass (g)", "Sex"
]
select!(adelie, Symbol.(colnames))
Latexify.latexify(adelie[1:5,1:5], latex=false, env=:mdtable)


renames = [
    "Species" => "species", "Region" => "region", "Island" => "island", 
    "Culmen Length (mm)" => "culmen_length", "Culmen Depth (mm)" => "culmen_depth",
    "Flipper Length (mm)" => "flipper_length", "Body Mass (g)" => "bodymass",
    "Sex" => "sex"
]
rename!(adelie, renames...)
adelie.species .= "Adelie"
Latexify.latexify(first(adelie, 4), latex=false, env=:mdtable)


function clean_penguin_df(species::AbstractString)
    df = DataFrame(CSV.File(joinpath("data", "penguins", lowercase(species)*".csv")))
    select!(df, Symbol.(colnames))
    rename!(df, renames...)
    df.species .= species
    return df
end


penguins = vcat(clean_penguin_df.(["Adelie", "Chinstrap", "Gentoo"])...)
Latexify.latexify(first(penguins, 3), latex=false, env=:mdtable)


CSV.write(joinpath("data", "penguins.csv"), penguins)


plot(
    dropmissing(penguins),
    x=:flipper_length,
    y=:culmen_length,
    color=:species,
    Geom.ellipse, Geom.point,
    Guide.xlabel("Flipper length (mm)"),
    Guide.ylabel("Culmen length (mm)")
) |>
PNG("figures/data_ellipses.png", dpi=600)


plot(
    dropmissing(
        select(
        penguins,
        [:species, :bodymass]
        )
    ),
    x=:species,
    y=:bodymass,
    color=:species,
    Geom.beeswarm,
    Guide.xlabel("Species"),
    Guide.ylabel("Body mass (g)")
) |>
PNG("figures/data_distributions.png", dpi=600)


using Statistics
avg_bodymass = @linq penguins |> 
    select(:species, :island, :bodymass) |>
    where(.!ismissing.(:bodymass)) |>
    by([:species, :island], mean = mean(:bodymass), std = std(:bodymass)) |>
    orderby(:mean)

Latexify.latexify(avg_bodymass, latex=false, env=:mdtable, fmt="%.2d")


stack(penguins, [:culmen_length, :culmen_depth, :flipper_length, :bodymass]) |>
    df -> Latexify.latexify(df[1:7,:], latex=false, env=:mdtable, fmt="%.2d")


using UUIDs #Part of the standard library
[uuid4() for i in 1:4]


@linq dropmissing(penguins) |>
    select(:island, :species, :sex) |>
    by([:island, :species, :sex], count = length(:species)) |>
    where(:count .>= 20) |>
    orderby(:count)


tdf = @linq dropmissing(penguins) |>
    where(:species .== "Adelie") |>
    select(:island, :sex, :flipper_length)

plot(
    tdf,
    x=:island,
    y=:flipper_length,
    color=:sex,
    Geom.beeswarm,
    Guide.xlabel("Island"),
    Guide.ylabel("Flipper length (mm)")
) |>
PNG("figures/data_islands.png", dpi=600)

