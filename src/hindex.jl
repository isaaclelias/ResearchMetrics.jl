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

