
using DataFrames, DataFramesMeta
using CSV: CSV
using Cairo: Cairo
using Fontconfig: Fontconfig
using Gadfly

using Statistics, LinearAlgebra
using Distributions
using StatsBase

penguins = joinpath("data", "penguins.csv") |> CSV.File |> DataFrame |> dropmissing

mknorm(v) = Normal(mean(v), std(v))
group_species = groupby(penguins, :species)
morphodist = combine(
    group_species,
    :culmen_length => mknorm => :culmen_length,
    :culmen_depth => mknorm => :culmen_depth,
    :flipper_length => mknorm => :flipper_length,
    :bodymass => mknorm => :bodymass,
)
morphodist.bodymass[1] #Adelie penguin bodymass

i = rand(1:size(penguins, 1))
randompenguin =
    penguins[i, [:species, :culmen_length, :culmen_depth, :flipper_length, :bodymass]] |>
    DataFrame

features = [:culmen_length, :culmen_depth, :flipper_length, :bodymass]
sp = morphodist.species

p = zeros(Float64, (length(features), length(sp)))

for (i, ft) in enumerate(features)
    for (j, s) in enumerate(sp)
        p[i, j] = pdf(morphodist[j, ft], randompenguin[1, ft])
    end
end

p

class_k = vec(prod(p; dims=2)) |> argmax

morphodist.species[class_k]

predictions = eltype(morphodist.species)[]
p = zeros(Float64, (length(features), length(sp)))
for i in 1:size(penguins, 1)
    for (k, ft) in enumerate(features)
        for (j, s) in enumerate(sp)
            p[k, j] = pdf(morphodist[j, ft], penguins[i, ft])
        end
    end
    class_k = argmax(vec(prod(p; dims=2)))
    push!(predictions, morphodist.species[class_k])
end

countmap(predictions)

obs = penguins.species .== "Chinstrap"
prd = predictions .== "Chinstrap"

TP = sum(obs .& (obs .& prd))
FN = sum(obs .& (.!(obs .& prd)))
FP = sum(.!obs .& (.!obs .& prd))
TN = sum(.!obs .& (.!obs .& .!prd))
conf = [TP FN; FP TN]

@assert (TP + FN + FP + TN) == length(obs)

sum(diag(conf)) / sum(conf)
