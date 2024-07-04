sha_length = 20

:wa
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

function scalecurvefinalvalue(timearray, finalvalue::Real)
    y_end = values(timearray[end])[begin]
    y_scaled = (values(timearray)/y_end)*finalvalue
    x = timestamp(timearray)
    timearray_scaled = TimeArray(x, y_scaled)

    return timearray_scaled
end

#=
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
=#

function setpublications!(
    researcher::Researcher,
    keys::Union{Vector{Symbol}, Symbol};

    verbose=false,
    ask_before_batch=true,
    warn_not_found_information=true
)

    error("Non implemented")
    error("Non tested")

    if typeof(keys) == Symbol
        keys = Symbol[keys]
    end
    
    if [:Scopus, :SerpApi] |> arein(keys)
        
    end
end

# COMMIT move it to a misc file
function arein(a::T, b::T) where T<:AbstractVector
    _a = unique(a)
    _b = unique(b)

    # counting principle
    if length(_a) > length(_b)
        return false
    end

    b_contains_all_a = true
    # compare each item from a::Vector{} ...
    for item_a in a
        b_contains_item_a = false
        # with every item from b::Vector
        for item_b in b
            if item_b == item_a
                b_contains_item_a = true
                break
            end
        end
        
        if b_contains_item_a == false
            b_contains_all_a = false
            break
        end
    end

    return b_contains_all_a
end

function export_citation_to_csv(res::Researcher, path::AbstractString)
    pub_title = []
    pub_date = []
    cit_title = []
    cit_date = []

    for pub in publications(res)
        for cit in citations(pub)
            append!(pub_title, title(pub))
            append!(pub_date, date(pub))
            append!(cit_title, title(cit))
            append!(cit_date, date(cit))
        end
    end

    df = DataFrame(
        "PublicationTitle" => pub_title,
        "PublicationDate" => pub_date,
        "CitationTitle" => cit_title,
        "CitationDate" => cit_date,
    )
end

function _parse_success_to_string(success)
    if     success == true;  return "true"
    elseif success == false; return "false"
    else;                    return "nothing"
    end
end

function _parse_authids_to_string(authids)
    if isnothing(authids); return "nothing"; end

    ret = ""
    for authid in authids; ret = ret*" "*authid; end
    ret = ret |> lstrip |> rstrip

    return ret
end

function export_hindex_to_csv(arguments)
  
end

function export_publications_to_csv()

end

function export_citations_to_csv()
  
end
