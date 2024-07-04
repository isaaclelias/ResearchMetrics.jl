"""
    setinfoforhindex!(::Researcher, only_local=false, progress_bar=true)

    Fetches information for researcher's publications and publications that cite the researcher's documents aiming to fullfil the information needed for a H-Index evolution in time plot.

    Steps:
    1. Scopus Author Search performed with the researcher's name and affiliation. Obtain Scopus AuthID and AffiliationID.
    2. Scopus Search performed with the researcher's AuthID. Obtain ScopusIDs for each of the researcher's publications.
    3. Scopus Abstract Retrieval performed with each of the researcher's publication's ScopusID. Obtain publication date.
    4. SerpApi Google Scholar Search performed with each of the researcher's publication's title. Obtain Google Scholar CiteID.
    5. SerpApi Google Scholar Cite performed with each of the researcher's publication's CiteID. Obtain a list of titles for each of the researcher's publications of the documents that cite each publication.
    6. Scopus Search performed with each citing documents' title. Obtain a ScopusID for each citing document.
    7. Scopus Abstract Retrieval performed with each citing document's ScopusID. Obtain publication date for each.
"""
function set_needed_for_hindex_with_scopus_serpapi!(researcher::Researcher; only_local::Bool=false, progress_bar::Bool=true)

    begin
        @info "Retrieving author's data with Scopus Author Search\nRetrieving publications title and Scopus ID"
        set_scopus_author_search!(researcher, only_local=only_local)
        @info "Retrieved with Scopus Author Search" researcher.scopus_firstname researcher.scopus_lastname researcher.scopus_affiliation researcher.scopus_authid researcher.scopus_affiliation_id researcher.scopus_query_nresults
    end

    begin
        @info "Retrieving author's publications list with Scopus Search"
        set_scopus_search!(researcher, progress_bar=progress_bar, only_local=only_local)
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
        mappublications(x -> set_scopus_abstract_retrieval!(x, only_local=only_local), researcher, progress_bar=progress_bar)
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
        mappublications(x->set_serpapi_google_scholar_search!(x, only_local=only_local), researcher, progress_bar=progress_bar)
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
        @info "Retrieving ScopusID for each citing document"
        mapcitations(
            x->setScopusSearch!(x, only_local=only_local),
            researcher,
            progress_bar=progress_bar
        )
    end

    begin
        progress_bar && @info "Retrieving information for each citation using Scopus Abstract Retrieval"
        mapcitations(x -> setScopusAbstractRetrieval!(x, only_local=only_local), researcher, progress_bar=progress_bar)
    end
end
@deprecate setinfoforhindex!(researcher, only_local=false, progress_bar=true) set_needed_for_hindex_with_scopus_serpapi!(researcher, only_local=only_local, progress_bar=progress_bar)


