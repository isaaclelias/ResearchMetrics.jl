# What to do
# Search for Author Profile
# Get all papers that he published
# Get all papers that cite paper in papers that he published
# Exlude self citations
# Calculate h-index by time
#-------------------------------------------------------------------------------

"""
Provides functions to bulk query scientific database for authors and analyse their h-indexes.
"""
module HIndex

using HTTP
using JSON
using TimeSeries

export Author, Abstract
export setScopusData!, getAuthorsFromCSV, getCitations, popSelfCitations!

print("Enter the Scopus API key: ")
scopus_api_key = readline()

"""
Stores informations about the author based on a database query.

Fields meaning
- `query_name`: name used for querying the database
- `query_affiliation`: institution used for querying the database 
- `DATABASE_id`: id of the chosen researcher from query results
"""
mutable struct Author
    # Query data
    query_name::Union{String, Nothing}
    query_affiliation::Union{String, Nothing}

    # Scopus
    scopus_id::Union{String, Nothing}
    scopus_firstname::Union{String, Nothing}
    scopus_lastname::Union{String, Nothing}
    scopus_affiliation_name::Union{String, Nothing}
    scopus_affiliation_id::Union{String, Nothing}
    scopus_query_nresults::Union{String, Nothing}

    # ORCID
    orcid_id

    # Enforce that `Author` has at least these two fields filled up
    function Author(query_name::String, query_affiliation::String)
        author = new(ntuple(x->nothing, fieldcount(Author))...)
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
               "X-ELS-APIKey" => String(scopus_api_key)
              ]
    params = ["query" => "AUTHLASTNAME($(author.query_name)) and AFFIL($(author.query_affiliation))"]
    @info "Querying Scopus for" author.query_name author.query_affiliation
    response = HTTP.get(endpoint, headers; query=params).body |> String |> JSON.parse
    # Parsing the data

    author.scopus_firstname         = response["search-results"]["entry"][1]["preferred-name"]["given-name"]
    author.scopus_lastname          = response["search-results"]["entry"][1]["preferred-name"]["surname"]
    author.scopus_id                = response["search-results"]["entry"][1]["eid"]
    author.scopus_affiliation_id    = response["search-results"]["entry"][1]["affiliation-current"]["affiliation-id"]
    author.scopus_affiliation_name  = response["search-results"]["entry"][1]["affiliation-current"]["affiliation-name"]
    author.orcid_id                 = response["search-results"]["entry"][1]["orcid"]
    author.scopus_query_nresults    = response["search-results"]["opensearch:totalResults"]
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
