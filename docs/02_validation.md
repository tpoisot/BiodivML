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
   1 │ Gentoo            52.2          17.1             228      5400
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
 4.95892e-7  0.0718783   0.0417242
 0.193901    0.178649    0.041799
 2.84698e-9  2.12674e-6  0.0158058
 9.49334e-7  8.54096e-8  0.000659074
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





Interestingly, the correct class was "Gentoo", but this is
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
our model is misbehaving. 

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
0.7205882352941176
```





True Negative Rate (`TNR`):

```julia
TNR = TN/(TN+FP)
```

```
0.32706766917293234
```




]

.column[
False Positive Rate (`FPR`):

```julia
FPR = FP/(FP+TN)
```

```
0.6729323308270677
```





False Negative Rate (`FNR`):

```julia
FNR = FN/(FN+TP)
```

```
0.27941176470588236
```




]

This classifier correctly identifies a Chinstrap as a Chinstrap 72% of the
time, but identifies something else as a Chinstrap 67% of the time!

In other words, it's predicting *a lot more* Chinstrap penguins than we
should expect.

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
0.2149122807017544
```





Negative Predictive Value (`NPV`):

```julia
NPV = TN/(TN+FN)
```

```
0.8207547169811321
```




]

.column[
False Discovery Rate (`FDR`):

```julia
FDR = FP/(FP+TP)
```

```
0.7850877192982456
```





False Omission Rate (`FOR`):

```julia
FOR = FN/(FN+TN)
```

```
0.1792452830188679
```




]

A prediction of "not a Chinstrap" is true about 82% of the time (it's
great!). A prediction of "Chinstrap" is only true 21% of the time (it's
not ideal!).

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
0.40718562874251496
```





Balanced Accuracy (`BCC`):

```julia
BCC = (TPR + TNR) / 2.0
```

```
0.523827952233525
```




]

.column[
Informedness (`INF`):

```julia
INF = TPR + TNR - 1
```

```
0.047655904467049925
```





]

The balanced accuracy (accounting for class prevalence) is **higher** than
the standard accuracy, suggesting a very bad model. The informedness is
essentially 0, meaning that the model is not giving useful information.

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
0.3917315070457887
```





Cohen's κ (`CHN`):

```julia
CHN =  (ACC - RCC) / (1.0 - RCC)
```

```
0.025406743692525297
```




]

.column[

The *random* accuracy is approximatively equal to the measured
accuracy! Cohen's statistic is, therefore, very close to 0, which indicates
a model with no predictive value whatsoever.

Taken together, these measures show that the model is **not usable to tell
whether a sample is a Chinstrap penguin**.

]

---

# Wrapping up

## About the model

- it cannot be used for predictions!
- it has a systematic bias towards over-predicting Chinstrap as a class
- the predictions are barely better than they would at random

--

## About validation

- need to look at a variety of measures
- in some cases, biases can be acceptable
- the initial values of these measures provide a good baseline to see if we improve a model

---

# Open discussion: why is this model so bad?

Think about the assumptions of Naive Bayesian Classifiers - are some of
these assumptions likely to decrease the performance of this model, based
on characteristics of the dataset?