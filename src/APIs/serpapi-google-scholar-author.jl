fprefix_serpapi_google_scholar_author = "Serapi-GoogleScholarAuthor"

function request_serpapi_google_scholar_author_api(gscholar_author_id::AbstractString; start::Int=0)
    # Preparing API
    endpoint = "https://serpapi.com/search?engine=google_scholar_author"
    params = ["api_key" => serapi_api_key,
              "engine" => "google_scholar_author",
              "author_id" => gscholar_author_id,
              "start" => start]
    response = HTTP.get(endpoint; query=params).body |> String

    _savequery(fprefix_serpapi_google_scholar_author, gscholar_author_id*string(start), response)

    @debug "request_serpapi_google_scholar_author_api" gscholar_author_id 
    return response
end

function query_serpapi_google_scholar_author(gscholar_author_id::AbstractString; start::Int=0)
    response = _localquery(fprefix_serpapi_google_scholar_author, gscholar_author_id*string(start))
    if isnothing(response)
        response = request_serpapi_google_scholar_author_api(gscholar_author_id, start=start)
    end

    @debug "query_serpapi_google_scholar_author_api" gscholar_author_id
    return response
end

function set_serpapi_google_scholar_author!(r::Researcher)
    r.success_set_serpapi_google_scholar_author = false

    start = 0
    publications = Publication[]
    while !isnothing(start) # no, God, please no
        # get a response from somewhere
        response_parse = nothing  
        try
            response = query_serpapi_google_scholar_author(r.gscholar_author_id, start=start)
            response_parse = JSON.parse(response)
        catch y
            @debug "set_serpapi_google_scholar_author!() failed to get a response. Returning." name(r) start y
            return nothing
        end

        # set the next starting point
        try
            start = response_parse["serpapi_pagination"]["next"] |>
                    x->match(r"=([0-9]*)$", x).captures[1] |>
                    x->parse(Int, x)
        catch y
            @debug "set_serpapi_google_scholar_author!() reached the last page of results" name(r) start response_parse
            start = nothing
        end

        # use the response to set the fields
        try
            for article in response_parse["articles"]
                # should fail if not present
                pub = Publication()
                pub.gscholar_title = article["title"]
                pub.gscholar_link = article["link"]
                pub.gscholar_date = begin 
                    if length(article["year"]) > 0
                        return Date(article["year"])
                    else
                        return missing
                    end 
                end
                # should not fail if not present
                ## if an article has no citations yet, the "cites_id" field will not exist
                if haskey(article, "cited_by") && haskey(article["cited_by"], "cites_id")
                    pub.scholar_citesid = article["cited_by"]["cites_id"]
                end
                push!(publications, pub)
            end
        catch y
            @show y
        end
    end

    r.abstracts = publications
    r.success_set_serpapi_google_scholar_author = true
    return nothing
end
