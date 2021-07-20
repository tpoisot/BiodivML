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
- See the effect (or not!) of feature transformation on model performance

--

## Why we will do it

- Very few features are directly usable
- Models usually work best when we correct for statistical artifacts
- It's (sometimes) a good way to have fewer dimensions

---

# Before we start...

- Transformations are **models** that illuminate the relationship between predictors and response
    - they operate on features
    - their outputs are features
- There are **several books** focused only on feature engineering
- Most of the feature engineering techniques are **domain specific**
- We will focus on **frequent** and **powerful** techniques for quantitative predictors

---

# Setting up the environment

We will not need a lot more than for the previous module:

```julia
using DataFrames, DataFramesMeta
import CSV
```




We will add the `MultivariateStats` and `DecisionTree` packages to help.

```julia
using Statistics
using StatsBase
using MultivariateStats
using DecisionTree
```




The `DecisionTree` package assumes that features are rows, so we'll do a
lot of transpose (`'`).

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
([18.0 40.3 195.0 3250.0; 19.3 36.7 193.0 3450.0; … ; 14.8 45.2 212.0 5200.
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
L-> Feature 2, Threshold 43.150000000000006
    L-> Feature 1, Threshold 16.75
        L-> 
        R-> Adelie : 86/86
    R-> Feature 4, Threshold 4075.0
        L-> Chinstrap : 37/37
        R-> 
R-> Feature 1, Threshold 17.55
    L-> Gentoo : 84/84
    R-> Feature 1, Threshold 18.75
        L-> Adelie : 1/1
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
 44   2   0
  2  17   0
  0   0  35
Classes:  ["Adelie", "Chinstrap", "Gentoo"]
Matrix:   
Accuracy: 0.96
Kappa:    0.936487773896475
```




]

---

# Intermezzo - decision trees

- Work by splitting the dataset in two
- Splits are done on features, at some point maximizing a criteria
- There are many tree-based approaches for classification or regressions
- Random forests are usually a good initial guess (few parameters, work a little too well)

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
 45   1   0
  2  16   1
  0   0  35
Classes:  ["Adelie", "Chinstrap", "Gentoo"]
Matrix:   
Accuracy: 0.96
Kappa:    0.9360511590727417
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
 0.513882  0.0975826   0.395851  -0.0425886
 0.0       0.181682   -0.166326  -0.0144796
 0.0       0.0         0.118027  -0.138171
 0.0       0.0         0.0        0.00266943
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
 43   3   0
  2  17   0
  1   0  34
Classes:  ["Adelie", "Chinstrap", "Gentoo"]
Matrix:   
Accuracy: 0.94
Kappa:    0.9049730757047829
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
  0.37446    0.785161    0.468535  -0.154196
 -0.464671   0.617438   -0.622423   0.124262
 -0.572413  -0.0266553   0.244748  -0.782133
 -0.56232    0.0397711   0.577203   0.590806
```





| Feature            | Value                 |
|--------------------|-----------------------|
| Input dim.         | 4          |
| Output dim.        | 4         |
| Variance preserved | 1.0 |

---

class: split-50

# PCA - dimensionality reduction

Whitening keeps the *same* number of variables - it creates derived variables,
but keeps the same dimensionality.

--

PCA can *reduce* the number of variables, by keeping *just enough* to explain
a set proportion of variance. Here, starting from 4 features,
we can explain 99% of variance with 4 axis.

--

What do you think would happen with the "raw" features? Do you think the
fact that we keep all variables hints at some important truth about our data?

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
 45   1   0
  0  19   0
  0   1  34
Classes:  ["Adelie", "Chinstrap", "Gentoo"]
Matrix:   
Accuracy: 0.98
Kappa:    0.9684592335593755
```





---

# PCA - discussion

- The performance increased *a little*
- Why?

---

# Summary

| Model                | Accuracy            | Cohen's Kappa    |
|----------------------|---------------------|------------------|
| baseline             | 0.96 | 0.936487773896475 |
| center + standardize | 0.96 | 0.9360511590727417 |
| Whitening            | 0.94 | 0.9049730757047829 |
| PCA                  | 0.98 | 0.9684592335593755 |

--

## What's going on?

--

- decision trees are prone to **overfitting** (we'll get back to this with neural networks)
- the classes are essentially **linearly separable** - we can draw lines to split the dataset
- sometimes you don't **need** the fancy features transformation!
