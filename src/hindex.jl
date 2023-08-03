# What to do
# Search for Author Profile
# Get all papers that he published
# Get all papers that cite paper in papers that he published
# Exlude self citations
# Calculate h-index by time
#-------------------------------------------------------------------------------

"""
Provides functions to bulk query scientific database for authors and analyse their h-indexes.

Issues:
- Scopus API only allows 2 requests/second. This will take forever.

Tasks:
- Get data from output/extern before querying scopus
- Refactor querying scopus to a separate function
"""
module HIndex

using HTTP
using JSON
using TimeSeries
using Dates
using SHA
using Dates

export Author, Abstract
export setScopusData!, getScopusAuthoredAbstracts, getAuthorsFromCSV, getCitations, popSelfCitations!, getScopusCitingAbstracts

print("Enter the Scopus API key: "); scopus_api_key = String(readline())
sha_length = 20
api_query_folder = "output/extern/"

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
    scopus_authid::Union{Int, Nothing}
    scopus_firstname::Union{String, Nothing}
    scopus_lastname::Union{String, Nothing}
    scopus_affiliation_name::Union{String, Nothing}
    scopus_affiliation_id::Union{String, Nothing}
    scopus_query_nresults::Union{String, Nothing}
    scopus_query_string::Union{String, Nothing}

    # ORCID
    orcid_id::Union{String, Nothing}

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
mutable struct Abstract
    title::Union{String, Nothing}
    date_pub::Union{Date, Nothing}
    doi::Union{String, Nothing}

    # Scopus
    scopus_scopusid::Union{Int, Nothing}
    scopus_eid::Union{String, Nothing}
    scopus_authids::Union{Vector{Int}, Nothing}
    is_in_scopus::Union{Bool, Nothing}
    
    # Empty constructor sets all fields to nothing
    function Abstract()
        author = new(ntuple(x->nothing, fieldcount(Abstract))...)
        return author
    end
end

"""
Tasks:
- Trim the authid (maybe with regex)
"""
function setScopusData!(author::Author)
    # Preparing API 
    endpoint = "https://api.elsevier.com/content/search/author"
    headers = [
               "Accept" => "application/json",
               "X-ELS-APIKey" => String(scopus_api_key)
              ]
    query_string = "AUTHLASTNAME($(author.query_name)) and AFFIL($(author.query_affiliation))"
    params = ["query" => query_string]
    @info "Querying Scopus for" author.query_name author.query_affiliation
    @time response = HTTP.get(endpoint, headers; query=params).body |> String
    response_parse = JSON.parse(response)

    # Setting the Author values
    author.scopus_firstname         = response_parse["search-results"]["entry"][1]["preferred-name"]["given-name"]
    author.scopus_lastname          = response_parse["search-results"]["entry"][1]["preferred-name"]["surname"]
    author.scopus_affiliation_id    = response_parse["search-results"]["entry"][1]["affiliation-current"]["affiliation-id"]
    author.scopus_affiliation_name  = response_parse["search-results"]["entry"][1]["affiliation-current"]["affiliation-name"]
    author.orcid_id                 = response_parse["search-results"]["entry"][1]["orcid"]
    author.scopus_query_nresults    = response_parse["search-results"]["opensearch:totalResults"]
    author.scopus_query_string      = query_string
    ## Triming the authors url to get the id
    scopus_authid                   = response_parse["search-results"]["entry"][1]["prism:url"]
    scopus_authid                   = replace(scopus_authid, r"https://api.elsevier.com/content/author/author_id/"=>"")
    author.scopus_authid            = parse(Int, scopus_authid)

    # Saving the response to a file
    query_sha = first(bytes2hex(sha256(query_string)), sha_length)
    fname = "Scopus-AuthorSearch"*"_"*Dates.format(now(), "yyyy-mm-dd_HH-MM")*"_"*query_sha*".json"
    dirpath = api_query_folder
    fpath = dirpath*fname
    touch(fpath)
    open(fpath, "w") do file
        write(file, response)
    end

    # Logging
    @info "Received data from Scopus:" author.scopus_lastname author.scopus_firstname author.scopus_authid author.scopus_affiliation_name author.scopus_affiliation_id
end

"""
    setScopusData!(::Abstract)

Uses the Scopus Abstract Retrieval API to get data.
"""
function setScopusData!(abstract::Abstract)
    # Checking if we have the needed information for the query
    if something(abstract.scopus_scopusid)
        query_string = string(abstract.scopus_scopusid)
    else
        @error "Missing needed information for query"
    end

    # Preparing API 
    endpoint = "https://api.elsevier.com/content/abstract/scopus_id/"
    headers = [
               "Accept" => "application/json",
               "X-ELS-APIKey" => scopus_api_key
              ]
    @info "Querying Scopus Abstract Retrieval API" abstract.scopus_scopusid 
    response = HTTP.get(endpoint*query_string, headers).body |> String
    response_parse = JSON.parse(response)
    response_parse = response_parse["abstracts-retrieval-response"]

    # Saving the response to a file
    query_sha = first(bytes2hex(sha256(query_string)), sha_length)
    fname = "Scopus-AbstractRetrieval"*"_"*Dates.format(now(), "yyyy-mm-dd_HH-MM")*"_"*query_sha*".json"
    dirpath = api_query_folder
    fpath = dirpath*fname
    touch(fpath)
    open(fpath, "w") do file
        write(file, response)
    end
    @info "Abstract Retrieval response written to "*fpath

    # Setting the fields
    abstract.title = response_parse["coredata"]["dc:title"]
    abstract.date = Date(response_parse["coredata"]["prism:coverDate"])
    ## Authors
    n_authors = length(response_parse["authors"]["author"])
    abstract.scopus_authids = Vector{Int}(undef, n_authors)
    for (i, author) in enumerate(response_parse["authors"]["author"])
        abstract.scopus_authids[i] = parse(Int, author["@auid"])
    end
end

"""
- write!

Tasks:
- Iterate over the list of received objects and populate the Vector{Abstract}
- Do a double check wheater the received abstracts indeed are authored by the given author
"""
function getScopusAuthoredAbstracts(author::Author)::Vector{Abstract}
    # Preparing API 
    endpoint = "https://api.elsevier.com/content/search/scopus"
    headers = [
               "Accept" => "application/json",
               "X-ELS-APIKey" => scopus_api_key
              ]
    query_string = "AU-ID($(author.scopus_authid))"
    params = ["query" => query_string]
    @info "Querying Scopus for abstracts by" author
    response = HTTP.get(endpoint, headers; query=params).body |> String
    response_parse = JSON.parse(response)
    
    # Setting the values
    n_abstracts = parse(Int, response_parse["search-results"]["opensearch:totalResults"])
    @info n_abstracts
    authored_abstracts = Vector{Abstract}(undef, n_abstracts)
    # debugging
    for (i, abstract) in enumerate(response_parse["search-results"]["entry"])
        # Setting the fields
        authored_abstracts[i]                   = Abstract() # initializing the struct
        authored_abstracts[i].title
        ## Triming the abstract url to get the id
        scopus_scopusid                         = abstract["prism:url"]
        scopus_scopusid                         = replace(scopus_scopusid, r"https://api.elsevier.com/content/abstract/scopus_id/"=>"")
        authored_abstracts[i].scopus_scopusid   = parse(Int, scopus_scopusid)
        ## Setting the DOI if it's present
        authored_abstracts[i].doi               = get(abstract, "prism:doi", nothing)
    end
    
    # Saving the response to a file
    query_sha = first(bytes2hex(sha256(query_string)), sha_length)
    fname = "Scopus-ScopusSearch"*"_"*Dates.format(now(), "yyyy-mm-dd_HH-MM")*"_"*query_sha*".json"
    dirpath = api_query_folder
    fpath = dirpath*fname
    touch(fpath)
    open(fpath, "w") do file
        write(file, response)
    end
    @info "ScopusSearch API response written to "*fpath

    return authored_abstracts
end

"""
    getScopusCitingAbstracts(::Abstract)::Vector{Abstract}

Queries scopus for a list of abstracts that cite the given abstract
"""
function getScopusCitingAbstracts(abstract::Abstract)#::Vector{Abstract}
    @warn "getScopusCitingAbstracts not implemented"
    # Preparing API 
    endpoint = "https://api.elsevier.com/content/search/scopus"
    headers = [
               "Accept" => "application/json",
               "X-ELS-APIKey" => scopus_api_key
              ]
    #query_string = "REFEID($(abstract.scopus_scopusid))" # APIKey doesn't have privileges
    query_string = "REFEID($(abstract.scopus_scopusid))"
    params = ["query" => query_string]
    @info "Querying Scopus Search for arcticles that cite" abstract.title
    response = HTTP.get(endpoint, headers; query=params).body |> String
    response_parse = JSON.parse(response)
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
