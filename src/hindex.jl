# What to do
# Search for Author Profile
# Get all papers that he published
# Get all papers that cite paper in papers that he published
# Exlude self citations
# Calculate h-index by time
#-------------------------------------------------------------------------------

include("../secrets.jl")

"""
Provides functions to bulk query scientific database for authors and analyse their h-indexes.
"""
module HIndex

using HTTP
using TimeSeries

export Author, Abstract
export getAuthor, getAuthorsFromCSV, getCitations, popSelfCitations!

print("Enter the Scopus API key: ")
scopus_api_key = readline()

"""
Stores informations about the author based on a database query.

Fields meaning
- `query_name`: name used for querying the database 
- `query_affiliation`: institution used for querying the database 
- `DATABASE_id`: id of the chosen researcher from query results
"""
struct Author
    # Query data
    query_name::String
    query_affiliation::String

    # Scopus
    scopus_id::Union{Int, Nothing}
    scopus_preferred_name::Union{String, Nothing}
    scopus_affiliation::Union{String, Nothing}
    scopus_returned_ids::Union{Vector{Int}, Nothing}

    # ORCID
    orcid_id

    # Enforce that `Author` has at least these two fields filled up
    function Author(query_name::String, query_affiliation::String)
        author = new()
        author.query_name = query_name
        author.query_affiliation = query_affiliation
        return author
    end
end

"""
Store information about abstracts.
"""
struct Abstract

end
@warn "Abstract not implemented"

function setScopusData!(author::Author)
    # Preparing API 
    endpoint = "https://api.elsevier.com/content/search/author"
    headers = [
               "Accept" => "application/json",
               "X-ELS-APIKey" => scopus_api_key
              ]
    params = ["query" => query]
    request = HTTP.request(:GET, endpoint, headers, query=params)
    println(request.status)
    println(String(request.body))
    
    # Parsing the data
end

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
    popSelfCitations!()

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

end #module
