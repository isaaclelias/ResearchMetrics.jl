export setScopusAbstractRetrieval!

function requestScopusAbstractRetrieval(query_string::String; only_local::Bool=false, in_a_hurry::Bool=false)::Union{String, Nothing}
    response = ""
    local_query = localQuery(scopusAbstractRetrieval_fprefix, query_string)
    if !isnothing(local_query)
        return local_query
    elseif !only_local && !queryKnownToFault(scopusAbstractRetrieval_fprefix, query_string)
        # Preparing API
        @debug "Requesting Scopus Abstract Retrieval API" query_string
        endpoint = "https://api.elsevier.com/content/abstract/scopus_id/"
        headers = ["Accept" => "application/json",
                   "X-ELS-APIKey" => scopus_api_key]
        try
            if !in_a_hurry; sleep(0.5); end # Sleep for half a second to avoid receiving a TOO MANY REQUESTS
            response = HTTP.get(endpoint*query_string, headers).body |> String
        catch y
            if isa(y, HTTP.StatusError)
                @debug "HTTP StatusError on Scopus Abstract Retrieval" 
                addQueryKnownToFault(scopusAbstractRetrieval_fprefix, query_string)
                return nothing
            end
        end
        saveQuery(scopusAbstractRetrieval_fprefix, query_string, response)
        return response
    else
        return nothing
    end
end
@deprecate queryScopusAbstractRetrieval(query_string; only_local=false, in_a_hurry=false) requestScopusAbstractRetrieval(query_string)

"""
    setScopusData!(::Abstract; only_local::Bool)::Nothing

Uses the Scopus Abstract Retrieval API to get data. If a Copus ID is `nothing`, tries to set it based on the article's title.
"""
function setScopusAbstractRetrieval!(abstract::Abstract; only_local::Bool=false)::Nothing
    @debug "Setting basic information from Scopus for" abstract.title abstract.scopus_scopusid
    # Does it have a scopusid set? If not:
    if isnothing(abstract.scopus_scopusid)
        # Querying scopus
        title = join(split(lowercase(abstract.title), " "), "+AND+")
        query_string_title = "TITLE("*title*")"
        response = queryScopusSearch(query_string_title, only_local=only_local)
        # Do I have a response?
        if isnothing(response)
            @debug "Couldn't find scopus_id" abstract.title query_string_title queryID(query_string_title)
            return nothing
        end
        # Parsing the response into the Abstract
        response_parse = JSON.parse(response)
        if haskey(response_parse["search-results"]["entry"][1], "prism:url")
            @debug "Number of results while trying to set Scopus ID" length(response_parse["search-results"]["entry"])
            scopusid = response_parse["search-results"]["entry"][1]["prism:url"]
            scopusid = replace(scopusid, r"https://api.elsevier.com/content/abstract/scopus_id/"=>"")
            abstract.scopus_scopusid = parse(Int, scopusid)
            @debug "Scopus ID set succesfully?" abstract.title abstract.scopus_scopusid
        else
            @debug "Couldn't find information on Scopus Search for" abstract.title
            return nothing
        end
    end
    query_string = string(abstract.scopus_scopusid)
    response = queryScopusAbstractRetrieval(query_string, only_local=only_local)
    if isnothing(response)
        @debug "Couldn't set information on Scopus Abstract Retrieval, no response from Scopus Abstract Retrieval" abstract.title abstract.scopus_scopusid queryID(query_string)
        return nothing
    end
    try
        response_parse = JSON.parse(response)
        response_parse = response_parse["abstracts-retrieval-response"]
        # Setting the fields
        abstract.title = response_parse["coredata"]["dc:title"]
        abstract.date_pub = Date(response_parse["coredata"]["prism:coverDate"])
    catch y
        
    end
    @debug "Basic information set?" abstract.title abstract.date_pub abstract.scopus_authids
    return nothing
end

