fprefix_serpapi_google_scholar_author = "Serapi-GoogleScholarAuthorArticles"

function request_serpapi_google_scholar_author_api(gscholar_author_id::String)
    # Preparing API
    endpoint = "https://serpapi.com/search?engine=google_scholar_author"
    params = ["api_key" => serapi_api_key,
              "engine" => "google_scholar_author",
              "author_id" => gscholar_author_id]
    response = HTTP.get(endpoint; query=params).body |> String

    _savequery(fprefix_serpapi_google_scholar_author, gscholar_author_id, response)

    @debug "request_serpapi_google_scholar_author_api" gscholar_author_id 
    return response
end

function query_serpapi_google_scholar_profiles_api(gscholar_author_id::AbstractString)
    response = _localquery(fprefix_serpapi_google_scholar_author, gscholar_author_id)
    if isnothing(response)
        response = request_serpapi_google_scholar_author_api(gscholar_author_id)
    end

    @debug "query_serpapi_google_scholar_author_api" gscholar_author_id
end

function set_serpapi_google_scholar_author_api(r::Researcher)
    r.success_set_serpapi_google_scholar_author = false

    response = query_serpapi_google_scholar_profiles_api(
        r.firstname*" "*r.lastname*" "*r.affiliation
    )

    reponse_parse = JSON.parse(response)

    r.gscholar_name         = response_parse["profiles"][1]["name"]
    r.gscholar_affiliations = response_parse["profiles"][1]["affiliations"]
    r.gscholar_author_id    = response_parse["profiles"][1]["author_id"]

    r.success_set_serpapi_google_scholar_author = true
    @debug "set_serpapi_google_scholar_profiles_api" r.gscholar_name r.gscholar_affiliations r.gscholar_author_id
end
