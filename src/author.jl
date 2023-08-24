include("abstract.jl")

export Author
export setAuthoredAbstracts!, setCitations!

"""
Stores informations about the author based on a database query.

Fields meaning
- `query_name`: name used for querying the database
- `query_affiliation`: institution used for querying the database 

Tasks:
- Refactor `scopus_FIELD` to `FIELD`
"""
mutable struct Author
    # Query data
    query_name::Union{String, Nothing}
    query_affiliation::Union{String, Nothing}

    # Basic info
    firstname::Union{String, Nothing}
    lastname::Union{String, Nothing}
    affiliation::Union{String, Nothing}

    abstracts::Union{Vector{Abstract}, Nothing}

    # Scopus
    ## Basic info
    scopus_authid::Union{Int, Nothing}
    scopus_firstname::Union{String, Nothing}
    scopus_lastname::Union{String, Nothing}
    scopus_affiliation_name::Union{String, Nothing}
    scopus_affiliation_id::Union{String, Nothing}
    scopus_query_nresults::Union{String, Nothing}
    scopus_query_string::Union{String, Nothing}
    scopus_hindex::Union{TimeArray, Nothing}
    ## Authored

    # ORCID
    orcid_id::Union{String, Nothing}

    # Enforce that `Author` has at least these two fields filled up
    function Author(query_name::String, query_affiliation::String)
        author = new(ntuple(x->nothing, fieldcount(Author))...)
        author.query_name = query_name
        author.query_affiliation = query_affiliation
        return author
    end
end

"""
    getAuthorsFromCSV()

Querys the database to obtain a list of scientist ids.
"""
function getAuthorsFromCSV(file::String)::Vector{Author}
    @warn "getAuthorsFromCSV() not implemented"
end

function setBasicInfo!(author::Author; only_local::Bool=false)::Nothing
    setBasicInfoFromScopus!(author, only_local=only_local)
end

function setAuthoredAbstracts!(author::Author; only_local::Bool=false)::Nothing
    author.abstracts = getScopusAuthoredAbstracts(author, only_local=only_local)
    return nothing
end

function setCitations!(author::Author; only_local::Bool=false)::Nothing
    @debug length(author.abstracts)
    for i in 1:length(author.abstracts)
        setCitations!(author.abstracts[i], only_local=only_local)
    end
    return nothing
end

function setCitationsBasicInfo!(author::Author; only_local::Bool=false)::Nothing
    for i in 1:length(author.abstracts)
        setCitationsBasicInfo!(author.abstracts[i], only_local=only_local)
    end
end
