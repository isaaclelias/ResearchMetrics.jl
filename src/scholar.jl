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
    response_parse = JSON.parse(querySerapiGScholar(query_string, only_local))
    print(response_parse)
    abstract.title = response_parse["organic_results"][1]["title"]
    #abstract.scholar_citesid = response["organic_results"][1]["inline_links"]["cited_by"]["cites_id"]
    return nothing
end

function remoteQuerySerapiGScholarCite(query_string::String)::String
    
end

"""
    querySerpapiGScholarCite(::Abstract)

TASKS:
- Local query
"""
function querySerapiGScholarCite(abstract::Abstract, start::Int=0; only_local::Bool=false)::Union{Vector{Abstract}, Nothing}
    @debug ""

    # Tries to set a citesid for the given abstract
    query_string = abstract.scholar_citesid
    if isnothing(query_string)
        @info "No Scholar Cites ID set. Querying for it." abstract.title
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
            @info "Citedid set succesfully?" query_string abstract.scholar_citesid
        else
            @info "Couldn't set citedid" abstract.title abstract.scholar_citesid response_parse["organic_results"][1]["inline_links"]
            addQueryKnownToFault(serapi_fprefix, abstract.title) #it's added here because faulting is actually having a response without citesid instead of not responding
            return nothing
        end
    end
    query_string = abstract.scholar_citesid
    endpoint = "https://serpapi.com/search?engine=google_scholar"
    start = 0
    citations = Vector{Abstract}()
    while true
        local_query = localQuery(serpapiGScholarCite_fprefix, query_string*"$start")
        params = ["api_key" => serapi_api_key,
                  "engine" => "google_scholar",
                  "cites" => query_string,
                  "start" => "$start"]
        @info "Querying Google Scholar for citations" abstract.title
        if isnothing(local_query) && !only_local
            response = HTTP.get(endpoint; query=params).body |> String
        else
            response = local_query
        end
        if isnothing(response)
            @error "Couldn't find citations" abstract.title
            return nothing
        end
        response_parse = JSON.parse(response)
        saveQuery(serpapiGScholarCite_fprefix, query_string*"$start", response)
        for item in response_parse["organic_results"]
            citation = Abstract(item["title"])
            setBasicInfo!(citation, only_local=only_local)
            push!(citations, citation)
        end
        n_response = length(response_parse["organic_results"])
        n_response_total = response_parse["search_information"]["total_results"]
        start = start+n_response
        if start >= n_response_total
            break
        end
    end
    @debug citations
    return citations
end

function popNotInScopus!(abstracts::Vector{Abstract})::Nothing

end

