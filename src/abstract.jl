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
    #is_in_scopus::Union{Bool, Nothing}
    scopus_citations::Union{Vector{Abstract}, Nothing}
    scopus_citation_count::Union{TimeArray, Nothing}
    
    # Empty constructor sets all fields to nothing
    function Abstract()
        author = new(ntuple(x->nothing, fieldcount(Abstract))...)
        return author
    end
end

"""
    getCitationDates(::Abstract)::Vector{Date}

NOT TESTED
Returns all the dates that the given abstract was cited.
"""
function getCitationDates(abstract::Abstract)::Vector{Date}
    # Do we have the data?
    if isnothing(abstract.scopus_citations)
        @error "Citations not present for the given abstract"
    end

    return citation_dates
end


