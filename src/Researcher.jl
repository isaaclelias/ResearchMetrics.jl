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
    abstracts::Union{Vector{Publication}, Nothing} # refactor to publications, refactor to only Vector{publications}
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
    if isnothing(author.abstracts)
        return all_citation_dates
    end
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

function totalcitationcount(researcher::Researcher)::Int 
    n_citations = 0
    for publication in publications(researcher)
        pub_citations = citations(publication)
        if !isnothing(pub_citations)
            n_citations += length(citations(publication))
        end
    end
    return n_citations
end

function publications(author::Author)
    return author.abstracts
end

function prizes(author::Author)
    return author.prizes
end

function mappublications(func, researcher::Researcher; progress_bar::Bool=false)
    iter = enumerate(publications(researcher))
    destination = []
    if progress_bar; iter = ProgressBar(iter); end
    for (i, publication) in iter
        push!(destination, func(researcher.abstracts[i]))   
    end
    return destination
end

function mappublications!(func, destination::Researcher, collection); end

function mapcitations(func, researcher::Researcher; progress_bar=false)
    destination = []
    progress = ProgressBar(total=totalcitationcount(researcher))
    for (i, publication) in collect(enumerate(publications(researcher))) # REFACTOR!!!!!! NOT RACE-CONDITION FREE
        for (j, citation) in enumerate(citations(publication))
          ProgressBars.update(progress)
          func(researcher.abstracts[i].scopus_citations[j])
          #push!(destination, func(researcher.abstracts[i].scopus_citations[j]))
        end
    end
    return destination
end

function citations(researcher::Researcher)::Vector{Publication}
    cits = Publication[]
    for pub in publications(researcher)
        for cit in citations(pub)
            push!(cits, cit) 
        end
    end
    unique!(cits)
    return cits
end

