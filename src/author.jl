export Researcher
export hindex, articles, prizes, citationcountat, citations, citationdates, hindexat
export setAuthoredAbstracts!, setCitations!, getCitationDates

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

    abstracts::Union{Vector{Publication}, Nothing}
    prizes::Union{Vector{Prize}, Nothing}
    hindex::Union{TimeArray, Nothing}

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
    function Researcher(lastname::String, affiliation::String)
        author = new(ntuple(x->nothing, fieldcount(Author))...)
        author.lastname = lastname
        author.affiliation = affiliation
        return author
    end
end
Base.@deprecate_binding Author Researcher

function setBasicInfo!(author::Author; only_local::Bool=false)::Nothing
    setBasicInfoFromScopus!(author, only_local=only_local)
end

function setCitationsBasicInfo!(author::Author; only_local::Bool=false)::Nothing
    for i in 1:length(author.abstracts)
        setCitationsBasicInfo!(author.abstracts[i], only_local=only_local)
    end
end

function citationdates(author::Author)::Vector{Date}
    all_citation_dates = Vector{Date}()
    for abstract in author.abstracts
        if isnothing(abstract.scopus_citation_count)
            setCitationCount!(abstract)
        end
        citation_dates = getCitationDates(abstract)
        @debug citation_dates
        if !isnothing(citation_dates)
            append!(all_citation_dates, citation_dates)
        end
    end
    sort!(all_citation_dates)
    return all_citation_dates
end
@deprecate getCitationDates(author::Author) citationdates(author)

function citationcountat(author::Author, date::Date)::Int
    error("Not implemented")
end

function articles(author::Author)
    return author.abstracts
end

function prizes(author::Author)
    return author.prizes
end

function hindex(author::Author)
  if !isnothing(author.hindex)
      return author.scopus_hindex
  else
      _sethindex!(author)
      return author.scopus_hindex
  end
end

function hindexat(author::Author, date::Author)::Int
    error("Not implemented") 
end

function mapcitations(func, destination::Researcher)
    map(func, destination.citations)
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

