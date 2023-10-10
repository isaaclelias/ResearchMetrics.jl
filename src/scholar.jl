include("secrets.jl")
include("local.jl")

export setSerapiApiKey, setScholarBasicFields!, querySerapiGScholarCite, querySerapiGScholar

serapi_fprefix = "Serapi-GoogleScholar"
serpapiGScholarCite_fprefix = "Serpapi-GScholarCite"

@debug serapi_api_key

function setSerapiApiKey(api_key::String)::Nothing
    serapi_api_key = api_key

    return nothing
end

function remoteQuerySerapiGScholar(query_string::String)#::String
    # Preparing API
    endpoint = "https://serpapi.com/search?engine=google_scholar"
    params = ["api_key" => serapi_api_key,
              "engine" => "google_scholar",
              "q" => query_string]
    response = HTTP.get(endpoint; query=params).body |> String
    response_parse = JSON.parse(response)

    saveQuery(serapi_fprefix, query_string, response)
    return response
end

"""
`query_string` should already be formated
"""
function localQuerySerapiGScholar(query_string::String)::Union{String, Nothing}
    localQuery(serapi_fprefix, query_string)
end

"""
Implementation details:
- `query_string` is formatted here
"""
function querySerapiGScholar(query_string::String; only_local::Bool=false)::Union{String, Nothing}
    local_query = localQuery(serapi_fprefix, query_string)
    if !isnothing(local_query)
        return local_query
    else
        if only_local || queryKnownToFault(serapi_fprefix, query_string)
            return nothing
        else
            sleep(3.6)
            return remoteQuerySerapiGScholar(query_string)
        end
    end
end

"""
    setScholarBasicFields!(::Abstract)::Nothing

Basic fields:
- scholar_citesid
"""
function setBasicFieldsFromSerapiGScholar!(abstract::Abstract; only_local::Bool=false)::Nothing
    query_string = abstract.title
    response_parse = JSON.parse(querySerapiGScholar(query_string, only_local=only_local))

    # Tries to set a Cites ID, otherwise assigns missing to indicate that it was already tried
    if (haskey(response_parse, "organic_results") &&
        haskey(response_parse["organic_results"][1]["inline_links"], "cited_by"))
        abstract.scholar_citesid = response_parse["organic_results"][1]["inline_links"]["cited_by"]["cites_id"]
    else
        abstract.scholar_citesid = missing
    end

    @debug "Result from setBasicFieldsFromSerapiGScholar" abstract.title abstract.scholar_citesid
    return nothing
end

"""
    querySerpapiGScholarCite(::Abstract)

TASKS:
- Local query
"""
function querySerapiGScholarCite(abstract::Abstract, start::Int=0; only_local::Bool=false)::Union{Vector{Abstract}, Nothing}
    # Dealing with lack of information
    ## Nothing
    if isnothing(abstract.scholar_citesid)
        setBasicFieldsFromSerapiGScholar!(abstract)
    end
    # Missing
    if ismissing(abstract.scholar_citesid)
        @error "Couldn't query GScholarCite because citesid is missing" abstract.title 
        return nothing
    end
#=
    # Tries to set a citesid for the given abstract
    query_string = abstract.scholar_citesid
    if isnothing(abstract.scholar_citesid)
        @debug "No Scholar Cites ID set. Querying for it." abstract.title
        response = querySerapiGScholar(abstract.title, only_local=only_local)
        if isnothing(response)
            @error "Query for citeid returned empty"
            return nothing
        end
        response_parse = JSON.parse(response)
        if !haskey(response_parse, "organic_results")
            @error "Scholar response whitout organic_results"
            return nothing
        end
        if haskey(response_parse["organic_results"][1]["inline_links"], "cited_by")
            abstract.scholar_citesid = response_parse["organic_results"][1]["inline_links"]["cited_by"]["cites_id"]
            query_string = abstract.scholar_citesid
            @debug "Citedid set succesfully?" abstract.title abstract.scholar_citesid
        else
            @error "Couldn't set citedid" abstract.title abstract.scholar_citesid response_parse["organic_results"][1]["inline_links"]
            addQueryKnownToFault(serapi_fprefix, abstract.title) #it's added here because faulting is actually having a response without citesid instead of not responding
            return nothing
        end
    end
=#

    query_string = abstract.scholar_citesid
    endpoint = "https://serpapi.com/search?engine=google_scholar"
    start = -1
    n_response = 1
    citations = Vector{Abstract}()
    while true
        start = start+n_response
        if start >= 240
            break
        end

        # API Request
        @debug "Querying Google Scholar for citations" abstract.title abstract.scholar_citesid start
        response = nothing
        ## Trying locally
        local_query = localQuery(serpapiGScholarCite_fprefix, query_string*"$start")
        if !isnothing(local_query)
            response = local_query
        end
        ## If not found locally, try remote
        if isnothing(response) && !only_local
            params = ["api_key" => serapi_api_key,
                      "engine" => "google_scholar",
                      "cites" => query_string,
                      "start" => "$start"]
            sleep(3.6)
            response = HTTP.get(endpoint; query=params).body |> String
            saveQuery(serpapiGScholarCite_fprefix, query_string*"$start", response)
        end
        # If not remote, give up
        if isnothing(response)
            @debug "No response"
            break
        end

        # Parsing and checking the response
        response_parse = JSON.parse(response)
        if (!haskey(response_parse, "organic_results") ||
            !haskey(response_parse["organic_results"][1]["inline_links"], "cited_by"))
            @warn "Received a response, but something wrong" abstract.title start queryID(query_string*"$start")
            break
        end

        # Apending the returned citations
        for item in response_parse["organic_results"]
            citation = Abstract(item["title"])
            push!(citations, citation)
        end

        # Preparing to query the next results page
        n_response = length(response_parse["organic_results"])
        n_response_total = response_parse["search_information"]["total_results"]
        ## If last page
        if start >= n_response_total || n_response == 0 || n_response_total <= 10 || start > 240
            break
        end
    end
    return citations
end

function popNotInScopus!(abstracts::Vector{Abstract})::Nothing

end

