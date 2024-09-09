
function load_wos_report(filepath::AbstractString)
    df = XLSX.readxlsx(filepath)
    return df
end

function parse_citation_count(wos_report_row)::TimeArray
    
end

function publications(wos_report::DataFrame)::TimeArray
    pubs = Vector{Publication}[]

    for row in eachrow(wos_report)
        @show row
        publication_date = 0
        citations_count = 0
        push!(pubs, Publication(publication_date, citations_count))
        break
    end


end

function researcher_info(wos_report)
    name = wos_report["savedrecs"]["A1"]
    n_publications = wos_report["savedrecs"]["B6"]
    n_citations = wos_report["savedrecs"]["B7"] 
    hindex_reported = wos_report["savedrecs"]["B9"]

    return name, n_publications, n_citations, hindex_reported
end

function hevolution_wos_report(filepath)
    wos_report = load_wos_report(filepath)
    @show researcher_info(wos_report)

    #publications(wos_report)

end

