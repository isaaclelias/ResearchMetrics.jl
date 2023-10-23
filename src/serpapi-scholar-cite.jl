export setSerpapiGScholarCite!

"""
    querySerpapiGScholarCite(::Abstract)

TASKS:
- Local query
"""
function querySerapiGScholarCite(abstract::Abstract, start::Int=0; only_local::Bool=false)::Union{Vector{Abstract}, Nothing}
    # Dealing with lack of information
    ## Nothing
    if isnothing(abstract.scholar_citesid)
        setBasicFieldsFromSerapiGScholar!(abstract)
    end
    # Missing
    if ismissing(abstract.scholar_citesid)
        @error "Couldn't query GScholarCite because citesid is missing" abstract.title 
        return nothing
    end
#=
    # Tries to set a citesid for the given abstract
    query_string = abstract.scholar_citesid
    if isnothing(abstract.scholar_citesid)
        @debug "No Scholar Cites ID set. Querying for it." abstract.title
        response = querySerapiGScholar(abstract.title, only_local=only_local)
        if isnothing(response)
            @error "Query for citeid returned empty"
            return nothing
        end
        response_parse = JSON.parse(response)
        if !haskey(response_parse, "organic_results")
            @error "Scholar response whitout organic_results"
            return nothing
        end
        if haskey(response_parse["organic_results"][1]["inline_links"], "cited_by")
            abstract.scholar_citesid = response_parse["organic_results"][1]["inline_links"]["cited_by"]["cites_id"]
            query_string = abstract.scholar_citesid
            @debug "Citedid set succesfully?" abstract.title abstract.scholar_citesid
        else
            @error "Couldn't set citedid" abstract.title abstract.scholar_citesid response_parse["organic_results"][1]["inline_links"]
            addQueryKnownToFault(serapi_fprefix, abstract.title) #it's added here because faulting is actually having a response without citesid instead of not responding
            return nothing
        end
    end
=#

    query_string = abstract.scholar_citesid
    endpoint = "https://serpapi.com/search?engine=google_scholar"
    start = -1
    n_response = 1
    n_response_total = 0
    citations = Vector{Abstract}()
    while true
        start = start+n_response
        if start >= 240
            break
        end

        # API Request
        @debug "Querying Google Scholar for citations" abstract.title abstract.scholar_citesid start
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
        # If not remote, give up
        if isnothing(response)
            @debug "No response"
            break
        end

        # Parsing and checking the response
        response_parse = JSON.parse(response)
        if (!haskey(response_parse, "organic_results") ||
            !haskey(response_parse["organic_results"][1]["inline_links"], "cited_by"))
            @warn "Received a response, but something wrong" abstract.title start n_response_total queryID(query_string*"$start")
            break
        end

        # Apending the returned citations
        for item in response_parse["organic_results"]
            citation = Abstract(item["title"])
            push!(citations, citation)
        end

        # Preparing to query the next results page
        n_response = length(response_parse["organic_results"])
        n_response_total = response_parse["search_information"]["total_results"]
        ## If last page
        if start >= n_response_total-10 || n_response == 0 || n_response_total <= 10 || start > 240
            break
        end
    end
    return citations
end

function setSerpapiGScholarCite!(abstract::Publication; only_local::Bool=false)::Nothing    
    abstract.scopus_citations = querySerapiGScholarCite(abstract, only_local=only_local)
    return nothing
end
@deprecate setCitations!(abstract::Abstract; only_local::Bool=false) setSerpapiGScholarCite!(abstract, only_local=only_local)

function setSerpapiGScholarCite!(author::Researcher; only_local::Bool=false)::Nothing
    @debug length(author.abstracts)
    for i in 1:length(author.abstracts)
        setCitations!(author.abstracts[i], only_local=only_local)
    end
    return nothing
end
@deprecate setCitations!(author::Author; only_local::Bool=false) setSerpapiGScholarCite!(author, only_local=only_local)

