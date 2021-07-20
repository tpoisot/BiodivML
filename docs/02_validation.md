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
   1 │ Adelie            39.8          19.1             184      4650
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
 0.140096     0.00307602  0.00574338
 0.270415     0.293771    6.95323e-5
 0.0394825    0.0141544   1.61154e-7
 0.000104657  6.02952e-5  0.00054119
```





---

# Assigning a sample to a class (part 3)

We can get our matrix of probability, and multiply its *columns* to get the
overall score:

```julia
vec(prod(p; dims=1))
```

```
3-element Vector{Float64}:
 1.5654138218804614e-7
 7.712080239019896e-10
 3.482927807796029e-17
```





We then feed this to `argmax`, and have a look at the class we get in return:

```julia
class_k = vec(prod(p; dims=1)) |> argmax
morphodist.species[class_k]
```

```
"Adelie"
```





This seems to work for this sample - how do we evaluate the overall success
of the model?

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
    class_k = argmax(vec(prod(p; dims=1)))
    push!(predictions, morphodist.species[class_k])
end
```




Note that this leads to some data re-use, but we used the summary statistics
and not the raw data, so it's cool.

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
 63    5
  6  260
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
0.9670658682634731
```





It's **pretty good**! But let's not take any risk, and try to understand in
depth how good the model really is.

---

class: split-50

# Measures of bias

The first thing we want to know is whether the model is *biased* towards
making certain predictions.

.column[
True Positive Rate (`TPR`):

```julia
TPR = TP/(TP+FN)
```

```
0.9264705882352942
```





True Negative Rate (`TNR`):

```julia
TNR = TN/(TN+FP)
```

```
0.9774436090225563
```




]

.column[
False Positive Rate (`FPR`):

```julia
FPR = FP/(FP+TN)
```

```
0.022556390977443608
```





False Negative Rate (`FNR`):

```julia
FNR = FN/(FN+TP)
```

```
0.07352941176470588
```




]

This classifier correctly identifies a Chinstrap as a Chinstrap 92% of the
time, and identifies something else as a Chinstrap only 2% of the time!

In other words, it's **really good** at telling if something is a Chinstrap
penguin or not.

---

class: split-50

# Measures of predictive potential

The confusion matrix can also inform us about *when* we can trust a model:

.column[
Positive Predictive Value (`PPV`):

```julia
PPV = TP/(TP+FP)
```

```
0.9130434782608695
```





Negative Predictive Value (`NPV`):

```julia
NPV = TN/(TN+FN)
```

```
0.9811320754716981
```




]

.column[
False Discovery Rate (`FDR`):

```julia
FDR = FP/(FP+TP)
```

```
0.08695652173913043
```





False Omission Rate (`FOR`):

```julia
FOR = FN/(FN+TN)
```

```
0.018867924528301886
```




]

A prediction of "not a Chinstrap" is true about 98% of the time (it's
great!). A prediction of "Chinstrap" is only true 91% of the time (it's still
pretty good!). The risks of *missing* and *falsely detecting* a Chinstrap
are respectively 1% and 8%.

---

class: split-50

# Broader measures of model performance

We can take a broader view of model "performance":

.column[
Accuracy (`ACC`):

```julia
ACC = (TP+TN)/(TP+TN+FP+FN)
```

```
0.9670658682634731
```





Balanced Accuracy (`BCC`):

```julia
BCC = (TPR + TNR) / 2.0
```

```
0.9519570986289252
```




]

.column[
Informedness (`INF`):

```julia
INF = TPR + TNR - 1
```

```
0.9039141972578504
```





]

The balanced accuracy (accounting for class prevalence) is **similar**
to the standard accuracy, but the dataset is almost perfectly balanced, so
this is normal. The informedness is about 90%. In other words, if you were
to bet on the model making a correct prediction, you would win 90% of the time!

---

class: split-50

# Comparison to random expectation

.column[
Random Accuracy (`RCC`):

```julia
N = TP+FP+TN+FN
RCC = ((TN + FP) * (TN + FN) +
    (FN + TP) * (FP + TP)) / (N * N)
```

```
0.6739395460575854
```





Cohen's κ (`CHN`):

```julia
CHN =  (ACC - RCC) / (1.0 - RCC)
```

```
0.8989937867707704
```




]

.column[

The *random* accuracy is much lower than to the measured accuracy! Cohen's
statistic is, therefore, very close to 1, which indicates a model with a
really high predictive value.

Taken together, these measures show that the model is **usable to tell
whether a sample is a Chinstrap penguin**, and that the risks associated to
under or over-prediction can be discussed.

]

---

# Wrapping up

## About the model

- it can be used for prediction!
- it tends to miss a little bit more Chinstrap than it misses
- the predictions are informative and a lot better than random

--

## About validation

- need to look at a variety of measures
- in some cases, biases can be acceptable, and you can decide on the acceptable level of bias
- the initial values of these measures provide a good baseline to see if we improve a model

