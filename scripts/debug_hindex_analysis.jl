include("../src/ResearchMetrics.jl")
using .ResearchMetrics
using Logging, LoggingExtras
using Dates
using Eyeball

io_path = "logs/hindex_"*Dates.format(now(), "yyyy-mm-dd_HH-MM")*".log"
touch(io_path)
io = open(io_path, "w+")
logger = TeeLogger(ConsoleLogger(stdout, Logging.Info),
                   SimpleLogger(io, Logging.Debug))
global_logger(logger)

researcher = Researcher("Rattman", "Aperture Science")
publications = [Publication("Morality Core",
                            Date("2005-10-01"),
                            citations=[Publication(Date("2006-10-01")),
                                       Publication(Date("2006-10-01"))])]

researchers = [ 
    Researcher("Hommelhoff", "Universität Erlangen-Nürnberg") # Survey 2
    Researcher("Martínez-Pinedo", "Technische Universitat Darmstadt") # Survey 3
    Researcher("André", "Universität Augsburg") # Survey 4
    Researcher("Haddadin", "Technische Universität München") # Survey 5
    Researcher("Wessling", "RWTH") # Survey 6
    #Author("schölkopf", "mpi") # Survey 7
    #Author("mädler", "universität bremen") # Survey 8
    #Author("grimme", "universität bonn") # Survey 9
    #Author("dreizler", "technische universität darmstadt") # Survey 9
    #Author("merklein", "universität erlangen-nürnberg") # Survey 8
    #Author("rosch", "universität zu köln") # Survey 7
]

function setinfoforhindex!(researcher::Researcher)
    println("Setting researcher info with Scopus Author Search")
    setScopusAuthorSearch!(researcher, only_local=true)
    println("Setting researcher publications with Scopus Search")
    setScopusSearch!(researcher, progress_bar=true, only_local=true)
    println("Setting information from Scopus Abstract Retrieval for each researcher's publications")
    mappublications(x -> setScopusAbstractRetrieval!(x, only_local=true), researcher, progress_bar=true)
    println("Setting citations for each researcher's publication with Serpapi Google Scholar Cite")
    mappublications(x -> setSerpapiGScholarCite!(x, only_local=true), researcher, progress_bar=true)
    println("Setting information from Scopus Abstract Retrieval for each researcher's citations")
    mapcitations(x -> setScopusAbstractRetrieval!(x, only_local=true), researcher, progress_bar=true)
end

setinfoforhindex!(researchers[1])
eye(researchers[1])
