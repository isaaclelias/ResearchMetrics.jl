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
@memoize function hindex(author::Researcher)::TimeArray
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

function hindex(df::DataFrame)
     
end

function hindex_evol_from_wos_report(res::Researcher)::TimeArray
    hindexes       = Int[]
    hindexes_dates = Date[]

    # get the h-index for each year in the timespan
    for year in res.wosrep_timespan[1]:Year(1):res.wosrep_timespan[2]
        citation_counts_at_year = Int[]
        # get the citation count for each publication in the given year
        for pub in res.abstracts
            citation_count_at_year = values(to(pub.wosrep_citation_count_evol, year)[end])[begin]
            push!(citation_counts_at_year, citation_count_at_year)
        end

        hindex_at_year = hindex(citation_counts_at_year)
        push!(hindexes, hindex_at_year)
        push!(hindexes_dates, year)
    end

    _hindex_evol = TimeArray(hindexes_dates, hindexes)
end
