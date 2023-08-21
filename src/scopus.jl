include("secrets.jl")

export setScopusApiKey, setScopusSearchData!

scopusAuthorSearch_fprefix = "Scopus-AuthorSearch"
scopusAbstractRetrieval_fprefix = "Scopus-AbstractRetrieval"
scopusSearch_fprefix = "Scopus-Search"

function setScopusApiKey(api_key::String)::Nothing
    scopus_api_key = api_key
end

function remoteQueryScopusAuthorSearch(query_string::String)
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

function queryScopusAuthorSearch(query_string::String)::String
    local_query = localQuery(scopusAuthorSearch_fprefix, query_string)
    if !isnothing(local_query)
        return local_query
    else
        return remoteQueryScopusAuthorSearch(query_string)    
    end
end

"""
    setScopusSearchData!(::Author)::Nothing
"""
function setBasicInfoFromScopus!(author::Author)::Nothing
    query_string = "AUTHLASTNAME($(author.query_name)) and AFFIL($(author.query_affiliation))"
    response = queryScopusAuthorSearch(query_string)

    # Setting the Author values
    author.scopus_firstname         = response_parse["search-results"]["entry"][1]["preferred-name"]["given-name"]
    author.scopus_lastname          = response_parse["search-results"]["entry"][1]["preferred-name"]["surname"]
    author.scopus_affiliation_id    = response_parse["search-results"]["entry"][1]["affiliation-current"]["affiliation-id"]
    author.scopus_affiliation_name  = response_parse["search-results"]["entry"][1]["affiliation-current"]["affiliation-name"]
    author.orcid_id                 = response_parse["search-results"]["entry"][1]["orcid"]
    author.scopus_query_nresults    = response_parse["search-results"]["opensearch:totalResults"]
    author.scopus_query_string      = query_string
    ## Triming the authors url to get the id
    scopus_authid                   = response_parse["search-results"]["entry"][1]["prism:url"]
    scopus_authid                   = replace(scopus_authid, r"https://api.elsevier.com/content/author/author_id/"=>"")
    author.scopus_authid            = parse(Int, scopus_authid)

    return nothing
end

function queryScopusAbstractRetrieval(query_string::String)
    localQuery = localQuery(scopusAbstractRetrieval_fprefix, query_string)
    if !isnothing(localQuery)
        return localQuery
    else
        # Preparing API 
        endpoint = "https://api.elsevier.com/content/abstract/scopus_id/"
        headers = [
                   "Accept" => "application/json",
                  "X-ELS-APIKey" => scopus_api_key
                  ]
        @info "Querying Scopus Abstract Retrieval API" abstract.scopus_scopusid 
        response = HTTP.get(endpoint*query_string, headers).body |> String

        saveQuery(scopusAbstractRetrieval_fprefix, query_string)

        return response
    end
end

"""
    setScopusData!(::Abstract)

Uses the Scopus Abstract Retrieval API to get data.
"""
function setBasicInfoFromScopus!(abstract::Abstract)::Nothing
    query_string = abstract.scopus_scopusid
    response = queryScopusAbstractRetrieval(query_string)
    response_parse = JSON.parse(response)
    response_parse = response_parse["abstracts-retrieval-response"]

    # Setting the fields
    abstract.title = response_parse["coredata"]["dc:title"]
    abstract.date = Date(response_parse["coredata"]["prism:coverDate"])
    ## Authors
    n_authors = length(response_parse["authors"]["author"])
    abstract.scopus_authids = Vector{Int}(undef, n_authors)
    for (i, author) in enumerate(response_parse["authors"]["author"])
        abstract.scopus_authids[i] = parse(Int, author["@auid"])
    end

    return nothing
end

function queryScopusSearch(query_string::String)::String
    local_query = local_query(scopusSearch_fprefix, query_string)
    if !isnothing(local_query)
        return local_query
    else
        # Preparing API 
        endpoint = "https://api.elsevier.com/content/search/scopus"
        headers = [
                   "Accept" => "application/json",
                   "X-ELS-APIKey" => scopus_api_key
                  ]
        params = ["query" => query_string]
        @info "Querying Scopus for abstracts by" author
        response = HTTP.get(endpoint, headers; query=params).body |> String
        saveQuery(scopusSearch_fprefix, query_string, response)
    end

    return response
end

"""
- write!

Issues:
- It's allocating more space than it needs. Final vector has lots of #undef.

Tasks:
- Iterate over the list of received objects and populate the Vector{Abstract}
- Do a double check wheater the received abstracts indeed are authored by the given author
"""
function getScopusAuthoredAbstracts(author::Author)::Vector{Abstract}
    query_string = "AU-ID($(author.scopus_authid))"
    response = queryScopusSearch(query_string)
    response_parse = JSON.parse(response)
    
    # Setting the values
    n_abstracts = parse(Int, response_parse["search-results"]["opensearch:totalResults"])
    @info n_abstracts
    authored_abstracts = Vector{Abstract}(undef, n_abstracts)
    # debugging
    for (i, abstract) in enumerate(response_parse["search-results"]["entry"])
        # Setting the fields
        authored_abstracts[i]                   = Abstract() # initializing the struct
        authored_abstracts[i].title
        ## Triming the abstract url to get the id
        scopus_scopusid                         = abstract["prism:url"]
        scopus_scopusid                         = replace(scopus_scopusid, r"https://api.elsevier.com/content/abstract/scopus_id/"=>"")
        authored_abstracts[i].scopus_scopusid   = parse(Int, scopus_scopusid)
        ## Setting the DOI if it's present
        authored_abstracts[i].doi               = get(abstract, "prism:doi", nothing)
    end
    
    return authored_abstracts
end

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
    abstracts = author.scopus_abstracts

    # Getting a list of all publication dates
    all_citation_dates = Vector{Date}()
    for abstract in abstracts
        append!(all_citation_dates, getCitationDates(abstract))
    end
    sort!(pub_dates)

    hindex_current = 0
    hindex_values = Vector{Int}
    hindex_dates = Vector{Date}
    for date in all_citation_dates
        citation_count_per_abstract = Vector{Int}()
        for abstract in abstracts
            push!(citation_count_per_abstract, to(abstract.scopus_citation_count, date)[end])
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
end


