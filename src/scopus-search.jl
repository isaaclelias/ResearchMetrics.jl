export setAuthoredPublicationsOnScopus!

function _requestScopusSearch(query_string::String; start::Int=0, only_local::Bool=false, in_a_hurry::Bool=false)::Union{String, Nothing}
    formatted_query_string = query_string
    local_query = localQuery(scopusSearch_fprefix, formatted_query_string*"$start")
    if !isnothing(local_query)
        return local_query
    else
        if only_local | queryKnownToFault(scopusSearch_fprefix, query_string*"$start")
            return nothing
        end
        # Preparing API 
        endpoint = "https://api.elsevier.com/content/search/scopus"
        headers = [
                   "Accept" => "application/json",
                   "X-ELS-APIKey" => scopus_api_key
                  ]
        params = [
                  "query" => formatted_query_string,
                  "start" => "$start"
                  ]
        try
            if !in_a_hurry; sleep(0.5); end # Sleep for half a second to avoid receiving a TOO MANY REQUESTS
            response = HTTP.get(endpoint, headers; query=params).body |> String
            saveQuery(scopusSearch_fprefix, formatted_query_string*"$start", response)
            return response
        catch y
            if isa(y, HTTP.Exceptions.StatusError)
                @error "HTTP StatusError for Scopus Search" query_string start
                addQueryKnownToFault(scopusSearch_fprefix, query_string*"$start")
                return nothing
            end
        end
    end
end
@deprecate queryScopusSearch(query_string::String, start::Int=0; only_local::Bool=false, in_a_hurry::Bool=false) _requestScopusSearch(query_string, start=0, only_local=only_local, in_a_hurry=in_a_hurry)

"""
- write!

Issues:
- It's allocating more space than it needs. Final vector has lots of #undef.

Tasks:
- Iterate over the list of received objects and populate the Vector{Abstract}
- Do a double check wheater the received abstracts indeed are authored by the given author
"""
function getScopusAuthoredAbstracts(author::Author; 
                                    only_local::Bool=false,
                                    progress_bar::Bool=false)::Vector{Abstract}
    query_string = "AU-ID($(author.scopus_authid))"
    start = 0
    authored_abstracts = Vector{Abstract}()
    while true
        response = queryScopusSearch(query_string, start, only_local=only_local)
        response_parse = JSON.parse(response)
        # Setting the values
        # debugging
        if !haskey(response_parse["search-results"], "entry")
            @error "No entries found on Scopus Search answer" query_string*" start=$start"
            break
        end

        iter = enumerate(enumerate(response_parse["search-results"]["entry"]))
        if progress_bar; iter = ProgressBar(iter); end
        for (i, result) in iter
            abstract = Abstract(result["dc:title"])
            # Setting the fields
            ## Triming the abstract url to get the id
            scopus_scopusid                         = result["prism:url"]
            scopus_scopusid                         = replace(scopus_scopusid, r"https://api.elsevier.com/content/abstract/scopus_id/"=>"")
            abstract.scopus_scopusid   = parse(Int, scopus_scopusid)
            ## Setting the DOI if it's present
            #abstract.doi               = result["prism:doi"]
            setBasicInfo!(abstract, only_local=only_local)
            push!(authored_abstracts, abstract)
        end
        # Do we need to query again?
        n_result = length(response_parse["search-results"]["entry"])
        start = start+n_result
        n_result_total = parse(Int, response_parse["search-results"]["opensearch:totalResults"]) # no need to be done every loop
        if start >= n_result_total
            break
        end
        @debug "Querying for another Scopus Search results page"
    end
    return authored_abstracts
end

function setAuthoredPublicationsWithScopusSearch!(author::Author; only_local::Bool=false; progress_bar=false)::Nothing
    author.abstracts = getScopusAuthoredAbstracts(author, only_local=only_local, progress_bar=progress_bar)
    return nothing
end
@deprecate setAuthoredAbstracts!(author::Author; only_local::Bool=false) setScopusArticles!(author, only_local=only_local)
