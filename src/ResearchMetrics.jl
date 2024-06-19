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

include("logging.jl")

include("ApiKeys.jl")
export setScopusKey, setSerpApiKey

include("Publication.jl")
export Publication

include("Prize.jl")
export Prize, dateof, nameof

include("Researcher.jl")
export Researcher
export publications, prizes, citationcount, citations, citationdates, hindexat, mapcitations, mappublications

include("local.jl")

include("scopus.jl")
export setScopusAbstractRetrieval!
export setScopusData!, getScopusAuthoredAbstracts, getAuthorsFromCSV, getCitations, popSelfCitations!, getScopusCitingAbstracts, queryID

include("serpapi.jl")
export setSerpapiGScholarSearch!
export setScopusSearch!
export setScopusAuthorSearch!
export setScopusSearchData!, getCitationDates
export setBasicInfo!, setCitations!, setCitationsBasicInfo!

include("hindex.jl")
export hindex, setinfoforhindex!, plothindexevolution

# misc
export arein

end #module
