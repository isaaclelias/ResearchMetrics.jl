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
    scopus_citations::Union{Vector{Abstract}, Nothing}
    scopus_citation_count::Union{TimeArray, Nothing}

    # Scholar661347f2079f97d08567078d659bf462c8c86f5f8eaef71498e5bbf
    scholar_citesid::Union{Int, Nothing}

    # Where is it listed?
    found_in_scopus::Union{Bool, Nothing}
    found_in_scholar::Union{Bool, Nothing}
    
    # Empty constructor sets all fields to nothing
    function Abstract()
        author = new(ntuple(x->nothing, fieldcount(Abstract))...)
        return author
    end
end

function setBasicInfo!(abstract::Abstract)::Nothing
    setBasicInfoFromScopus!(abstract)
end

function setCitations!(abstract::Abstract)::Nothing
    abstract.citations = queryScholarCitations(abstract)
end

function setCitationsBasicInfo!(abstract::Abstract)
    for i in length author.abstracts
        set!(author.abstracts[i])
    end

end

"""
    getCitationDates(::Abstract)::Vector{Date}

NOT TESTED
Returns all the dates that the given abstract was cited.
"""
function getCitationDates(abstract::Abstract)::Vector{Date}
    @error "getCitationDates not implemented"
    # Do we have the data?
    if isnothing(abstract.scopus_citations)
        @error "Citations not present for the given abstract"
    end

    return citation_dates
end


