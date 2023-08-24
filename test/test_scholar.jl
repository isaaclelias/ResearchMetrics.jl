# - [ ] rodar o código para o pesquisador com menor h-index
# - [ ]  

include("../src/hindex.jl")

using Test
using .HIndex
using Logging
using Plots
using TimeSeries

ENV["JULIA_DEBUG"] = HIndex
logger = SimpleLogger(stdout, Logging.Debug)
global_logger(logger)

@test begin
    abstract = Abstract("Large eddy simulation of OME3 and OME4 spray combustion under heavy-duty conditions")
    setBasicInfo!(abstract)
    response = querySerapiGScholarCite(abstract)
    print(response)
    setCitations!(abstract)
    true
end

@test begin
    author = Author("hasse", "technische universitat darmstadt")
    setBasicInfo!(author, only_local=true)
    setAuthoredAbstracts!(author, only_local=true)
    setCitations!(author, only_local=true)
    setCitationsBasicInfo!(author, only_local=true)
    setHIndex!(author)
    @info length(author.abstracts)
    print(author)
    hindex_plot = plot(author.scopus_hindex)
    savefig(hindex_plot, "output/$(author.scopus_lastname).png")
    true
end