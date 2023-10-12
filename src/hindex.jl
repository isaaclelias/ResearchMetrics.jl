export Author, Abstract
export setScopusData!, getScopusAuthoredAbstracts, getAuthorsFromCSV, getCitations, popSelfCitations!, getScopusCitingAbstracts, setHIndex!, queryID

sha_length = 20
api_query_folder = "resources/extern/"

function _uniqueidentifierSHA(unique_identifier::String)::String
    query_sha = first(bytes2hex(sha256(unique_identifier)), sha_length)
end
@deprecate queryID(query_string::String) _uniqueidentifierSHA(query_string)

include("local.jl")

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
        @debug "Query saved to disk" fpath
    end

    return nothing
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

function _sethindex!(author::Author)::Nothing
    setScopusHIndex!(author)
    return nothing
end
@deprecate setHIndex!(author::Author) _sethindex(author)

end #module

#=
function setInfoForHIndexEvaluation(author::Author; only_local::Bool=false)::Nothing
    @warn "Not implemented"
    return nothing
end
=#
