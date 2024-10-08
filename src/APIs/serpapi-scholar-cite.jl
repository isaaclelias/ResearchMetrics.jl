"""
    querySerpapiGScholarCite(::Abstract, start::Int=0, only_local::Bool=false)

Fetches list of citations for a given publication using Google Scholar Cite through SerpApi. The query first tries to retrieve the information in the local cache
"""
function querySerapiGScholarCite(abstract::Abstract, start::Int=0; only_local::Bool=false, progress_bar::Bool=false, progress)::Union{Vector{Abstract}, Nothing}
    abstract.success_set_serpapi_google_scholar_cite = false
    # Dealing with lack of information
    ## Nothing
    if isnothing(abstract.scholar_citesid)
        @debug "`querySerpapiGScholarCite` failing because to Scholar Cite ID is nothing" title(abstract)
        return nothing
    end


    # Fails if Cite ID is missing
    if ismissing(abstract.scholar_citesid)
        @debug "Couldn't query GScholarCite because citesid is missing" abstract.title 
        return nothing
    end

    # Prepare the query
    query_string = abstract.scholar_citesid
    endpoint = "https://serpapi.com/search?engine=google_scholar"
    start = -1
    n_response = 1
    n_response_total = 0
    
    # Loop through the pages and append the citations
    citations = Vector{Abstract}()
    while true # refactor for a proper for loop intead of this atrocity
        start = start+n_response
        if start >= 240
            break
        end

        # API Request
        @debug "Querying Google Scholar for citations" title(abstract) abstract.scholar_citesid start
        response = nothing
        ## Trying locally
        local_query = localQuery(serpapiGScholarCite_fprefix, query_string*"$start")
        if !isnothing(local_query)
            response = local_query
        end
        ## If not found locally, try remote
        if isnothing(response) && !only_local
            params = ["api_key" => serapi_api_key,
                      "engine" => "google_scholar",
                      "cites" => query_string,
                      "start" => "$start"]
            sleep(3.6)
            response = HTTP.get(endpoint; query=params).body |> String
            saveQuery(serpapiGScholarCite_fprefix, query_string*"$start", response)
        end

        # If not no response, pass to next iteration 
        if isnothing(response)
            @debug "`querySerpapiGScholarCite` no response from local or remote sources"
            break
        end

        # Parsing and checking the response
        response_parse = JSON.parse(response)
        if !haskey(response_parse, "organic_results")# ||
           #!haskey(response_parse["organic_results"][1]["inline_links"], "cited_by"))
            @debug "`querySerpapiGScholarCite` Received a response with no `organic_results`" abstract.title start n_response_total queryID(query_string*"$start") #!haskey(response_parse, "organic_results") !haskey(response_parse["organic_results"][1]["inline_links"], "cited_by")
            break
        end

        # Apending the returned citations
        for item in response_parse["organic_results"]
            citation = Abstract(item["title"])
            citation.gscholar_date = begin
                if haskey(item, "publication_info") && haskey(item["publication_info"], "summary")
                    _parse_gscholar_summary_to_date(item["publication_info"]["summary"])
                else
                    missing
                end
            end
            citation.gscholar_pub_link = begin
                if haskey(item, "link")
                    item["link"]
                else
                    missing
                end
            end
            push!(citations, citation)
            next!(progress)
            @debug "`querySerpapiGScholarCite` found citation found" citation.title
        end

        # Preparing to query the next results page
        n_response = length(response_parse["organic_results"])
        n_response_total = response_parse["search_information"]["total_results"]

        ## If last page, break. Shoudn't return to the loop after this break
        if start >= n_response_total-10 || n_response == 0 || n_response_total <= 10 || start > 240
            abstract.success_set_serpapi_google_scholar_cite = true
            break
        end
    end

    @debug "`querySerpapiGScholarCite` returned" length(citations)
    return citations
end

function request_serpapi_google_scholar_cite_api(gscholar_citesid::AbstractString; start::Int=0)
  
end

function query_serpapi_google_scholar_cite(arguments)
  
end

function _parse_gscholar_summary_to_date(s::AbstractString)
  r = r" ((?:19|20)[0-9]{2}) " # matches any number between 1900 and 2099
    dat = match(r, s)

    if !isnothing(dat)
        return Date(dat.captures[1])
    else
        return missing
    end
end

function set_serpapi_google_scholar_cite!(
        abstract::Publication;
        only_local::Bool=false,
        progress_bar::Bool=false,
        progress=nothing
    )::Nothing 

    _progress = nothing
    if isnothing(progress)
        _progress = ProgressUnknown(desc="Retrieved citations:", spinner=true)
    else
        _progress = progress
    end
    abstract.scopus_citations = querySerapiGScholarCite(abstract, only_local=only_local, progress=_progress)

    if isnothing(progress)
        finish!(_progress)
    end

    return nothing
end
@deprecate setCitations!(abstract::Abstract; only_local::Bool=false) setSerpapiGScholarCite!(abstract, only_local=only_local)
@deprecate setSerpapiGScholarCite!(a::Abstract; only_local::Bool=false) set_serpapi_google_scholar_cite!(a, only_local=only_local)

function set_serpapi_google_scholar_cite!(author::Researcher; only_local::Bool=false, progress_bar=false)::Nothing
    @debug "`setSerpapiGScholarCite!(::Researcher)`" length(author.abstracts)
    progress = ProgressUnknown(desc="Retrieved citations: grande", spinner=true)
    for i in 1:length(author.abstracts)
        setSerpapiGScholarCite!(author.abstracts[i], only_local=only_local, progress=progress)
    end

    finish!(progress)
    return nothing
end
#@deprecate setSerpapiGScholarCite!(r::Researcher; only_local::Bool=false) set_serpapi_google_scholar_cite!(r, only_local=only_local)
#@deprecate setCitations!(author::Author; only_local::Bool=false, progress_bar::Bool=false) setCitationsWithSerpapiGScholarCite!(author, only_local=only_local, progress_bar=progress_bar)
#@deprecate setSerpapiGScholarCite!(p::Publication; only_local::Bool=false, progress=nothing) set_serpapi_google_scholar_cite!(p, only_local=only_local, progress=progress)

function set_serpapi_google_scholar_cite_2!(
    r::Researcher;
    only_local::Bool=false,
    progress_bar::Bool=false
)

    progress = ProgressUnknown(desc="Retrieved citations:", spinner=true)
    mappublications(
        x->set_serpapi_google_scholar_cite!(x, only_local=only_local, progress=progress),
        r,
        progress_bar=progress_bar
    )
    finish!(progress)
  
end
