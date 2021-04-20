using Weave
using Mustache

sources = filter(endswith("Jmd"), joinpath.("sources", readdir("sources")))

tmpl = read("slides.tpl")

for source in sources
    # Step 1 - generate a raw md file from the Jmd file
    weave(source; out_path = replace(source, "sources" => "out"), informat = "markdown", doctype = "github")
    # Step 2 - generate the html from the md file
    render()
end