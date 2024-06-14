"""
Provides functions to bulk query scientific database for authors and analyse their h-indexes.

Issues:
- Scopus API only allows 2 requests/second. This will take forever.

Tasks:
- Get data from output/extern before querying scopus
- Write LOTS of documentation
"""
module ResearchMetrics

using HTTP
using JSON
using TimeSeries
using Dates
using SHA
using ProgressBars
using Debugger
using CurveFit
using Plots

export setScopusData!, getScopusAuthoredAbstracts, getAuthorsFromCSV, getCitations, popSelfCitations!, getScopusCitingAbstracts, queryID
export Publication
export setBasicInfo!, setCitations!, setCitationsBasicInfo!
export Researcher
export publications, prizes, citationcount, citations, citationdates, hindexat, mapcitations, mappublications
export setScopusAbstractRetrieval!
export setScopusAuthorSearch!
export setScopusSearch!
export setScopusApiKey, setScopusSearchData!, getCitationDates

include("logging.jl")
include("secrets.jl")
include("Publication.jl")

include("Prize.jl")
export Prize, dateof, nameof

include("Researcher.jl")
include("local.jl")
include("scopus.jl")
include("serpapi.jl")
export setSerpapiGScholarSearch!

include("hindex.jl")
export hindex, setinfoforhindex!, plothindexevolution

end #module
