scopus_api_key::String = ""
serapi_api_key::String = ""

function setSerpApiKey(key::AbstractString)
    global serapi_api_key = key
end

function setScopusKey(key::AbstractString)
    global scopus_api_key = key
end

function prompt_to_set_scopus_key()
    _parsed_secrets = TOML.parsefile("Secrets.toml")
    setSerpApiKey(_parsed_secrets["serpapi"])

    if length(serapi_api_key) !== 0
        @debug "SerpApi API key is already set."
        return nothing
    end

    @info "SerpApi API key is not set. Please insert the key below."
    print("SerpApi API key: ")
    setSerpApiKey(readline())

    return nothing
end
