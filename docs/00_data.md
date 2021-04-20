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




We will also plot and pretty-print tables:

```julia
using Gadfly
import Cairo, Fontconfig
import Latexify
```




---

# Preparing the environment

Let's prepare a folder

```julia
penguin_path = joinpath("data", "penguins")
ispath(penguin_path) || mkpath(penguin_path)
```




We use the following construct:

```
thing we want to be true || thing to do if the first part is false
```

--

This is equivalent to 

```
if ispath("data/penguins")
    continue
else
    mkpath("data/penguins")
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
    datafile = joinpath("data", "penguins", "$(penguin).csv")
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
readdir(joinpath("data", "penguins"))
```

```
3-element Vector{String}:
 "adelie.csv"
 "chinstrap.csv"
 "gentoo.csv"
```





---

# Examining the data

We can have a look at the data, to get a sense for what the columns are:

```julia
adelie = DataFrame(CSV.File(joinpath("data", "penguins", "adelie.csv")))
Latexify.latexify(adelie[1:3,1:7], latex=false, env=:mdtable)
```


| studyName | Sample Number |                             Species | Region |    Island |              Stage | Individual ID |
| ---------:| -------------:| -----------------------------------:| ------:| ---------:| ------------------:| -------------:|
|   PAL0708 |             1 | Adelie Penguin (Pygoscelis adeliae) | Anvers | Torgersen | Adult, 1 Egg Stage |          N1A1 |
|   PAL0708 |             2 | Adelie Penguin (Pygoscelis adeliae) | Anvers | Torgersen | Adult, 1 Egg Stage |          N1A2 |
|   PAL0708 |             3 | Adelie Penguin (Pygoscelis adeliae) | Anvers | Torgersen | Adult, 1 Egg Stage |          N2A1 |




--

There is a lot of information we will *not* want to keep! In the next step, we
will remove a large part of it. Note that the column names have both spaces and
metadata, which is not good practices.

---

# Columns selection

We will start by selecting the columns we care about (after a bit of manual
inspection).

```julia
colnames = [
    "Species", "Region", "Island", "Culmen Length (mm)", "Culmen Depth (mm)",
    "Flipper Length (mm)", "Body Mass (g)", "Sex"
]
select!(adelie, Symbol.(colnames))
Latexify.latexify(adelie[1:5,1:5], latex=false, env=:mdtable)
```


|                             Species | Region |    Island | Culmen Length (mm) | Culmen Depth (mm) |
| -----------------------------------:| ------:| ---------:| ------------------:| -----------------:|
| Adelie Penguin (Pygoscelis adeliae) | Anvers | Torgersen |               39.1 |              18.7 |
| Adelie Penguin (Pygoscelis adeliae) | Anvers | Torgersen |               39.5 |              17.4 |
| Adelie Penguin (Pygoscelis adeliae) | Anvers | Torgersen |               40.3 |              18.0 |
| Adelie Penguin (Pygoscelis adeliae) | Anvers | Torgersen |            missing |           missing |
| Adelie Penguin (Pygoscelis adeliae) | Anvers | Torgersen |               36.7 |              19.3 |




---

# Columns renaming

We will give the columns better name for data manipulation: lowercase, no
spaces, no metadata.

```julia
renames = [
    "Species" => "species", "Region" => "region", "Island" => "island", 
    "Culmen Length (mm)" => "culmen_length", "Culmen Depth (mm)" => "culmen_depth",
    "Flipper Length (mm)" => "flipper_length", "Body Mass (g)" => "bodymass",
    "Sex" => "sex"
]
rename!(adelie, renames...)
adelie.species .= "Adelie"
Latexify.latexify(first(adelie, 6), latex=false, env=:mdtable)
```


| species | region |    island | culmen_length | culmen_depth | flipper_length | bodymass |     sex |
| -------:| ------:| ---------:| -------------:| ------------:| --------------:| --------:| -------:|
|  Adelie | Anvers | Torgersen |          39.1 |         18.7 |            181 |     3750 |    MALE |
|  Adelie | Anvers | Torgersen |          39.5 |         17.4 |            186 |     3800 |  FEMALE |
|  Adelie | Anvers | Torgersen |          40.3 |         18.0 |            195 |     3250 |  FEMALE |
|  Adelie | Anvers | Torgersen |       missing |      missing |        missing |  missing | missing |
|  Adelie | Anvers | Torgersen |          36.7 |         19.3 |            193 |     3450 |  FEMALE |
|  Adelie | Anvers | Torgersen |          39.3 |         20.6 |            190 |     3650 |    MALE |




---

# Merging the three datasets

```julia
function clean_penguin_df(species::AbstractString)
    df = DataFrame(CSV.File(joinpath("data", "penguins", lowercase(species)*".csv")))
    select!(df, Symbol.(colnames))
    rename!(df, renames...)
    df.species .= species
    return df
end
```




--

We can now `map` this function for the three species, and the concatenate the
results:

```julia
penguins = vcat(clean_penguin_df.(["Adelie", "Chinstrap", "Gentoo"])...)
Latexify.latexify(first(penguins, 3), latex=false, env=:mdtable)
```


| species | region |    island | culmen_length | culmen_depth | flipper_length | bodymass |    sex |
| -------:| ------:| ---------:| -------------:| ------------:| --------------:| --------:| ------:|
|  Adelie | Anvers | Torgersen |          39.1 |         18.7 |            181 |     3750 |   MALE |
|  Adelie | Anvers | Torgersen |          39.5 |         17.4 |            186 |     3800 | FEMALE |
|  Adelie | Anvers | Torgersen |          40.3 |         18.0 |            195 |     3250 | FEMALE |




---

# Saving the artifacts!

We have done a lot of work we do *not* want to lose:

```julia
CSV.write(joinpath("data", "penguins.csv"), penguins)
```

```
"data/penguins.csv"
```





--

We will call a *[computational artifact][artifact]* anything that is written to
disk:

- intermediate files
- scripts
- figures

[artifact]: https://plato.stanford.edu/entries/computer-science/

---

# Taking a step back

So far, we have

- **read** data from a remote machine   
`download`
--

- **loaded** these data from the disk to memory   
`CSV.File`, `DataFrame`
--

- **cleaned** a data file to decide what to keep   
`rename!`, `select!`
--

- **applied** the cleaning to the entire dataset   
`.` , `vcat`
--

- **saved** the dataset we will actually use to disk   
`CSV.Write`

---

class: split-30

# Looking at relationships

.column[
```julia
plot(penguins,
    x=:culmen_length,
    y=:culmen_depth,
    color=:species,
    Geom.point
);
```



]

.column[
![Culmen plot](/figures/00_data_culmen_1.png)
]

---

class: split-40

# Looking at distributions

.column[
```julia
plot(
    dropmissing(
        select(
        penguins,
        [:species, :bodymass])
    ),
    x=:bodymass,
    color=:species,
    Geom.density
);
```



]

.column[
![Bodymass plot](/figures/00_data_bodymass_1.png)
]
