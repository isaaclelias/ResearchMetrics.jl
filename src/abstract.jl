using Dates
using TimeSeries

export setBasicInfo!, setCitations!, setCitationsBasicInfo!

"""
Store information about abstracts.
"""
mutable struct Abstract
    title::Union{String, Nothing}
    date_pub::Union{Date, Nothing}
    doi::Union{String, Nothing}

    # Scopus
    scopus_scopusid::Union{Int, Nothing}
    scopus_eid::Union{String, Nothing}
    scopus_authids::Union{Vector{Int}, Nothing}
    scopus_citation_count::Union{TimeArray, Nothing}

    # Scholar
    scholar_citesid::Union{String, Nothing}

    # Should be refactored to be not scopus only
    scopus_citations::Union{Vector{Abstract}, Nothing}

    # Where is it listed?
    found_in_scopus::Union{Bool, Nothing}
    found_in_scholar::Union{Bool, Nothing}
    
    # Enforces that every abstract has a title
    function Abstract(title::String)
        abstract = new(ntuple(x->nothing, fieldcount(Abstract))...)
        abstract.title = title
        return abstract
    end
end

function setBasicInfo!(abstract::Abstract; only_local::Bool=false)::Nothing
    setBasicInfoFromScopus!(abstract, only_local=only_local)
    return nothing
end

function setCitations!(abstract::Abstract; only_local::Bool=false)::Nothing    
    abstract.scopus_citations = querySerapiGScholarCite(abstract, only_local=only_local)
    return nothing
end

function setCitationsBasicInfo!(abstract::Abstract; only_local::Bool=false)::Nothing
    if isnothing(abstract.scopus_citations)
        @warn "No citations set for" abstract.title
        return nothing
    end
    for i in 1:length(abstract.scopus_citations)
        setBasicInfo!(abstract.scopus_citations[i], only_local=only_local)
    end
    return nothing
end

"""
    getCitationDates(::Abstract)::Vector{Date}

NOT TESTED
Returns all the dates that the given abstract was cited.
"""
function getCitationDates(abstract::Abstract)::Union{Vector{Date}, Nothing}
    # Do we have the data?
    if isnothing(abstract.scopus_citations)
        return nothing
    end

    citation_dates = Vector{Date}()
    for citation in abstract.scopus_citations
        if !isnothing(citation.date_pub)
            push!(citation_dates, citation.date_pub)
        end
    end
    sort!(citation_dates)
    return citation_dates
end

function setCitationCount!(abstract::Abstract)
    citation_dates = getCitationDates(abstract)
    if !isnothing(citation_dates)
        onetolength = [i for i=1:length(citation_dates)]
        abstract.scopus_citation_count = TimeArray(citation_dates, onetolength)
    else
        @error "Couldn't set citation dates for" abstract.title
    end
end