
using DataFrames, DataFramesMeta
using CSV: CSV
using Cairo: Cairo
using Fontconfig: Fontconfig
using Gadfly

using Statistics
using StatsBase
using MultivariateStats
using DecisionTree

penguins = joinpath("data", "penguins.csv") |> CSV.File |> DataFrame |> dropmissing

features = permutedims(
    Matrix(penguins[!, [:culmen_depth, :culmen_length, :flipper_length, :bodymass]])
)
labels = penguins.species

test_index = sample(1:length(labels), 50; replace=false)
train_index = filter(i -> !(i in test_index), 1:length(labels))

# DecisionTree follows the 'wrong' convention for features...
testset = (features[:, test_index]', vec(labels[test_index]))
trainset = (features[:, train_index]', vec(labels[train_index]))

model = build_tree(reverse(trainset)...)
model = prune_tree(model, 0.9)
print_tree(model, 3)

prediction = apply_tree(model, first(testset))
confusion_matrix(last(testset), prediction)

# We need to express these as row vectors
mn = vec(mean(features; dims=2))'
st = vec(std(features; dims=2))'

model = build_tree(last(trainset), (first(trainset) .- mn) ./ st)
model = prune_tree(model, 0.9)
prediction = apply_tree(model, (first(testset) .- mn) ./ st)
confusion_matrix(last(testset), prediction)

pingoo = [12.4, 46.7, 215.3, 4842.0]

nd = (pingoo .- μ) ./ σ

distances = vec(sqrt.(sum((nf .- nd) .^ 2.0; dims=1)))

plot(;
    y=sort(distances), Geom.line, Guide.xlabel("Rank of neighbor"), Guide.ylabel("Distance")
) |> PNG("figures/knndist.png"; dpi=600)

k = 5
neighbors = findall(sortperm(distances) .<= k)
neighbors'

penguins.species[neighbors]

votes = countmap(penguins.species[neighbors])

first(sort(collect(votes); by=(x) -> x.second, rev=true)).first

ftval = LinRange(-3, 3, 90)
ftcomb = vec(collect(Base.product(ftval, ftval)))
decisions = []
for (f1, f2) in ftcomb
    tv = [f1, f2, 0.0, 0.0]
    distances = vec(sqrt.(sum((nf .- tv) .^ 2.0; dims=1)))
    neighbors = findall(sortperm(distances) .<= 5)
    votes = countmap(penguins.species[neighbors])
    decision = first(sort(collect(votes); by=(x) -> x.second, rev=true)).first
    push!(decisions, decision)
end

f1 = [first(c) for c in ftcomb]
f2 = [last(c) for c in ftcomb]
plot(;
    x=f1,
    y=f2,
    color=decisions,
    Geom.rectbin,
    Guide.xlabel("Culmen depth (relative)"),
    Guide.ylabel("Culmen length (relative)"),
    Coord.cartesian(; xmin=-3, xmax=3, ymin=-3, ymax=3, fixed=true),
) |> PNG("figures/knnsim.png"; dpi=600)

function knn(
    v::Vector{TF}, features::Matrix{TF}, labels::Vector{TL}; k::Integer=5
) where {TF<:Number,TL}
    @assert length(v) == size(features, 1)
    @assert length(labels) == size(features, 2)
    @assert 1 <= k <= length(labels)

    Δ = vec(sqrt.(sum((v .- features) .^ 2.0; dims=1)))

    neighbors = findall(sortperm(Δ) .<= k)
    votes = countmap(labels[neighbors])
    decision = first(sort(collect(votes); by=(x) -> x.second, rev=true)).first

    return decision
end

labels = vec(String.(penguins.species))
features = nf

function accuracy(x::Vector{T}, y::Vector{T}) where {T}
    @assert length(x) == length(y)
    return sum(x .== y) / length(x)
end

guesses = similar(labels)

function loocv!(guesses, features, labels; k=3)
    for i in 1:size(features, 2)
        tf = features[:, setdiff(1:end, i)]
        tl = labels[setdiff(1:end, i)]
        guesses[i] = knn(vec(features[:, i]), tf, tl; k=k)
    end
    return accuracy(guesses, labels)
end

function loocv(features, labels; k=3)
    guesses = similar(labels)
    return loocv!(guesses, features, labels; k=k)
end

loocv!(guesses, features, labels)

K = collect(1:20)

acc = [loocv!(guesses, features, labels; k=k) for k in K]

plot(;
    x=K,
    y=acc,
    Geom.point,
    Geom.line,
    Guide.xlabel("Number of neighbors"),
    Guide.ylabel("Accuracy"),
) |> PNG("figures/knnloo.png"; dpi=600)
