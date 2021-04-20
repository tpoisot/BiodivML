using Weave

sources = filter(endswith("Jmd"), joinpath.("sources", readdir("sources")))

for source in sources
    weave(source; out_path = replace(source, "sources" => "docs"), informat = "markdown", doctype = "github")
end