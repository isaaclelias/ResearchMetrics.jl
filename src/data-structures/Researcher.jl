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
    # TODO refactor to `user_` to indicate that they where supplied by the user
    firstname::Union{String, Nothing}
    lastname::Union{String, Nothing}
    affiliation::Union{String, Nothing}
    abstracts::Union{Vector{Publication}, Nothing} # refactor to publications, refactor to only Vector{publications}
    prizes::Union{Vector{Prize}, Nothing}

    # Scopus
    scopus_authid::Union{Int, Nothing}
    scopus_affiliation_id::Union{String, Nothing}
    scopus_firstname::Union{String, Nothing}
    scopus_lastname::Union{String, Nothing}
    scopus_affiliation::Union{String, Nothing}
    scopus_query_nresults::Union{String, Nothing}
    scopus_query_string::Union{String, Nothing}
    success_set_scopus_author_search::Union{Bool, Nothing}
    success_set_scopus_search::Union{Bool, Nothing}

    # ORCID
    orcid_id::Union{String, Nothing}

    # Google Scholar
    gscholar_name::Union{String, Nothing}
    gscholar_affiliations::Union{String, Nothing}
    gscholar_author_id::Union{String, Nothing, Missing}
    gscholar_citation_count::Union{Int, Nothing}
    gscholar_link::Union{String, Nothing}
    success_set_serpapi_google_scholar_author::Union{Bool, Nothing}
    success_set_serpapi_google_scholar_cited_by::Union{Bool, Nothing}
    success_set_serpapi_google_scholar_profiles::Union{Bool, Nothing}
    

    # Enforce that `Author` has at least these two fields filled up
    function Researcher(lastname::String, affiliation::String; prizes=nothing)
        author = new(ntuple(x->nothing, fieldcount(Author))...)
        author.lastname = lastname
        author.affiliation = affiliation
        author.prizes = prizes
        return author
    end

    function Researcher(firstname::AbstractString, lastname::AbstractString, affiliation::AbstractString; prizes=nothing)
        author = new(ntuple(x->nothing, fieldcount(Author))...)
        author.firstname = firstname
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

function dataframe_citations(res::Researcher)
    # what do I need to know to evaluate why there's missing data for the hindex?
    pub_title = []
    pub_date = []
    pub_link = []
    pub_scopus_id = []
    pub_scopus_authids = []
    cit_title = []
    cit_date = []
    cit_gscholar_authids = []
    pub_success_set_scopus_abstract_retrieval = []
    pub_success_set_serpapi_google_scholar_search = []
    pub_success_set_serpapi_google_scholar_cite = []
    cit_success_set_scopus_search = []
    cit_success_set_scopus_abstract_retrieval = []

    for pub in publications(res)
        @show "passei por aqui"
        for cit in citations(pub)
            append!(pub_title, title(pub))
            append!(pub_date, date(pub))
            append!(pub_scopus_id,
                    pub.scopus_scopusid)
            append!(pub_scopus_authids,
                    _parse_authids_to_string(pub.scopus_authids))
            append!(pub_link, link(pub))
            append!(pub_success_set_scopus_abstract_retrieval,
                    _parse_success_to_string(pub.success_set_scopus_abstract_retrieval))
            append!(pub_success_set_serpapi_google_scholar_search,
                    _parse_success_to_string(pub.success_set_serpapi_google_scholar_search))
            append!(pub_success_set_serpapi_google_scholar_cite,
                    _parse_success_to_string(pub.success_set_serpapi_google_scholar_cite))
            append!(cit_title, title(cit))
            append!(cit_date, date(cit))
            append!(cit_gscholar_authids, cit.gscholar_authids)
            append!(cit_success_set_scopus_search, 
                    cit.success_set_scopus_search)
            append!(cit_success_set_scopus_abstract_retrieval,
                    cit.success_set_scopus_abstract_retrieval)
            @show "passei por aqui também"
        end
    end

    df = Dict(
        "PublicationTitle" => pub_title,
        "PublicationDate" => pub_date,
        "PublicationLink" => pub_link,
        "PublicationScopusId" => pub_scopus_id,
        "PublicationScopusAuthorIds" => pub_scopus_authids,
        "CitationTitle" => cit_title,
        "CitationDate" => cit_date,
        "PublicantionSuccededScopusAbstractRetrieval" => pub_success_set_scopus_abstract_retrieval,
        "PublicationSuccededSerpapiGoogleScholarSearch" => pub_success_set_serpapi_google_scholar_search,
        "PublicationSuccededSerpapiGoogleScholarCite" => pub_success_set_serpapi_google_scholar_cite,
        "CitationSuccededGoogleScholarAuthorIds" => cit_gscholar_authids,
        "CitationSuccededScopusSearch" => cit_success_set_scopus_search,
        "CitationSuccededScopusAbstractRetrieval" => cit_success_set_scopus_abstract_retrieval
    )

    return df
end

function dataframe_publications(res::Researcher)
    # what do I need to know to evaluate why there's missing data for the hindex?
    pub_title = []
    pub_date = []
    pub_link = []

    for pub in publications(res)
        @show "passei por aqui"
        push!(pub_title, title(pub))
        push!(pub_date, date(pub))
        push!(pub_link, link(pub))
    end

    df = Dict(
        "PublicationTitle" => pub_title,
        "PublicationDate" => pub_date,
        "PublicationLink" => pub_link,
    )# |> x->DataFrame(x)

    return df
end

function name(r::Researcher)
    if  !any(isnothing.([r.scopus_firstname, r.scopus_lastname]))
        return r.scopus_firstname*" "*r.scopus_lastname
    elseif !isnothing(r.gscholar_name);
        return r.gscholar_name
    elseif !any(isnothing.([r.firstname, r.lastname]))
        return r.firstname*" "*r.lastname
    elseif isnothing(r.lastname)
        return r.lastname
    else
        throw(UndefRefError())
    end
end
