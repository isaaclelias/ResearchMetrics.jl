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

function scalecurvefinalvalue(timearray, finalvalue::Real)
    y_end = values(timearray[end])[begin]
    y_scaled = (values(timearray)/y_end)*finalvalue
    x = timestamp(timearray)
    timearray_scaled = TimeArray(x, y_scaled)

    return timearray_scaled
end

function plothindexevolution(researcher::Researcher; h_index=nothing, scale_final_hindex_to=nothing, indication_offset=Year(2), disconsider_before=nothing, fit_curves_when_hindex_is_higher_than=5)

    # Calculate hindex if not given in function arguments
    if isnothing(h_index)
        h_index = hindex(researcher)
    end

    # Scale the values if the argument for it is given.
    # The result is that the entire curve is scaled, so the final h_index corresponds to the given one
    if scale_final_hindex_to |> !isnothing
        h_index = scalecurvefinalvalue(h_index, scale_final_hindex_to)
    end

    # Chop out papers before a given date
    if disconsider_before |> !isnothing
        h_index = from(h_index, disconsider_before)
    end

    ## Prizes
    if prizes(researcher) |> !isnothing
        
    end

    indication_date = dateof(prizes(researcher)[1])-indication_offset
    fit_start_date = first(findwhen(h_index[:A] .> fit_curves_when_hindex_is_higher_than))
    h_index_before = h_index |> (y -> from(y, fit_start_date)) |> (y->to(y, indication_date))
    h_index_after = from(h_index, indication_date)
    x_h_index_before = float(Dates.value.(timestamp(h_index_before)))
    x_h_index_after = float(Dates.value.(timestamp(h_index_after)))
    y_h_index_before = float(values(h_index_before))
    y_h_index_after = float(values(h_index_after))
    fit_h_index_before = curve_fit(LinearFit, x_h_index_before, y_h_index_before)
    fit_h_index_after = curve_fit(LinearFit, x_h_index_after, y_h_index_after)
    #lastname = uppercasen(wessling.lastname, 1)
    save_date = Dates.format(now(), "YYYY-mm-dd_HH-MM")
    # Plots
    plt_hi = plot(h_index, linetype=:steppre, label="h-index", title = "Wessling's H-Index evolution")
    vline!(plt_hi, [dateof(prizes(researcher)[1])-indication_offset], linestyle=:dash, label = "Indication for Gottfried Wilhelm Leibniz Prize")
    plot!(plt_hi, x_h_index_before, fit_h_index_before.(x_h_index_before), label="Linear fit before indication")
    plot!(plt_hi, x_h_index_after, fit_h_index_after.(x_h_index_after), label="Linear fit after indication")

    plt_ann = plot(grid=false, axiscolor=:white, fg_color_text=:white, showaxis=false, size=(40,10))
    annotate!(plt_ann, [(0/3, 2/2, ("Scopus H-Index: $(scale_final_hindex_to)", 8, :left))])
    annotate!(plt_ann, [(0/3, 1/2, ("Before indication: increase of $(trunc(fit_h_index_before.coefs[2]*365, digits=1)) per year.", 8, :left))])
    annotate!(plt_ann, [(0/3, 0/2, ("After indication: increase of $(trunc(fit_h_index_after.coefs[2]*365, digits=1)) per year.", 8, :left))])
    annotate!(plt_ann, [(0/3, 1/2, ("", 8, :left))])

    @info "used information" x_h_index_before y_h_index_before

    plt = plot(plt_hi, plt_ann, layout=grid(2, 1, heights=(5/6, 1/6)))
    #savefig("output/hindex_$(lastname)_$(save_date).png")

    return plt
end

