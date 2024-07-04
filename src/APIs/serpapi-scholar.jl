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
function set_serpapi_google_scholar_search!(publication::Publication; only_local::Bool=false)::Nothing
    publication.success_set_serpapi_google_scholar_search = false
    
    @debug "`set_serpapi_google_scholar_search!`"
    query_string = publication.title # TODO refactor to title(p)

    response = querySerapiGScholar(query_string, only_local=only_local) # TODO refactor
    if isnothing(response)
        @warn "`set_serpapi_google_scholar_search!` Couldn't set SerpApi Google Scholar Search" title(publication)
        return nothing
    end

    # Tries to set a Cites ID, otherwise assigns missing to indicate that it was already tried
    try
        response_parse = JSON.parse(response)
        publication.scholar_citesid = response_parse["organic_results"][1]["inline_links"]["cited_by"]["cites_id"]
        publication.success_set_serpapi_google_scholar_search = true
        @debug "`set_serpapi_google_scholar_search!` successful" publication.title publication.scholar_citesid
        return nothing
    catch y
        @debug "`set_serpapi_google_scholar_search!` coudln't find a Google Scholar Cite ID." publication.title y
        return nothing
    end

    error("I shoudn't exit here. File an issue please.")
end
# TODO resolve @deprecate for set_serpapi_google_scholar_search!
