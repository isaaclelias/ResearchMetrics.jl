export Researcher
export hindex, articles, prizes, citationcountat, citations, citationdates, hindexat, mapcitations, mappublications

"""
Stores informations about the author based on a database query.

Fields meaning
- `query_name`: name used for querying the database
- `query_affiliation`: institution used for querying the database 

Tasks:
- Refactor `scopus_FIELD` to `FIELD`
"""
mutable struct Researcher
    # Basic info
    firstname::Union{String, Nothing}
    lastname::Union{String, Nothing}
    affiliation::Union{String, Nothing}
    abstracts::Union{Vector{Publication}, Nothing} # refactor to publications
    prizes::Union{Vector{Prize}, Nothing}
    # Scopus
    ## Basic info
    scopus_authid::Union{Int, Nothing}
    scopus_affiliation_id::Union{String, Nothing}
    scopus_firstname::Union{String, Nothing}
    scopus_lastname::Union{String, Nothing}
    scopus_affiliation::Union{String, Nothing}
    scopus_query_nresults::Union{String, Nothing}
    scopus_query_string::Union{String, Nothing}
    ## Authored
    # ORCID
    orcid_id::Union{String, Nothing}

    # Enforce that `Author` has at least these two fields filled up
    function Researcher(lastname::String, affiliation::String; prizes=nothing)
        author = new(ntuple(x->nothing, fieldcount(Author))...)
        author.lastname = lastname
        author.affiliation = affiliation
        author.prizes = prizes
        return author
    end
end
Base.@deprecate_binding Author Researcher

function citationdates(author::Researcher)::Vector{Date}
    all_citation_dates = Vector{Date}()
    for abstract in author.abstracts
        citation_dates = citationdates(abstract)
        if !isnothing(citation_dates)
            append!(all_citation_dates, citation_dates)
        end
    end
    sort!(all_citation_dates)
    return all_citation_dates
end
@deprecate getCitationDates(author::Author) citationdates(author)

function citationcount(researcher::Researcher)::TimeArray
    citation_dates = citationdates(researcher)
    if !isnothing(citation_dates)
        onetolength = [i for i=1:length(citation_dates)]
        return TimeArray(citation_dates, onetolength)
    else
        return nothing
    end    
end

function articles(author::Author)
    return author.abstracts
end

function prizes(author::Author)
    return author.prizes
end

function mappublications(func, researcher::Researcher; progress_bar::Bool=false)
    iter = articles(researcher)
    destination = []
    if progress_bar; iter = ProgressBar(iter); end
    for (i, publication) in iter
        push!(destination, func(researcher[i]))   
    end
    return destination
end

function mapcitations(func, researcher::Researcher, progress_bar)
    mappublications(abstract -> mapcitations(func, abstract), researcher.abstracts)

    iter = researcher.abstracts
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

