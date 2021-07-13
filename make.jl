using Weave

sources = filter(endswith("jmd"), joinpath.("sources", readdir("sources")))

for source in sources
    weave(source; out_path = replace(source, "sources" => "docs"), informat = "markdown", doctype = "github")
    tangle(source; out_path = replace(source, "sources" => "scripts"))
end
