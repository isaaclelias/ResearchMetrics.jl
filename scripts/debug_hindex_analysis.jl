include("../src/ResearchMetrics.jl")
using .ResearchMetrics
using Logging, LoggingExtras
using Dates
using Eyeball
using Serialization

io_path = "logs/hindex_"*Dates.format(now(), "yyyy-mm-dd_HH-MM")*".log"
touch(io_path)
io = open(io_path, "w+")
logger = TeeLogger(ConsoleLogger(stdout, Logging.Info),
                   SimpleLogger(io, Logging.Debug))
global_logger(logger)

researchers = [ 
    Researcher("Hommelhoff",
               "Universität Erlangen-Nürnberg",
               prizes = [Prize("Gottfried Wilhelm Leibniz Prize", "2022-01-01")])
    Researcher("Martínez-Pinedo",
               "Technische Universitat Darmstadt",
               prizes = [Prize("Gottfried Wilhelm Leibniz Prize", "2022-01-01")])
    Researcher("André",
               "Universität Augsburg",
               prizes = [Prize("Gottfried Wilhelm Leibniz Prize", "2021-01-01")])
    Researcher("Haddadin",
               "Technische Universität München",
               prizes = [Prize("Gottfried Wilhelm Leibniz Prize", "2019-01-01")])
    Researcher("Wessling", 
               "RWTH",
               prizes = [Prize("Gottfried Wilhelm Leibniz Prize", "2019-01-01")])
    Researcher("Schölkopf",
               "MPI",
               prizes = [Prize("Gottfried Wilhelm Leibniz Prize", "2018-01-01")])
    Researcher("Mädler",
               "Universität Bremen",
               prizes = [Prize("Gottfried Wilhelm Leibniz Prize", "2017-01-01")])
    Researcher("Grimme",
               "Universität Bonn",
               prizes = [Prize("Gottfried Wilhelm Leibniz Prize", "2015-01-01")])
    Researcher("Dreizler",
               "Technische Universität Darmstadt",
               prizes = [Prize("Gottfried Wilhelm Leibniz Prize", "2014-01-01")])
    Researcher("Merklein",
               "Universität Erlangen-Nürnberg",
               prizes = [Prize("Gottfried Wilhelm Leibniz Prize", "2013-01-01")])
    Researcher("Eosch",
               "Universität zu Köln",
               prizes = [Prize("Gottfried Wilhelm Leibniz Prize", "2013-01-01")])
]

function setinfoforhindex!(researcher::Researcher)
    println("Setting info for h-index for $(researcher.lastname)")
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

setinfoforhindex!.(researchers)
serialize("researchers.jls", researchers)
