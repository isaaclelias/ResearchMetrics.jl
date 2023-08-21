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
- Write LOTS of documentation
"""
module HIndex

using HTTP
using JSON
using TimeSeries
using Dates
using SHA
using Dates

include("author.jl")
include("abstract.jl")
include("scopus.jl")
include("scholar.jl")

export Author, Abstract
export setScopusData!, getScopusAuthoredAbstracts, getAuthorsFromCSV, getCitations, popSelfCitations!, getScopusCitingAbstracts

sha_length = 20
api_query_folder = "resources/extern/"

function queryID(query_string::String)::String
    query_sha = first(bytes2hex(sha256(query_string)), sha_length)
end

"""
    localQuery(::String)::String

CURRENTLY WORKING ON
NOT TESTED
"""
function localQuery(query_type::String, query_string::String)::Union{String, Nothing}
    regex = Regex(query_type*"-.*-"*queryID(query_string))
    what_we_have = readdir(api_query_folder)
    what_we_have = filter(s-> occursin(regex, s), what_we_have)
    @debug "Files found matching the query" length(what_we_have)
    if !isempty(what_we_have)
        @debug "Using info from the disk"
        sort!(what_we_have)
        open(api_query_folder*what_we_have[1], "r") do file
            print(read(file, String))
            response_parse = JSON.parse(read(file, String))
        end
    else
        return nothing
    end 
end

"""
    saveQuery(query_type::String, query_string::String)::Nothing

Saves the result to disk.
"""
function saveQuery(query_type::String, query_string::String, response::String)::Nothing
    fname = query_type*"_"*Dates.format(now(), "yyyy-mm-dd_HH-MM")*"_"*queryID(query_string)*".json"
    fpath = api_query_folder*fname
    touch(fpath)
    open(fpath, "w") do file
        write(file, response)
    end
end

"""
    popSelfCitations!()

NOT TESTED
Pops all papers authored by `author` from the `abstracts`.

Tasks:
- TEST IT
"""
function popSelfCitations!(abstracts::Vector{Abstract}, author::Author)
    for abstract in abstracts
        if author.scopus_authid in abstract.scopus_authids
            pop!(abstracts, abstract)
        end
    end
end

"""
    calcHIndex(::Vector{Int})::Int

NOT TESTED
Calculates the h-index.

Implementation details:
- GPT generated
"""
function calcHIndex(citation_count::Vector{Int})::Int
    n = length(citation_count)
    sorted_citations = sort(citation_count, rev=true)

    h_index = 0
    for i in 1:n
        if sorted_citations[i] >= i
            h_index = i
        else
            break
        end
    end

    return h_index
end

end #module
