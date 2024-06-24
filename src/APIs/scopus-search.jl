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
        headers = ["Accept" => "application/json",
                   "X-ELS-APIKey" => scopus_api_key]
        params = ["query" => formatted_query_string,
                  "start" => "$start"]
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
    scopussearch(::Researcher, only_local=false, progress_bar=false,)
"""
function scopussearch(author::Author; 
                      only_local=false,
                      progress_bar::Bool=false,
                      in_a_hurry=false)::Vector{Publication}
    query_string = "AU-ID($(author.scopus_authid))"
    start = 0
    authored_abstracts = Vector{Abstract}()

    # Set iteration
    response = ""
    response_parse = Dict()
    try
        response = _requestScopusSearch(query_string, only_local=only_local, in_a_hurry=in_a_hurry)
        response_parse = JSON.parse(response)
    catch y
        @debug y
    end
    n_result_total = parse(Int, response_parse["search-results"]["opensearch:totalResults"]) # no need to be done every loop

    max_npublication = 800
    if n_result_total > max_npublication
        @warn "Author published more than $(max_npublication) publications. Only $(max_npublication) will be retrieved."
        n_result_total = 240
    end # Limiting the amount of abstracts queried REFACTOR THIS ATROCITY

    start_offsets = 0:scopus_nresultsperpage:n_result_total
    if progress_bar; start_offsets = ProgressBar(1:scopus_nresultsperpage:n_result_total); end
    for start in start_offsets
        response_iter = 0
        try
            response = _requestScopusSearch(query_string, start=start, only_local=only_local, in_a_hurry=in_a_hurry)
            response_parse = JSON.parse(response)
            response_iter = enumerate(response_parse["search-results"]["entry"])
            #@debug response response_parse response_iter
        catch y
            @debug "aqui" y
            continue
        end
        for (i, result) in response_iter
            abstract = Publication()
            try # eventually the results come with messed up fields
                abstract.title = result["dc:title"]
                # Setting the fields
                ## Triming the abstract url to get the id
                scopus_scopusid           = result["prism:url"]
                scopus_scopusid           = replace(scopus_scopusid, r"https://api.elsevier.com/content/abstract/scopus_id/"=>"")
                abstract.scopus_scopusid  = parse(Int, scopus_scopusid)
                ## Setting the DOI if it's present
                #abstract.doi               = result["prism:doi"]
            catch y
                @debug y
            end
            push!(authored_abstracts, abstract)
        end
    end
    return authored_abstracts
end

function setScopusSearch!(author::Author; only_local::Bool=false, progress_bar=false)::Nothing
    author.abstracts = scopussearch(author, only_local=only_local, progress_bar=progress_bar)
    return nothing
end
@deprecate setAuthoredAbstracts!(author::Author; only_local::Bool=false) setScopusArticles!(author, only_local=only_local)

"""
    setscopussearch!(::Publication; only_local::Bool)::Nothing

Use the Scopus Abstract Retrieval API to get data and set the 

If a Copus ID is `nothing`, tries to set it based on the article's title.
"""
function setScopusSearch!(abstract::Abstract; only_local::Bool=false)::Nothing
    @debug "`setScopusSearch` setting basic information from Scopus for" abstract.title abstract.scopus_scopusid

    # Does it have a scopusid set? If not:
    if isnothing(abstract.scopus_scopusid)
        # Querying scopus
        title = abstract.title
        title = _formattitleforscopussearch(title)
        title = join(split(lowercase(title), " "), "+AND+")
        query_string_title = "TITLE("*title*")"
        response = queryScopusSearch(query_string_title, only_local=only_local)
        # Do I have a response?
        if isnothing(response)
            @warn "Couldn't find scopus_id using title" abstract.title 
            @debug "`setScopusSearch` failed due to lack of response" query_string_title queryID(query_string_title)
            return nothing
        end

        # Parsing the response into the Abstract
        response_parse = JSON.parse(response)
        if haskey(response_parse["search-results"]["entry"][1], "prism:url")
            scopusid = response_parse["search-results"]["entry"][1]["prism:url"]
            scopusid = replace(scopusid, r"https://api.elsevier.com/content/abstract/scopus_id/"=>"")
            abstract.scopus_scopusid = parse(Int, scopusid)
            @debug "`setScopusSearch` Scopus ID set succesfully (?)" abstract.title abstract.scopus_scopusid length(response_parse["search-results"]["entry"])
        else
            @warn "Couldn't set Scopus Search information for publication" abstract.title
            @debug "`setScopusSearch` couldn't find information on Scopus Search for" abstract.title query_string_title queryID(query_string_title)
            return nothing
        end
    end
end

#=
#Maybe wrap it in a type?
struct ScopusSearch <: AbstractVector{Abstract}
    results::Vector{Abstract}
    start::Int
end

function getindex(x::ScopusSearch, i)
    x.results[i]
end

function firstindex(x::ScopusSearch)
    x.results[first]
end

function lastindex(x::ScopusSearch)
    x.results[end]
end

function size(x::ScopusSearch)
    size(x.results)
end
=#
