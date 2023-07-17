# What to do
# Search for Author Profile
# Get all papers that he published
# Get all papers that cite paper in papers that he published
# Exlude self citations
# Calculate h-index by time

include("../secrets.jl")

"""
Provides functions to bulk query scientific database for authors and analyse their h-indexes.
"""
module HIndex

using HTTP
using TimeSeries

export Author, Abstract
export getAuthorsFromCSV, getCitations, popSelfCitations

# Preparing API 
api_url = "https://api.elsevier.com/content/search/scopus"
params = Dict(
              "exemplo" => "exemplo"
             )
@warn "params not set"
params_encode = HTTP.URLEncodeçparamsencode(params)
url = api_url * "?" * params_encode
request = HTTP.Request("GET", url)
HTTP.addheader!(request, "Accept",        "application/json")
HTTP.addheader!(request, "Authorization", "Bearer XXXXXXXXX")
HTTP.addheader!(request, "",              "")
@warn "OAuth bearer access token not set"

"""
Stores informations about the author based on a database query.
"""
struct Author
  
end
@warn "Author not implemented"

"""
Stores informations about the author based on a database query.
"""
struct Abstract

end
@warn "Abstract not implemented"

"""
    getAuthorsFromCSV()

Querys the database to obtain a list of scientist ids.
"""
function getAuthorsFromCSV(file::String)::Vector{Author}
    @warn "getAuthorsFromCSV() not implemented"
end

"""
    getCitations()

Querys the database for all abstracts from papers which cite the given abstract.
"""
function getCitations(abstract::Abstract)::Vector{Abstract}
  @warn "getCitations() not implemented"
end

"""
    popSelfCitations()

Pops all papers authored by `author` from the `abstracts`.
"""
function popSelfCitations!(abstracts::Vector{Abstract}, author::Author)
    @warn "popSelfCitations() not implemented" 
end

"""
    nameToBeDecided()

Returns a timeseries 
"""
function calcHIndexTimeseries(arguments)::TimeArray
  
end
