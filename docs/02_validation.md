---
title: "Validation for classifiers"
layout: "presentation"
permalink: "validation"
---


# Validation for classifiers

## Understanding model fitness

---

# Class agenda

## What we will do

- Use a Naive Bayesian Classifier to create a confusion table
- Measure validation measures on the confusion table
- Discuss the suitability of the model

--

## Why we will do it

- Validation is *fundamental*
- Errors in models can be acceptable
- The same approach works for more complex models

---

# Setting up the environment

We will not need a lot more than for the previous module:

```julia
using DataFrames, DataFramesMeta
import CSV
import Cairo, Fontconfig
using Gadfly
```




To simplify our work, we will add the `StatsBase` package, which will make the
code nicer to write:

```julia
using Statistics, LinearAlgebra
using Distributions
using StatsBase
```




--

As a sidenote, the code in this module is *really not optimized* -- it would
be a good exercise to go through it an express everything to use `Matrix`
instead of `DataFrame`.

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

---

class: split-50

# Naive Bayesian What?

.column[
- A classifier using **distribution** of features values
- Assumes i.i.d. features ("naive")
- Returns the probability of a class given the features ("Bayesian") 
]

--

.column[
- NBC works with a very small data volume
- NBC is *fast* (lookup the PDF for a known distribution)
- NBC is surprisingly effective!
]

---

# Naive Bayes Classifier

For each class $C_k$, we want to calculate $p(C_k | \mathbf{v})$ (where
$\mathbf{v}$ is a vector of features).

Because there are several features and we assume that they are independant,
we can write


$$
p(C_k|\mathbf{v}) \propto p(C_k)\times \prod_i p(v_i | C_k)
$$

This *is* Bayes' rule, with $\propto$ replacing $=$ as we do not divide by $p(\textbf{v})$ which is constant across classes

We finally get the class for an observation as $\text{argmax}\left(p(C_k)\times
\prod_i p(v_i | C_k)\right)$

---

# Getting the distributions for every class

We will build a model to predict if a penguin is a Chinstrap or not. We do
have three classes, but we will simplify this (after the prediction!) as
"Chinstrap" *v.* "not Chinstrap".

We will assume that the distributions are all normal -- because they are
independant, there is no need to apply a transformation.

```julia
mknorm(v) = Normal(mean(v), std(v))
group_species = groupby(penguins, :species)
morphodist = combine(group_species,
    :culmen_length => mknorm => :culmen_length,
    :culmen_depth => mknorm => :culmen_depth,
    :flipper_length => mknorm => :flipper_length,
    :bodymass => mknorm => :bodymass
    )
morphodist.bodymass[1] #Adelie penguin bodymass
```

```
Distributions.Normal{Float64}(μ=3706.1643835616437, σ=458.6201347129234)
```





---

# Assigning a sample to a class (part 1)

Let's draw a penguin at random:

```julia
i = rand(1:size(penguins,1))
randompenguin = penguins[
    i,
    [:species, :culmen_length, :culmen_depth, :flipper_length, :bodymass]
] |> DataFrame
```

```
1×5 DataFrame
 Row │ species  culmen_length  culmen_depth  flipper_length  bodymass
     │ String   Float64        Float64       Int64           Int64
─────┼────────────────────────────────────────────────────────────────
   1 │ Adelie            34.6          17.2             189      3200
```





---

# Assigning a sample to a class (part 2)

We can now get its probability of `randompenguin` belonging to every class:

```julia
features = [:culmen_length, :culmen_depth, :flipper_length, :bodymass]
sp = morphodist.species

p = zeros(Float64, (length(features), length(sp)))

for (i,ft) in enumerate(features)
    for (j,s) in enumerate(sp)
        p[i,j] = pdf(morphodist[j,ft], randompenguin[1,ft])
    end
end

p
```

```
4×3 Matrix{Float64}:
 0.0425706    1.35455e-5   2.17571e-5
 0.210161     0.197154     0.0334836
 0.0603021    0.035394     5.74265e-6
 0.000473101  0.000396675  6.22896e-7
```





---

# Assigning a sample to a class (part 3)

We can get our matrix of probability, and multiply its *columns* to get the
overall score, then feed this to `argmax`:

```julia
class_k = vec(prod(p; dims=2)) |> argmax
```

```
2
```





We can finally check which class this was actually:

```julia
morphodist.species[class_k]
```

```
"Chinstrap"
```





Interestingly, the correct class was "Adelie", but this is
not the answer we get. So, how do we evalue the model performance?

---

# Running the entire model

We will perform the NBC step for all samples in the dataset.

```julia
predictions = eltype(morphodist.species)[]
p = zeros(Float64, (length(features), length(sp)))
for i in 1:size(penguins, 1)
    for (k,ft) in enumerate(features)
        for (j,s) in enumerate(sp)
            p[k,j] = pdf(morphodist[j,ft], penguins[i,ft])
        end
    end
    class_k = argmax(vec(prod(p; dims=2)))
    push!(predictions, morphodist.species[class_k])
end
```




Note that this leads to some data re-use, but we used the summary statistics
and not the raw data, so it's cool.

```julia
countmap(predictions)
```

```
Dict{String, Int64} with 3 entries:
  "Adelie"    => 89
  "Gentoo"    => 17
  "Chinstrap" => 228
```





---

# How good is the model?

The only information we care about is whether the model works for Chinstrap
penguins - therefore, we can transform the classified `String`s into `Bool`s.

```julia
obs = penguins.species .== "Chinstrap"
prd = predictions .== "Chinstrap"
```




We will compare these two values in a **confusion matrix**:

|                | predicted true | predicted false |
|----------------|----------------|-----------------|
| observed true  | TP             | FN              |
| observed false | FP             | TN              |

---

# Filling the confusion matrix

We can get the components of the confusion matrix with simple boolean operations:

```julia
TP = sum(obs .& (obs.&prd))
FN = sum(obs .& (.!(obs.&prd)))
FP = sum(.!obs .& (.!obs .& prd))
TN = sum(.!obs .& (.!obs .& .!prd))
conf = [TP FN; FP TN]
```

```
2×2 Matrix{Int64}:
  49  19
 179  87
```





Note that the sum of the confusion matrix should be the length of the
predictions, which we can check with `@assert`:

```julia
@assert (TP + FN +FP + TN) == length(obs)
```




---

# Revisiting accuracy

Last time, we defined accuracy as the proportion of correct guesses - we
can get it by dividing the trace of the matrix by the sum of the matrix:

```julia
sum(diag(conf))/sum(conf)
```

```
0.40718562874251496
```





It's **pretty bad**! This is a good opportunity to figure out why and how
our model is misbehaving. But first, let's redefine a few terms:

| Term      | Definition          | How to get it | Value       |
|-----------|---------------------|---------------|-------------|
| Incidence | Number of positives | `TP + FN`     | 68 |
