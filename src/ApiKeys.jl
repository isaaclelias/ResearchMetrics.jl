scopus_api_key = nothing
serapi_api_key = nothing

function setSerpApiKey(key::AbstractString)
    global serapi_api_key = key
end

function setScopusKey(key::AbstractString)
    global scopus_api_key = key
end
