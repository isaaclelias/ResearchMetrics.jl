export setSerapiApiKey, setScholarBasicFields

serapi_api_key::String

function setSerapiApiKey(api_key::String)::Nothing
    serapi_api_key = api_key
end

"""
    setScholarBasicFields!(::Abstract)::Nothing

Basic fields:
- scholar_citesid
"""
function setScholarBasicFields!(abstract::Abstract)::Nothing
    # Preparing API
    endpoint = "https://serpapi.com/search?engine=google_scholar"
    params = ["api_key" => serapi_api_key,
              "engine" => "google_scholar",
              "q" => String(abstract.doi)]
    @info "Querying Google Scholar" abstract.doi
    @time response = HTTP.get(endpoint; query=params).body |> String
    response_parse = JSON.parse(response)
    @info response.request
    
    if !isnothing(abstract.doi)
        push!(params, "q" => abstract.doi)
    else
        @error "Not enough information to set abstracts Scholar's basic fields"
    end

    abstract.scholar_citesid = parse(Int, response_parse["organic_results"]["inline_links"]["cited_by"]["cites_id"])
end

function queryScholarCitations(abstract::Abstract)::Vector{Abstract}
     # Preparing API
    endpoint = "https://serpapi.com/search?engine=google_scholar"
    params = ["api_key" => serapi_api_key,
              "engine" => "google_scholar",
              "cites" => String(abstract.scholar_citesid)]
    @info "Querying Google Scholar for citations" 
    @time response = HTTP.get(endpoint; query=params).body |> String
    response_parse = JSON.parse(response)

    saveQuery("GoogleScolar", )
 
    citations = Vector{Abstract}()
    for item in response_parse["organic_results"]
        citation = Abstract()
        citation.title = item["title"]
        push!(citations, citation)
    end
end

function popNotInScopus!(abstracts::Vector{Abstract})::Nothing

end

function setCitations!(abstract::Abstract)::Nothing

end
