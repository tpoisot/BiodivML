---
title: "Introduction to data wrangling"
layout: "presentation"
permalink: "data"
---


&nbsp;

---

class: center, middle

# Data Wrangling

## An introduction

---

# What ?

- Reproduce the up and coming `penguins` dataset

# Why ?

- `iris` comes from a long tradition of eugenics in statistics
- Penguins are cool
- We will see how to manipulate data simply

---

# Setting up our environment

We need to get data from a server, then we will read the data:

```julia
import CSV
```




We will manipulate these data as data frames:

```julia
using DataFrames
using DataFramesMeta
```




And maybe a plot?

```julia
using Gadfly
```




---

# Preparing the environment

Let's prepare a folder

```julia
ispath("data") || mkpath("data")
```




We use the following construct:

```
thing we want to be true || thing to do if the first part is false
```

--

This is equivalent to 

```
if ispath("data")
    continue
else
    mkpath("data")
end
```

but a little bit shorter - we will often use this *shorthand* notation

---

# Preparing to access the data

The data all share the same URI root


```julia
uri_root = "https://portal.edirepository.org/nis/dataviewer?packageid="
```

```
"https://portal.edirepository.org/nis/dataviewer?packageid="
```





--

We can get the datasets IDs in a `Dict`:

```julia
identifiers = Dict{String,String}(
    "adelie" => "knb-lter-pal.219.3&entityid=002f3893385f710df69eeebe893144ff",
    "gentoo" => "knb-lter-pal.220.3&entityid=e03b43c924f226486f2f0ab6709d2381",
    "chinstrap" => "knb-lter-pal.221.2&entityid=fe853aa8f7a59aa84cdd3197619ef462"
    )
```




---

# Accessing the data

To save time, we will download and save the files

```julia
for entry in identifiers
    penguin, identifier = entry
    datafile = joinpath("data", "$(penguin).csv")
    if isfile(datafile)
        continue
    else
        download(uri_root * identifier, datafile)
    end
end
```




--

We can have a look at the `data` folder:

```julia
readdir("data")
```

```
3-element Vector{String}:
 "adelie.csv"
 "chinstrap.csv"
 "gentoo.csv"
```





---