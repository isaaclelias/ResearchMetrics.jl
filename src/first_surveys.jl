include("hindex.jl")
using .HIndex
using Logging
using Plots

ENV["JULIA_DEBUG"] = HIndex
logger = SimpleLogger(stdout, Logging.Error+1)
global_logger(logger)

authors = [ 
    Author("hommelhoff", "universität erlangen-nürnberg") # Survey 2
    Author("martínez-pinedo", "technische universitat darmstadt") # Survey 3
    Author("andré", "universität augsburg") # Survey 4
    Author("haddadin", "technische universität münchen") # Survey 5
    Author("wessling", "rwth") # Survey 6
    Author("schölkopf", "mpi") # Survey 7
    Author("mädler", "universität bremen") # Survey 8
    Author("grimme", "universität bonn") # Survey 9
    Author("dreizler", "technische universität darmstadt") # Survey 9
    Author("merklein", "universität erlangen-nürnberg") # Survey 8
    Author("rosch", "universität zu köln") # Survey 7
]

@time Threads.@threads for author in authors
    setBasicInfo!(author, only_local=true)
    setAuthoredAbstracts!(author, only_local=true)
    setCitations!(author, only_local=true)
    setCitationsBasicInfo!(author, only_local=true)
    setHIndex!(author)
    hindex_plot = plot(author.scopus_hindex)
    #=
    for author in authors
        for abstract in filter(x->!isnothing(x.scopus_citation_count), author.abstracts)
            print(abstract)
        end
    end
    =#
    #savefig(hindex_plot, "output/$(author.scopus_lastname).png")
end

for author in authors
    print(author.scopus_hindex)
end