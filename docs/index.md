---
title: Index
---

# Machine learning for biodiversity workshop

Before you start, make sure you have a working installation of
[Julia](http://julialang.org). All of the classes can be done within the
terminal, but I strongly suggest you find a development environment that
suits you (VSCode, Juno, Pluto, and Jupyter are all user-friendly with a
lot of features).

All of the classes use the same *project*, which can be [downloaded from the
repo](https://raw.githubusercontent.com/tpoisot/BiodivML/main/Project.toml),
so every working session should start by making sure the project is activated.

This can be done with

~~~
julia --project
~~~

at the command line, from the directory in which you work; it can also be
done by typing

~~~
]
activate .
<backspace>
~~~

from within the Julia REPL.

# List of topics

| Class | Topic                       | Source                        |
|:-----:|-----------------------------|-------------------------------|
|   1   | [Data wrangling][wrangling] | [data.jl](scripts/00_data.jl) |
|   2   | [k-NN from scratch][knn]    | [knn.jl](scripts/01_knn.jl)   |
|   3   | Trees and forests           |                               |
|   4   | Boosted Regression Trees    |                               |
|   5   | Latent variables            |                               |
|   6   | Artificial Neural Networks  |                               |

[wrangling]: data.html
[knn]: knn.html
