using Weave
using JuliaFormatter

sources = filter(endswith("jmd"), joinpath.("sources", readdir("sources")))

for source in sources
    # Get the slides
    weave(source; out_path = replace(source, "sources" => "docs"), informat = "markdown", doctype = "github")
    # Extract the code
    tangle(source; out_path = replace(source, "sources" => "scripts"))
end

# Format the codes in BlueStyle but keep the pipes!
for source in filter(endswith("jl"), joinpath.("scripts", readdir("scripts")))
    format(source, BlueStyle(), pipe_to_function_call = false)
end
