"""
Type used to represent a scientific publication.
"""
mutable struct Publication
    title::Union{String, Nothing} # TODO Separate in user_title and SOURCE_title
    date_pub::Union{Date, Nothing} # TODO refactor to user_date
    doi::Union{String, Nothing}
    scopus_citations::Union{Vector{Publication}, Nothing} # TODO Refactor to `citing_articles, refactor to only Vector{Publication}`

    # Scopus
    scopus_title::Union{String, Nothing}
    scopus_date::Union{Date, Nothing}
    scopus_scopusid::Union{Int, Nothing} # TODO refactor to scopus_id
    scopus_authids::Union{Vector{String}, Nothing}
    scopus_citation_count::Union{TimeArray, Nothing} # I dont thinks this is currently used. If so, could be used to store the "oficial" citation count by that source
    scopus_link::Union{String, Nothing}
    #gscholar_link_domain::Union{String, Nothing} # like link.springer.com
    success_set_scopus_search::Union{Bool, Nothing}
    success_set_scopus_abstract_retrieval::Union{Bool, Nothing}

    # Scholar
    gscholar_title::Union{String, Nothing}
    gscholar_date::Union{Date, Nothing}
    gscholar_authids::Union{Vector{String}, Nothing}
    gscholar_citation_count::Union{Int, Nothing}
    gscholar_link::Union{String, Nothing}
    #gscholar_link_domain::Union{String, Nothing} # like link.springer.com
    scholar_citesid::Union{String, Nothing} # TODO refactor to `gscholar`
    success_set_serpapi_google_scholar_search::Union{Bool, Nothing}
    success_set_serpapi_google_scholar_cite::Union{Bool, Nothing}

    # overrides? # TODO
    # over_title
    # over_date

    # TODO strip those off
    found_in_scopus::Union{Bool, Nothing} # strip this off
    found_in_scholar::Union{Bool, Nothing}
    
    # TODO remove this constructor
    function Publication()
        return new(ntuple(x->nothing, fieldcount(Publication))...)
    end
end
Base.@deprecate_binding Abstract Publication

########## CONSTRUCTORS ##########

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

########## GETTERS ##########

"""
    title(::Publication)

Return the Publication's title with source priority:
1. Scopus
2. Google Scholar
3. User given
4. Return `nothing`
"""
function title(p::Publication)::Union{String, Nothing}
    if     !isnothing(p.scopus_title);   return p.scopus_title
    elseif !isnothing(p.gscholar_title); return p.gscholar_title
    elseif !isnothing(p.title);          return p.title
    else;                                return nothing
    end
end

function date(p::Publication)
    
end

function link(p::Publication)
  
end

########## CALCULATIONS - needs better name ##########

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


function authids(p::Publication)
  
end


