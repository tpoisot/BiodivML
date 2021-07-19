
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

test_index = sample(1:length(labels), 100; replace=false)
train_index = filter(i -> !(i in test_index), 1:length(labels))

# DecisionTree follows the 'wrong' convention for features...
testset = (features[:, test_index]', vec(labels[test_index]))
trainset = (features[:, train_index]', vec(labels[train_index]))

model = build_tree(reverse(trainset)...)
model = prune_tree(model, 0.9)
print_tree(model, 3)

prediction = apply_tree(model, first(testset))
cm_bas = confusion_matrix(last(testset), prediction)

# We need to express these as row vectors
mn = vec(mean(features; dims=2))'
st = vec(std(features; dims=2))'

model = build_tree(last(trainset), (first(trainset) .- mn) ./ st)
model = prune_tree(model, 0.9)
prediction = apply_tree(model, (first(testset) .- mn) ./ st)
cm_cen = confusion_matrix(last(testset), prediction)

cov(features')

W = fit(Whitening, first(trainset)')
W.W

model = build_tree(last(trainset), MultivariateStats.transform(W, first(trainset)')')
model = prune_tree(model, 0.9)
prediction = apply_tree(model, MultivariateStats.transform(W, first(testset)')')
cm_whi = confusion_matrix(last(testset), prediction)

ctrain = ((first(trainset) .- mn) ./ st)'
ctest = ((first(testset) .- mn) ./ st)'
P = fit(PCA, ctrain)

projection(P)

model = build_tree(last(trainset), MultivariateStats.transform(P, ctrain)')
model = prune_tree(model, 0.9)
prediction = apply_tree(model, MultivariateStats.transform(P, ctest)')
cm_pca = confusion_matrix(last(testset), prediction)
