function _requestScopusAuthorSearch(query_string::String)::String
    local_query = localQuery(scopusAuthorSearch_fprefix, query_string)
    if !isnothing(local_query)
        return local_query
    else
        # Preparing API 
        endpoint = "https://api.elsevier.com/content/search/author"
        headers = [
                   "Accept" => "application/json",
                   "X-ELS-APIKey" => String(scopus_api_key)
                  ]
        params = ["query" => query_string]
        response = HTTP.get(endpoint, headers, query=params).body |> String
        saveQuery(scopusAuthorSearch_fprefix, query_string, response)
        return response    
    end
end

function set_scopus_author_search!(author::Author; only_local::Bool=false)::Nothing
    @debug "`setScopusAuthorSearch`" author.lastname author.affiliation
    query_string = "AUTHLASTNAME($(lowercase(author.lastname))) and AFFIL($(lowercase(author.affiliation)))"
    local_query = _localquery(scopusAuthorSearch_fprefix, query_string)
    response = ""
    if isnothing(local_query)
        response = _requestScopusAuthorSearch(query_string)
        # TASK deal with the case that no response is given
    else
        response = local_query
    end
    response_parse = JSON.parse(response)

    # Setting the Author values
    author.scopus_firstname         = response_parse["search-results"]["entry"][1]["preferred-name"]["given-name"]
    author.scopus_lastname          = response_parse["search-results"]["entry"][1]["preferred-name"]["surname"]
    author.scopus_affiliation_id    = response_parse["search-results"]["entry"][1]["affiliation-current"]["affiliation-id"]
    author.scopus_affiliation = response_parse["search-results"]["entry"][1]["affiliation-current"]["affiliation-name"]
    #author.orcid_id                 = response_parse["search-results"]["entry"][1]["orcid"]
    author.scopus_query_nresults    = response_parse["search-results"]["opensearch:totalResults"]
    author.scopus_query_string      = query_string
    ## Triming the authors url to get the id
    scopus_authid                   = response_parse["search-results"]["entry"][1]["prism:url"]
    scopus_authid                   = replace(scopus_authid, r"https://api.elsevier.com/content/author/author_id/"=>"")
    author.scopus_authid            = parse(Int, scopus_authid)

    return nothing
end

@deprecate setScopusAuthorSearch!(author, only_local=false) set_scopus_author_search(author, only_local=only_local)
