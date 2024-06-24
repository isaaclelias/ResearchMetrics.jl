using Dates
using TimeSeries

"""
Store information about a publication.
"""
mutable struct Publication
    title::Union{String, Nothing}
    date_pub::Union{Date, Nothing}
    doi::Union{String, Nothing}
    # Scopus
    scopus_scopusid::Union{Int, Nothing}
    scopus_authids::Union{Vector{String}, Nothing}
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

function citations(article::Publication)::Vector{Publication}
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

"""
    mapcitations(func, ::Publication)
"""
function mapcitations(func, publication::Publication)
    if !isnothing(publication.scopus_citations)
        map(func, publication.scopus_citations)
    else
        return nothing
    end
end

