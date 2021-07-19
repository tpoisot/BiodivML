---
title: "Optimizing features"
layout: "presentation"
permalink: "features"
---


# Optimizing features

## PCA and all that

---

# Class agenda

## What we will do

- Apply some transformation on the penguins dataset
- Discuss the difference between PCA in ecology and machine learning
- See the effect of feature transformation on model performance

--

## Why we will do it

- Very few features are directly usable
- Models usually work best when we correct for statistical artifacts
- It's (sometimes) a good way to have fewer dimensions

---

# Setting up the environment

We will not need a lot more than for the previous module:

```julia
using DataFrames, DataFramesMeta
import CSV
import Cairo, Fontconfig
using Gadfly
```




We will add the `MultivariateStats` and `DecisionTree` packages to help.

```julia
using Statistics
using StatsBase
using MultivariateStats
using DecisionTree
```




---

# Loading the data

We will get the `penguins` data from the previous module -- as a reminder, we
can load them using *pipes*:

```julia
penguins = 
    joinpath("data", "penguins.csv") |>
    CSV.File |>
    DataFrame |>
    dropmissing
```




Note that we add `dropmissing` (about 10 records) to avoid having to deal with
the issue of `Missing` data (for now).

```julia
features = permutedims(Matrix(penguins[!,[:culmen_depth, :culmen_length, :flipper_length, :bodymass]]))
labels = penguins.species
```




---

# Training and testing

We will split our dataset into a training and testing set.

```julia
test_index = sample(1:length(labels), 100, replace=false)
train_index = filter(i -> !(i in test_index), 1:length(labels))
```




To avoid having too many variables, we will carry the test/train
features/labels together in tuples:

```julia
# DecisionTree follows the 'wrong' convention for features...
testset = (features[:,test_index]', vec(labels[test_index]))
trainset = (features[:,train_index]', vec(labels[train_index]))
```

```
([18.7 39.1 181.0 3750.0; 17.4 39.5 186.0 3800.0; … ; 14.8 45.2 212.0 5200.
0; 16.1 49.9 213.0 5400.0], ["Adelie", "Adelie", "Adelie", "Adelie", "Adeli
e", "Adelie", "Adelie", "Adelie", "Adelie", "Adelie"  …  "Gentoo", "Gentoo"
, "Gentoo", "Gentoo", "Gentoo", "Gentoo", "Gentoo", "Gentoo", "Gentoo", "Ge
ntoo"])
```





---

class: split-50

# A baseline model

We will use a regression tree (using CART, from `DecisionTree`) to classify
penguins based on features:

.column[
```julia
model = build_tree(reverse(trainset)...)
model = prune_tree(model, 0.9)
print_tree(model, 3)
```

```
Feature 3, Threshold 206.5
L-> Feature 2, Threshold 43.35
    L-> Feature 2, Threshold 42.349999999999994
        L-> Adelie : 88/88
        R-> 
    R-> Feature 4, Threshold 4175.0
        L-> Chinstrap : 42/42
        R-> 
R-> Feature 1, Threshold 17.65
    L-> Gentoo : 83/83
    R-> Feature 1, Threshold 18.95
        L-> Adelie : 2/2
        R-> Chinstrap : 4/4
```




]

.column[
```julia
prediction = apply_tree(model, first(testset))
cm_bas = confusion_matrix(last(testset), prediction)
```

```
3×3 Matrix{Int64}:
 48   1   0
  1  14   0
  0   0  36
Classes:  ["Adelie", "Chinstrap", "Gentoo"]
Matrix:   
Accuracy: 0.98
Kappa:    0.9670944389601842
```




]

---

class: split-50

# Centering and Standardizing

The data are not expressed in the same unit - we will apply a simple $z$-score
transformation, as we did with our bespoke $k$-NN:

.column[
```julia
# We need to express these as row vectors
mn = vec(mean(features, dims=2))'
st = vec(std(features, dims=2))'
```

```
1×4 adjoint(::Vector{Float64}) with eltype Float64:
 1.96791  5.46052  14.0222  804.836
```




]

.column[
```julia
model = build_tree(last(trainset), (first(trainset).-mn)./st)
model = prune_tree(model, 0.9)
prediction = apply_tree(model, (first(testset).-mn)./st)
cm_cen = confusion_matrix(last(testset), prediction)
```

```
3×3 Matrix{Int64}:
 47   2   0
  1  14   0
  0   0  36
Classes:  ["Adelie", "Chinstrap", "Gentoo"]
Matrix:   
Accuracy: 0.97
Kappa:    0.9509162303664921
```




]

---

# Centering and Standardizing - discussion

- There is not a great difference in performance
- Why?

---

# Covariance (it's a problem)

Data have a *covariance*:

```julia
cov(features')
```

```
4×4 Matrix{Float64}:
    3.87267    -2.45692   -15.9697  -749.138
   -2.45692    29.8173     49.9322  2588.84
  -15.9697     49.9322    196.621   9854.67
 -749.138    2588.84     9854.67       6.47761e5
```





In short, knowing something about a variable *might* tell us something about another variable.

---

# Whitening - fixing covariance

Whitening transforms creates a set of *new variables*, whose covariance matrix is the *identity matrix*.

These new variables are uncorrelated, and all have unit variance.

```julia
W = fit(Whitening, first(trainset)')
W.W
```

```
4×4 Matrix{Float64}:
 0.492984  0.090939   0.360905  -0.0513474
 0.0       0.189065  -0.157569  -0.00470196
 0.0       0.0        0.11283   -0.12893
 0.0       0.0        0.0        0.0025738
```





---

# Whitening

```julia
model = build_tree(last(trainset), MultivariateStats.transform(W, first(trainset)')')
model = prune_tree(model, 0.9)
prediction = apply_tree(model, MultivariateStats.transform(W, first(testset)')')
cm_whi = confusion_matrix(last(testset), prediction)
```

```
3×3 Matrix{Int64}:
 47   1   1
  1  14   0
  1   0  35
Classes:  ["Adelie", "Chinstrap", "Gentoo"]
Matrix:   
Accuracy: 0.96
Kappa:    0.9341888779203685
```





---

# Whitening - transformations are model

Note that we can transform *any* vector with 4 elements corresponding to the features into a set of random variables.

The transformation *is* a model!

This will be important for PCA.

---

# Whitening - discussion

- There is a small dip in performance
- Why?

---

# PCA - reprojecting the variables

```julia
ctrain = ((first(trainset).-mn)./st)'
ctest = ((first(testset).-mn)./st)'
P = fit(PCA, ctrain)
```

```
PCA(indim = 4, outdim = 4, principalratio = 1.0)
```



```julia
projection(P)
```

```
4×4 Matrix{Float64}:
  0.420032  0.789643    0.419332   0.155556
 -0.433409  0.605103   -0.652432  -0.142616
 -0.584209  0.0282118   0.24525    0.773147
 -0.542614  0.0975581   0.581675  -0.598085
```





| Feature            | Value                 |
|--------------------|-----------------------|
| Input dim.         | 4          |
| Output dim.        | 4         |
| Variance preserved | 1.0 |

---

class: split-50

# PCA - dimensionality reduction

Whitening kept the *same* number of variables.

--

PCA can *reduce* the number of variables, by keeping *just enough* to explain
a set proportion of variance. Here, starting from 4 features,
we can explain 99% of variance with 4 axis.

--

What do you think would happen with the "raw" features?

---

# PCA

```julia
model = build_tree(last(trainset), MultivariateStats.transform(P, ctrain)')
model = prune_tree(model, 0.9)
prediction = apply_tree(model, MultivariateStats.transform(P, ctest)')
cm_pca = confusion_matrix(last(testset), prediction)
```

```
3×3 Matrix{Int64}:
 47   2   0
  0  15   0
  0   0  36
Classes:  ["Adelie", "Chinstrap", "Gentoo"]
Matrix:   
Accuracy: 0.98
Kappa:    0.9674585095997397
```





---

# PCA - discussion

- The performance increased *a little*
- Why?

---

# Summary

| Model                | Accuracy            | Cohen's Kappa    |
|----------------------|---------------------|------------------|
| baseline             | 0.98 | 0.9670944389601842 |
| center + standardize | 0.97 | 0.9509162303664921 |
| Whitening            | 0.96 | 0.9341888779203685 |
| PCA                  | 0.98 | 0.9674585095997397 |

--

## What's going on?

--

- decision trees are prone to **overfitting** (we'll get back to this with neural networks)
- the classes are essentially **linearly separable** - we can draw lines to split the dataset
- sometimes you don't **need** the fancy features transformation!
