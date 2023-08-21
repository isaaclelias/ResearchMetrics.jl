export setSerapiApiKey, setScholarBasicFields!

print("Serapi API Key: "); serapi_api_key = readline()
serapi_fprefix = "Serapi-GoogleScholar"

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
    @info "Querying Google Scholar" abstract.doi
    @time response = HTTP.get(endpoint; query=params)
    response_parse = response.body |> String
    response_parse = JSON.parse(response_parse)

    saveQuery(serapi_fprefix, query_string, String(response.body))
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
function querySerapiGScholar(abstract::Abstract)#::String
    # Do we have the data?
    if !isnothing(abstract.doi)
        query_string = abstract.doi
    else
        @error "Not enough information to Scholar's basic fields"
    end

    local_query = localQuery(serapi_fprefix, query_string)
    if !isnothing(local_query)
        return local_query
    else
        return remoteQuerySerapiGScholar(query_string)
    end
end

"""
    setScholarBasicFields!(::Abstract)::Nothing

Basic fields:
- scholar_citesid
"""
function setBasicFieldsFromSerapiGScholar!(abstract::Abstract)::Nothing
    @debug "Setting Scholar basic fields for" query_sha

    response = JSON.parse(querySerapiGScholar(abstract))
    abstract.scholar_citesid = parse(Int, response["organic_results"]["inline_links"]["cited_by"]["cites_id"])
end

#=
function querySerapiCite(abstract::Abstract)::Vector{Abstract}
    # Querying from Serapi
    endpoint = "https://serpapi.com/search?engine=google_scholar"
    params = ["api_key" => String(serapi_api_key),
              "engine" => "google_scholar",
              "cites" => String(abstract.scholar_citesid)]
    @info "Querying Google Scholar for citations" 
    @time response = HTTP.get(endpoint; query=params).body |> String
    response_parse = JSON.parse(response)

    #saveQuery("GoogleScolar", )
 
    citations = Vector{Abstract}()
    for item in response_parse["organic_results"]
        citation = Abstract()
        citation.title = item["title"]
        push!(citations, citation)
    end

    return citations
end
=#

function popNotInScopus!(abstracts::Vector{Abstract})::Nothing

end

