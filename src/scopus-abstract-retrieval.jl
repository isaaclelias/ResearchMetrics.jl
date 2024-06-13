function _requestScopusAbstractRetrieval(query_string::String; only_local::Bool=false, in_a_hurry::Bool=false)::Union{String, Nothing}
    response = ""
    local_query = localQuery(scopusAbstractRetrieval_fprefix, query_string)
    if !isnothing(local_query)
        return local_query
    elseif !only_local && !queryKnownToFault(scopusAbstractRetrieval_fprefix, query_string)
        # Preparing API
        @debug "_requestScopusAbstractRetrieval\nQuery not found locally. Requesting API." query_string
        endpoint = "https://api.elsevier.com/content/abstract/scopus_id/"
        headers = ["Accept" => "application/json",
                   "X-ELS-APIKey" => scopus_api_key]
        try
            if !in_a_hurry; sleep(0.5); end # Sleep for half a second to avoid receiving a TOO MANY REQUESTS
            response = HTTP.get(endpoint*query_string, headers).body |> String
        catch y
            if isa(y, HTTP.StatusError)
                @debug "_requestScopusAbstractRetrieval\nStatusError on Scopus Abstract Retrieval" 
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
@deprecate queryScopusAbstractRetrieval(query_string; only_local=false, in_a_hurry=false) _requestScopusAbstractRetrieval(query_string)

"""
    setScopusData!(::Abstract; only_local::Bool)::Nothing

Uses the Scopus Abstract Retrieval API to get data. If a Scopus ID is `nothing`, tries to set it based on the article's title.
"""
function setScopusAbstractRetrieval!(abstract::Abstract; only_local::Bool=false)::Nothing
    @debug "`setScopusAbstractRetrieval` setting from Scopus Abstract Retrieval" abstract.title abstract.scopus_scopusid

    # Does it have a scopusid set? If not:
    if isnothing(abstract.scopus_scopusid)
        setScopusSearch!(abstract)
    end

    # Does it have a scopusid after that?
    if isnothing(abstract.scopus_scopusid) 
        @warn "Couldn't set information from Scopus Abstract Retrieval. Failed to get a Scopus ID."
        return nothing
    end

    # The query
    query_string = string(abstract.scopus_scopusid)
    response = _requestScopusAbstractRetrieval(query_string, only_local=only_local)
    if isnothing(response)
        @warn "Couldn't set information from Scopus Abstract Retrieval." abstract.title 
        @debug "`setScopusAbstractRetrieval` failed due to lack of response." abstract.title abstract.scopus_scopusid queryID(query_string)
        return nothing
    end

    # Parse the results
    try
        response_parse = JSON.parse(response)
        response_parse = response_parse["abstracts-retrieval-response"]
        # Setting the fields
        abstract.title = response_parse["coredata"]["dc:title"]
        abstract.date_pub = Date(response_parse["coredata"]["prism:coverDate"])

        abstract.scopus_authids = String[]
        for auth in response_parse["coredata"]["dc:creator"]["author"]
            push!(abstract.scopus_authids, auth["@auid"])
        end
    catch y
        @debug "setScopusAbstractRetrieval" y
    end

    @debug "`setScopusAbstractRetrieval` basic information set succesfully (?)" abstract.title abstract.date_pub abstract.scopus_authids

    return nothing
end

