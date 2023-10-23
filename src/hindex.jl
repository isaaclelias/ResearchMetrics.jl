export setScopusData!, getScopusAuthoredAbstracts, getAuthorsFromCSV, getCitations, popSelfCitations!, getScopusCitingAbstracts, queryID

sha_length = 20
api_query_folder = "resources/extern/"

"""
    saveQuery(query_type::String, query_string::String)::Nothing

Saves the result to disk.
"""
function saveQuery(query_type::String, query_string::String, response::String)::Nothing
    fname = query_type*"_"*Dates.format(now(), "yyyy-mm-dd_HH-MM")*"_"*queryID(query_string)*".json"
    fpath = api_query_folder*fname
    touch(fpath)
    open(fpath, "w") do file
        write(file, response)
        @debug "Query saved to disk" fpath
    end

    return nothing
end

"""
    popSelfCitations!()

NOT TESTED
Pops all papers authored by `author` from the `abstracts`.

Tasks:
- TEST IT
"""
function popSelfCitations!(abstracts::Vector{Publication}, author::Researcher)
    for abstract in abstracts
        if author.scopus_authid in abstract.scopus_authids
            pop!(abstracts, abstract)
        end
    end
end


"""
    calcHIndex(::Vector{Int})::Int

NOT TESTED
Calculates the h-index.

Implementation details:
- GPT generated
"""
function calcHIndex(citation_count::Vector{Int})::Int
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

#=
function _sethindex!(author::Author)::Nothing
    setScopusHIndex!(author)
    return nothing
end
=#

"""
Tasks:
- Better names for the variables please
"""
function _sethindex!(author::Author)::Nothing
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
    author.scopus_hindex = hindex
    
    return nothing
end
@deprecate setHIndex!(author::Author) _sethindex(author)
@deprecate setScopusHIndex!(author::Author) _sethindex!(author)

#=
function setInfoForHIndexEvaluation(author::Author; only_local::Bool=false)::Nothing
    @warn "Not implemented"
    return nothing
end
=#
