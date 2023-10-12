export setSerapiApiKey, setScholarBasicFields!, querySerapiGScholarCite, querySerapiGScholar

serapi_fprefix = "Serapi-GoogleScholar"
serpapiGScholarCite_fprefix = "Serpapi-GScholarCite"

@debug serapi_api_key

function setSerapiApiKey(api_key::String)::Nothing
    serapi_api_key = api_key

    return nothing
end

include("serpapi-scholar.jl")
include("serpapi-scholar-cite.jl")
