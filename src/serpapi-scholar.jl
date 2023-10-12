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

