sha_length = 20
api_query_folder = "resources/extern/"

"""
    hindex(::Vector{Int})::Int

Calculates the h-index of an array of integers.
"""
function hindex(citation_count::Vector{Int})::Int
    n = length(citation_count)
    sorted_citations = sort(citation_count, rev=true)
    h_index = 0
    for i in 1:n
        if sorted_citations[i] >= i
            h_index = i
        else
            break
        end
    end
    return h_index
end

"""
    hindex(::Researcher)::TimeArray

Returns a TimeArray with the h-index of the given researcher in function of time.
"""
function hindex(author::Researcher)::TimeArray
    abstracts = publications(author)
    all_citation_dates = citationdates(author) # Getting a list of all publication dates
    hindex_current = 0
    hindex_values = Vector{Int}()
    hindex_dates = Vector{Date}()
    for date in all_citation_dates
        citation_count_per_abstract = Vector{Int}()
        for abstract in abstracts
            if length(values(to(citationcount(abstract), date))) > 0
                abstract_citation_count_at_date = values(to(citationcount(abstract), date))[end]
                push!(citation_count_per_abstract, abstract_citation_count_at_date)
            end
        end
        hindex_at_date = hindex(citation_count_per_abstract)
        if hindex_at_date > hindex_current
            hindex_current = hindex_at_date
            push!(hindex_values, hindex_at_date)
            push!(hindex_dates, date)
        end
    end
    h_index = TimeArray(hindex_dates, hindex_values)
    return h_index
end

"""
    setinfoforhindex!(::Researcher, only_local=false, progress_bar=true)
"""
function setinfoforhindex!(researcher::Researcher; only_local=false, progress_bar=true)

    begin
        @info "Retrieving author's data with Scopus Author Search\nRetrieving publications title and Scopus ID"
        setScopusAuthorSearch!(researcher, only_local=only_local)
        @info "Retrieved with Scopus Author Search" researcher.scopus_firstname researcher.scopus_lastname researcher.scopus_affiliation researcher.scopus_authid researcher.scopus_affiliation_id researcher.scopus_query_nresults
    end

    begin
        @info "Retrieving author's publications list with Scopus Search"
        setScopusSearch!(researcher, progress_bar=progress_bar, only_local=only_local)
        # evaluate how it went
        n_publications = length(publications(researcher))
        n_publications_with_scopusid = count(
            x->!(isnothing(x.scopus_scopusid) || ismissing(x.scopus_scopusid)),
            publications(researcher)
        )
        @info "Retrieved with Scopus Search" n_publications n_publications_with_scopusid
    end

    begin
        @info "Retrieving data for each publication with Scopus Abstract Retrieval\nRetrieves Scopus ID's and Auth ID's"
        mappublications(x -> setScopusAbstractRetrieval!(x, only_local=only_local), researcher, progress_bar=progress_bar)
        n_pubs_with_date = count(x->!isnothing(x.date_pub), publications(researcher))
        n_pubs_with_authid = count(x->!isnothing(x.scopus_authids), publications(researcher))
        #=
        length_before_non_authored_removal = length(publications(researcher))
        deleteat!(researcher.abstracts, map(x-> (!isnothing(x) && in(string(researcher.scopus_authid)), x.scopus_authids), researcher.abstracts))
        length_after_non_authored_removal = length(publications(researcher))
        n_removed_publications = length_before_non_authored_removal = length_after_non_authored_removal
        =#
        @info "Retrieved information for author's publications with Scopus Abstract Retrieval" n_pubs_with_date n_pubs_with_authid n_publications_with_scopusid 
    end

    begin
        @info "Retrieving Google Scholar Cite ID with SerpApi Scholar Search"
        mappublications(x->setSerpapiGScholarSearch!(x, only_local=only_local), researcher, progress_bar=progress_bar)
        n_cits_with_gscholarcitesid = count(x->!(isnothing(x)  || ismissing(x)), citations(researcher))
        n_cits_with_gscholarcitesid_nothing = count(x->!isnothing(x), citations(researcher))
        @info "Retrieved with Google Scholar Search" length(citations(researcher)) n_cits_with_gscholarcitesid n_cits_with_gscholarcitesid_nothing
    end
    
    begin
        @info "Retrieving list of citations for each publication with SerpApi Google Scholar Cite"
        mappublications(x -> setSerpapiGScholarCite!(x, only_local=only_local), researcher, progress_bar=progress_bar)
        n_pub_with_scholarcitesid = count(x->!isnothing(x.scholar_citesid), publications(researcher))
        @info "Retrieved data from SerpApi Google Scholar Cite" n_pub_with_scholarcitesid
    end

    begin
        progress_bar && @info "Retrieving information for each citation using Scopus Abstract Retrieval"
        mapcitations(x -> setScopusAbstractRetrieval!(x, only_local=only_local), researcher, progress_bar=progress_bar)
    end
end
