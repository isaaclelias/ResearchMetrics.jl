include("../src/hindex.jl")
using .HIndex
using Dates
using Logging, LoggingExtras
using Plots

ENV["JULIA_DEBUG"] = HIndex
io_path = "logs/hindex_"*Dates.format(now(), "yyyy-mm-dd_HH-MM")*".log"
touch(io_path)
io = open(io_path, "w+")
logger = TeeLogger(ConsoleLogger(stdout, Logging.Debug),
                   SimpleLogger(io, Logging.Debug))
global_logger(logger)

authors = [ 
    #Author("hommelhoff", "universität erlangen-nürnberg") # Survey 2
    #Author("martínez-pinedo", "technische universitat darmstadt") # Survey 3
    #Author("andré", "universität augsburg") # Survey 4
    #Author("haddadin", "technische universität münchen") # Survey 5
    Author("wessling", "rwth") # Survey 6
    Author("schölkopf", "mpi") # Survey 7
    Author("mädler", "universität bremen") # Survey 8
    Author("grimme", "universität bonn") # Survey 9
    Author("dreizler", "technische universität darmstadt") # Survey 9
    Author("merklein", "universität erlangen-nürnberg") # Survey 8
    Author("rosch", "universität zu köln") # Survey 7
] 

for author in authors
    setBasicInfo!(author)
    setAuthoredAbstracts!(author)
    setCitations!(author)
    @debug "setCitationsBasicInfo starts here"
    setCitationsBasicInfo!(author)
    setHIndex!(author)
    hindex_plot = plot(author.scopus_hindex)
    #=
    for author in authors
        for abstract in filter(x->!isnothing(x.scopus_citation_count), author.abstracts)
            print(abstract)
        end
    end
    =#
    savefig(hindex_plot, "output/$(author.scopus_lastname).png")
    open("output/$(author.scopus_lastname)", "w") do file
        print(file, author)
    end
end

for author in authors
    print(author.scopus_hindex)
    @debug dump(author)
end
