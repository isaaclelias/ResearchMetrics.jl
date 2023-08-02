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

export Author, Abstract
export setScopusData!, getAuthoredAbstracts, getAuthorsFromCSV, getCitations, popSelfCitations!

print("Enter the Scopus API key: "); scopus_api_key = readline()
sha_length = 20
api_query_folder = "output/extern"

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
mutable struct Abstract
    doi::Union{String, Nothing}

    # Scopus
    scopus_scopusid::Union{String, Nothing}
    scopus_authids::Union{Vector{String}, Nothing}
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
     # Preparing API 
    endpoint = "https://api.elsevier.com/content/abstract/scopus_id/"
    query_string = abstract.scopus
    @info "Querying Scopus for abstracts by" author
    response = HTTP.get(endpoint, headers; query=params).body |> String
    response_parse = JSON.parse(response) 


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
               "X-ELS-APIKey" => String(scopus_api_key)
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
        @show i
        authored_abstracts[i] = Abstract() # initializing the struct
        authored_abstracts[i].doi = abstract["prism:doi"]
        #=
        n_authors = length(abstract["author"]) # number of authors the abstract has
        authored_abstracts[i].scopus_authid = Vector{Int}(undef, n_authors) # initializing the Vector
        for (j, abstract_author) in enumerate(abstract["author"])
            # double check for authorship could go here
            authored_abstracts[i].scopus_authid[j] = parse(Int, abstract_author["authid"])
        end
        =#
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

    return authored_abstracts
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
