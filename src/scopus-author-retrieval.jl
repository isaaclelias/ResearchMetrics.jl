function queryScopusAuthorSearch(query_string::String)::String
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

