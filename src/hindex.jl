export setScopusData!, getScopusAuthoredAbstracts, getAuthorsFromCSV, getCitations, popSelfCitations!, getScopusCitingAbstracts, queryID

sha_length = 20
api_query_folder = "resources/extern/"

"""
    calcHIndex(::Vector{Int})::Int

Calculates the h-index.
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
Tasks:
- Better names for the variables please
"""
function hindex(author::Researcher)::TimeArray
    abstracts = author.abstracts
    all_citation_dates = getCitationDates(author) # Getting a list of all publication dates
    hindex_current = 0
    hindex_values = Vector{Int}()
    hindex_dates = Vector{Date}()
    for date in all_citation_dates
        citation_count_per_abstract = Vector{Int}()
        for abstract in abstracts
            if !isnothing(abstract.scopus_citation_count) && length(values(to(abstract.scopus_citation_count, date))) > 0
                push!(citation_count_per_abstract, values(to(abstract.scopus_citation_count, date))[end])
            end
        end
        hindex_at_date = calcHIndex(citation_count_per_abstract)
        if hindex_at_date > hindex_current
            hindex_current = hindex_at_date
            push!(hindex_values, hindex_at_date)
            push!(hindex_dates, date)
        end
    end
    hindex = TimeArray(hindex_dates, hindex_values)
    return hindex
end

