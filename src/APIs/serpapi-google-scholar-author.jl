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

function set_serpapi_google_scholar_author!(r::Researcher; progress_bar::Bool=false)
    r.success_set_serpapi_google_scholar_author = false
    r.abstracts = Publication[]

    start = 0
    n_articles = 0
    progress = ProgressUnknown(desc="Retrieved publications:")
    while !isnothing(start) # no, God, please no
        #progress_bar && print("Number of publications: $n_articles\r")
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
            @debug "set_serpapi_google_scholar_author!() reached the last page of results" name(r) start
            start = nothing
        end

        # use the response to set the fields
        try
            for article in response_parse["articles"]
                pub = Publication()
                pub.gscholar_title = article["title"]
                pub.gscholar_database_link = article["link"]

                pub.gscholar_date = begin 
                    if length(article["year"]) > 0
                        Date(article["year"])
                    else
                        missing
                    end 
                end

                pub.scholar_citesid = begin
                    if haskey(article, "cited_by") && haskey(article["cited_by"], "cites_id")
                        article["cited_by"]["cites_id"]
                    else
                        nothing
                    end
                end

                pub.gscholar_authors = begin
                    article["authors"]
                end

                pub.gscholar_citation_count = begin
                    if haskey(article, "cited_by") && haskey(article["cited_by"], "value")
                        article["cited_by"]["value"]
                    else
                        missing
                    end
                end

                n_articles = n_articles + 1

                pub.success_set_serpapi_google_scholar_author = true
                @debug "set_serpapi_google_scholar_author!() included a publication" title(pub) date(pub) pub.gscholar_database_link
                push!(r.abstracts, pub)
                #progress_bar && print("Number of publications: $(length(publications(r)))\r")
                progress_bar && next!(progress)
            end
        catch y
            @debug "set_serpapi_google_scholar_author!() exception thrown while setting researcher fields" y
        end
    end

    r.success_set_serpapi_google_scholar_author = true
    #isnothing(start) && progress_bar && print("\n") # new line
    progress_bar && finish!(progress)
    return nothing
end
