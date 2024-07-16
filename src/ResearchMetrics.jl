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
using DataFrames

include("logging.jl")

include("APIs/ApiKeys.jl")
export setScopusKey, setSerpApiKey

include("data-structures/Publication.jl")
export Publication, title

include("data-structures/Prize.jl")
export Prize, dateof, nameof

include("data-structures/Researcher.jl")
export Researcher
export publications, prizes, citationcount, citations, citationdates, hindexat, mapcitations, mappublications
export dataframe_publications, dataframe_citations

include("local.jl")
export setworkingdir

include("APIs/scopus.jl")
export set_scopus_abstract_retrieval!, set_scopus_search!, set_scopus_author_search!
export setScopusData!, getScopusAuthoredAbstracts, getAuthorsFromCSV, getCitations, popSelfCitations!, getScopusCitingAbstracts, queryID

# TODO refactor the names to the commom standard
include("APIs/serpapi.jl")
export setSerpapiGScholarSearch!
export setScopusSearch!
export setScopusAuthorSearch!
export setScopusSearchData!, getCitationDates
export setBasicInfo!, setCitations!, setCitationsBasicInfo!
export setSerpapiGScholarCite!

include("APIs/serpapi-scholar-cite.jl")
export set_serpapi_google_scholar_cite!

include("APIs/serpapi-google-scholar-profiles.jl")
export set_serpapi_google_scholar_profiles!

include("APIs/serpapi-google-scholar-author.jl")
export set_serpapi_google_scholar_author!

include("hindex.jl")
export hindex, setinfoforhindex!, plothindexevolution

include("workflows/hindex_scopus_serpapi.jl")
export set_needed_for_hindex_with_scopus_serpapi!

# misc
export arein

end #module
