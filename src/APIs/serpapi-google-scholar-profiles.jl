fprefix_serpapi_google_scholar_profile = "Serapi-GoogleScholarProfiles"

function request_serpapi_google_scholar_profiles_api(query_string::String)
    # Preparing API
    endpoint = "https://serpapi.com/search?engine=google_scholar_profiles"
    params = ["api_key" => serapi_api_key,
              "engine" => "google_scholar_profiles",
              "q" => query_string]
    response = HTTP.get(endpoint; query=params).body |> String

    _savequery(fprefix_serpapi_google_scholar_profile, query_string, response)

    @debug "request_serpapi_google_scholar_profiles_api" query_string
    return response
end

function query_serpapi_google_scholar_profiles(query_string::AbstractString)
    response = _localquery(fprefix_serpapi_google_scholar_profile, query_string)
    if isnothing(response)
        response = request_serpapi_google_scholar_profiles_api(query_string)
    end

    @debug "query_serpapi_google_scholar_profiles_api" query_string
end

function set_serpapi_google_scholar_profiles(r::Researcher)
    
    response = query_serpapi_google_scholar_profiles(
        r.firstname*" "*r.lastname*" "*r.affiliation
    )

    reponse_parse = JSON.parse(response)

    r.gscholar_name         = response_parse["profiles"][1]["name"]
    r.gscholar_affiliations = response_parse["profiles"][1]["affiliations"]
    r.gscholar_author_id    = response_parse["profiles"][1]["author_id"]

    @debug "set_serpapi_google_scholar_profiles_api" r.gscholar_name r.gscholar_affiliations r.gscholar_author_id
end
