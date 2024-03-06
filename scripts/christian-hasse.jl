# include modules
include("../src/ResearchMetrics.jl")
using .ResearchMetrics
using Dates
using Logging, LoggingExtras

# setup logging
io_path = "logs/christian-hasse_"*Dates.format(now(), "yyyy-mm-dd_HH-MM")*".log"
touch(io_path)
io = open(io_path, "w+")
logger = TeeLogger(ConsoleLogger(stdout, Logging.Debug),
                   SimpleLogger(io, Logging.Debug))
global_logger(logger)

# gather information for the h-index plot
function setinfoforhindex!(researcher::Researcher)
           setScopusAuthorSearch!(researcher, only_local=true)
           setScopusSearch!(researcher, progress_bar=true, only_local=true)
           mappublications(x -> setScopusAbstractRetrieval!(x, only_local=true), researcher, progress_bar=true)
           mappublications(x -> setSerpapiGScholarCite!(x, only_local=true), researcher, progress_bar=true)
           mapcitations(x -> setScopusAbstractRetrieval!(x, only_local=true), researcher, progress_bar=true)
end

# the researcher
hasse = Researcher("Christian Hasse", "Technische Universität Darmstadt")
setinfoforhindex!(hasse)
