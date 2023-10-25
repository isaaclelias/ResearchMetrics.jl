using Dates
using TimeSeries

export Publication
export setBasicInfo!, setCitations!, setCitationsBasicInfo!

"""
Store information about abstracts.
"""
mutable struct Publication
    title::Union{String, Nothing}
    date_pub::Union{Date, Nothing}
    doi::Union{String, Nothing}
    # Scopus
    scopus_scopusid::Union{Int, Nothing}
    scopus_authids::Union{Vector{Int}, Nothing}
    scopus_citation_count::Union{TimeArray, Nothing} # Refactor to citation count
    # Scholar
    scholar_citesid::Union{String, Nothing, Missing}
    # Should be refactored to be not scopus only
    scopus_citations::Union{Vector{Publication}, Nothing} # Refactor to `citing_articles, refactor to only Vector{Publication}`
    # Where is it listed?
    found_in_scopus::Union{Bool, Nothing}
    found_in_scholar::Union{Bool, Nothing}
    
    function Publication()
        return new(ntuple(x->nothing, fieldcount(Publication))...)
    end
end
Base.@deprecate_binding Abstract Publication

# Enforces that every abstract has a title
function Publication(title::String)
    abstract = Publication()
    abstract.title = title
    return abstract
end
   
function Publication(title::String, date::Date; citations=nothing)
    abstract = Publication()
    abstract.title = title
    abstract.date_pub = date
    abstract.scopus_citations = citations
    return abstract
end

function Publication(date::Date)
    abstract = Publication()
    abstract.date_pub = date
    return abstract
end

"""
    citationdates(::Publication)::Vector{Date}

NOT TESTED
Returns all the dates that the given abstract was cited.
"""
function citationdates(abstract::Publication)::Union{Vector{Date}, Nothing}
    citation_dates = Vector{Date}()
    # Do we have the data?
    if isnothing(abstract.scopus_citations)
        return citation_dates
    end

    for citation in abstract.scopus_citations
        if !isnothing(citation.date_pub)
            push!(citation_dates, citation.date_pub)
        end
    end
    sort!(citation_dates)
    return citation_dates
end
@deprecate getCitationDates(article::Publication) citationdates(article)

#=
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
=#

#=
function _setcitationcount!(abstract::Abstract)
    citation_dates = getCitationDates(abstract)
    if !isnothing(citation_dates)
        onetolength = [i for i=1:length(citation_dates)]
        abstract.scopus_citation_count = TimeArray(citation_dates, onetolength)
    else
        @error "Couldn't set citation dates for" abstract.title
    end
end
@deprecate setCitationCount!(article::Abstract) _setcitationcount!(abstract)
=#

function citations(article::Publication)
    if !isnothing(article.scopus_citations)
        return article.scopus_citations
    else
        return Vector{Publication}()
    end
end

function citationcount(publication::Publication)::Union{TimeArray, Nothing}
    citation_dates = citationdates(publication)
    if !isnothing(citation_dates)
        onetolength = [i for i=1:length(citation_dates)]
        return TimeArray(citation_dates, onetolength)
    else
        return nothing
    end
end

function citationcountat(article::Abstract, date::Date)::Int
    article.scopus_citation_count
end

function mapcitations(func, publication::Publication)
    if !isnothing(publication.scopus_citations)
        map(func, publication.scopus_citations)
    else
        return nothing
    end
end
