include("secrets.jl")
include("local.jl")

export setScopusApiKey, setScopusSearchData!, getCitationDates

scopusAuthorSearch_fprefix = "Scopus-AuthorSearch"
scopusAbstractRetrieval_fprefix = "Scopus-AbstractRetrieval"
scopusSearch_fprefix = "Scopus-Search"

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

"""
    setScopusSearchData!(::Author)::Nothing
"""
function setBasicInfoFromScopus!(author::Author; only_local::Bool=false)::Nothing
    @info "Setting basic information for" author.query_name author.query_affiliation
    query_string = "AUTHLASTNAME($(author.query_name)) and AFFIL($(author.query_affiliation))"
    local_query = localQuery(scopusAuthorSearch_fprefix, query_string)
    response = ""
    if isnothing(local_query)
        response = queryScopusAuthorSearch(query_string)
    else
        response = local_query
    end
    response_parse = JSON.parse(response)

    # Setting the Author values
    author.scopus_firstname         = response_parse["search-results"]["entry"][1]["preferred-name"]["given-name"]
    author.scopus_lastname          = response_parse["search-results"]["entry"][1]["preferred-name"]["surname"]
    author.scopus_affiliation_id    = response_parse["search-results"]["entry"][1]["affiliation-current"]["affiliation-id"]
    author.scopus_affiliation_name  = response_parse["search-results"]["entry"][1]["affiliation-current"]["affiliation-name"]
    #author.orcid_id                 = response_parse["search-results"]["entry"][1]["orcid"]
    author.scopus_query_nresults    = response_parse["search-results"]["opensearch:totalResults"]
    author.scopus_query_string      = query_string
    ## Triming the authors url to get the id
    scopus_authid                   = response_parse["search-results"]["entry"][1]["prism:url"]
    scopus_authid                   = replace(scopus_authid, r"https://api.elsevier.com/content/author/author_id/"=>"")
    author.scopus_authid            = parse(Int, scopus_authid)

    return nothing
end

function queryScopusAbstractRetrieval(query_string::String; only_local::Bool=false, in_a_hurry::Bool=false)::Union{String, Nothing}
    if !in_a_hurry && !only_local; sleep(0.5); end # Sleep for half a second to avoid receiving a TOO MANY REQUESTS
    response = ""
    local_query = localQuery(scopusAbstractRetrieval_fprefix, query_string)
    if !isnothing(local_query)
        @info "Scopus Abstract Retrieval found locally" query_string
        return local_query
    elseif !only_local && !queryKnownToFault(scopusAbstractRetrieval_fprefix, query_string)
        # Preparing API
        @info "Requesting Scopus Abstract Retrieval API" query_string
        endpoint = "https://api.elsevier.com/content/abstract/scopus_id/"
        headers = [
                   "Accept" => "application/json",
                  "X-ELS-APIKey" => scopus_api_key
                  ]
        try
            response = HTTP.get(endpoint*query_string, headers).body |> String
        catch y
            if isa(y, HTTP.StatusError)
                @error "HTTP StatusError on Scopus Abstract Retrieval" 
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

"""
    setScopusData!(::Abstract)

Uses the Scopus Abstract Retrieval API to get data.
"""
function setBasicInfoFromScopus!(abstract::Abstract; only_local::Bool)::Nothing
    @debug "Setting basic information for" abstract.title abstract.scopus_scopusid

    # Does it have a scopusid set? If not:
    if isnothing(abstract.scopus_scopusid)
        query_string_title = "TITLE($(abstract.title))"
        response = queryScopusSearch(query_string_title, only_local=only_local)
        if isnothing(response)
            @error "Couldn't find scopus_id" abstract.title query_string_title queryID(query_string_title)
            return nothing
        end
        response_parse = JSON.parse(response)
        if haskey(response_parse["search-results"]["entry"][1], "prism:url")
            scopusid = response_parse["search-results"]["entry"][1]["prism:url"]
            scopusid = replace(scopusid, r"https://api.elsevier.com/content/abstract/scopus_id/"=>"")
            abstract.scopus_scopusid = parse(Int, scopusid)
            @debug "Scopus ID set succesfully?" abstract.title abstract.scopus_scopusid
        else
            @error "Couldn't find information on Scopus Search for" abstract.title
            return nothing
        end
    end

    query_string = string(abstract.scopus_scopusid)
    response = queryScopusAbstractRetrieval(query_string, only_local=only_local)
    if isnothing(response)
        @error "Couldn't set information on Scopus Abstract Retrieval, no response from Scopus Abstract Retrieval" abstract.title abstract.scopus_scopusid queryID(query_string)
        return nothing
    end
    response_parse = JSON.parse(response)
    response_parse = response_parse["abstracts-retrieval-response"]

    # Setting the fields
    abstract.title = response_parse["coredata"]["dc:title"]
    abstract.date_pub = Date(response_parse["coredata"]["prism:coverDate"])
    ## Authors
    ### ["coredata"]
    #=
    if (!haskey(response_parse["coredata"], "authors") ||
        !haskey(response_parse["authors"] ,"author") ||
        )
        @error "No authids found on response" abstract.title queryID(query_string)
        return nothing
    else
        n_authors = length(response_parse["authors"]["author"])
        abstract.scopus_authids = Vector{Int}(undef, n_authors)
        for (i, author) in enumerate(response_parse["authors"]["author"])
            abstract.scopus_authids[i] = parse(Int, author["@auid"])
        end
    end
    =#
    if haskey(response_parse["coredata"], "dc:creator")
        @debug "dc:creator style"
    elseif haskey(response_parse, "authors") || haskey(response_parse["author"], "author")
        @debug "[authors][author] style"
    else
        @debug "new style"
    end

    @debug "Basic information set?" abstract.title abstract.date_pub abstract.scopus_authids

    return nothing
end

function queryScopusSearch(query_string::String, start::Int=0; only_local::Bool, in_a_hurry::Bool=false)::Union{String, Nothing}
    if !in_a_hurry && !only_local; sleep(0.5); end # Sleep for half a second to avoid receiving a TOO MANY REQUESTS
    formatted_query_string = "$query_string"
    local_query = localQuery(scopusSearch_fprefix, formatted_query_string*"$start")
    if !isnothing(local_query)
        @debug "Scopus Search found locally" query_string
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
            response = HTTP.get(endpoint, headers; query=params).body |> String
            return response
        catch y
            if isa(y, HTTP.Exceptions.StatusError)
                @error "HTTP StatusError for Scopus Search" query_string*"$start"
                addQueryKnownToFault(scopusSearch_fprefix, query_string*"$start")
                return nothing
            end
        end
        saveQuery(scopusSearch_fprefix, formatted_query_string*"$start", response)
    end
end

"""
- write!

Issues:
- It's allocating more space than it needs. Final vector has lots of #undef.

Tasks:
- Iterate over the list of received objects and populate the Vector{Abstract}
- Do a double check wheater the received abstracts indeed are authored by the given author
"""
function getScopusAuthoredAbstracts(author::Author; only_local::Bool=false)::Vector{Abstract}
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
        for (i, result) in enumerate(response_parse["search-results"]["entry"])
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
        @info "Querying for another Scopus Search results page"
    end
    return authored_abstracts
end

#=
"""
    getScopusCitingAbstracts(::Abstract)::Vector{Abstract}

Queries scopus for a list of abstracts that cite the given abstract
"""
function setScopusCitingAbstracts(abstract::Abstract)#::Vector{Abstract}
    @warn "getScopusCitingAbstracts not implemented"
    # Preparing API 
    endpoint = "https://api.elsevier.com/content/search/scopus"
    headers = [
               "Accept" => "application/json",
               "X-ELS-APIKey" => scopus_api_key
              ]
    #query_string = "REFEID($(abstract.scopus_scopusid))" # APIKey doesn't have privileges
    query_string = "REFEID($(abstract.scopus_scopusid))"
    params = ["query" => query_string]
    @info "Querying Scopus Search for arcticles that cite" abstract.title
    response = HTTP.get(endpoint, headers; query=params).body |> String
    response_parse = JSON.parse(response)

    #abstract.citations = ::Vector{Abstract}
end
=#

function setScopusCitationCount(abstract::Abstract)::Nothing
    if isnothing(abstract.scopus_citations)
        @error "No citations set for the given abstract"
    end
    
    citation_dates = Vector{Date}
    for citation in abstract.citations
        push!(citation_dates, citation.date)
    end

    abstract.scopus_citation_count = TimeArray(citation_dates, 1:length(abstract.citations))
end

"""
Tasks:
- Better names for the variables please
"""
function setScopusHIndex!(author::Author)::Nothing
    abstracts = author.abstracts
    all_citation_dates = getCitationDates(author) # Getting a list of all publication dates
    hindex_current = 0
    hindex_values = Vector{Int}()
    hindex_dates = Vector{Date}()
    for date in all_citation_dates
        citation_count_per_abstract = Vector{Int}()
        for abstract in abstracts
            if !isnothing(abstract.scopus_citation_count) && length(values(to(abstract.scopus_citation_count, date))) > 0
                push!(citation_count_per_abstract, values(to(abstract.scopus_citation_count, date))[end])
            end
        end
        hindex_at_date = calcHIndex(citation_count_per_abstract)
        if hindex_at_date > hindex_current
            hindex_current = hindex_at_date
            push!(hindex_values, hindex_at_date)
            push!(hindex_dates, date)
        end
    end

    hindex = TimeArray(hindex_dates, hindex_values)
    author.scopus_hindex = hindex
    
    return nothing
end


