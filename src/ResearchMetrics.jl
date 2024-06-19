"""
Provides functions to bulk query scientific databases for authors and publications information and analyse their h-indexes.
"""
module ResearchMetrics

using HTTP
using JSON
using TimeSeries
using Dates
using SHA
using ProgressBars
using CurveFit

export setScopusData!, getScopusAuthoredAbstracts, getAuthorsFromCSV, getCitations, popSelfCitations!, getScopusCitingAbstracts, queryID
export setBasicInfo!, setCitations!, setCitationsBasicInfo!
export Researcher
export publications, prizes, citationcount, citations, citationdates, hindexat, mapcitations, mappublications
export setScopusAbstractRetrieval!
export setScopusAuthorSearch!
export setScopusSearch!
export setScopusApiKey, setScopusSearchData!, getCitationDates

include("logging.jl")

include("ApiKeys.jl")
export setScopusKey, setSerpApiKey

include("Publication.jl")
export Publication

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
