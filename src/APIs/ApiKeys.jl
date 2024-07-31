scopus_api_key::String = ""
serapi_api_key::String = ""

function setSerpApiKey(key::AbstractString)
    global serapi_api_key = key
end

function setScopusKey(key::AbstractString)
    global scopus_api_key = key
end

function prompt_to_set_scopus_key()
    if length(scopus_api_key) !== 0
        @info "Scopus API key is already set." scopus_api_key
        return nothing
    end

    @info "Scopus API key is not set. Please insert the key below."
    print("Scopus API key: ")
    setSerpApiKey(readline())

    return nothing
end
