#=
# This files contains the functions related to the flag --from-wos-report .
=#

#=
# Dates obtained from wos_reports should be always in the format "YYYY", since the citation counts is provided only in that format. Otherwise citations from the "past" would cite publications from the "future".
=#

"""
Load the `wos_report` present in `filepath` as an `XLSX.XLSXFile`.
"""
function load_wos_report(filepath::AbstractString)
    df = XLSX.readxlsx(filepath)
    return df
end

"""
Parses the timespan of publications cointained in the cell "A2" of a wos_report.
"""
function timespan_from_wos_report(wos_report::XLSX.XLSXFile)::Tuple{Date, Date}
    cel = wos_report["savedrecs"]["A2"]
    #should use that, but i'm going with the fast alternative of just counting string indexes instead of regex
    beginning = cel[11:14] |> x->Date(x)
    ending = cel[16:19] |> x->Date(x)

    return (beginning, ending)
end

"""
Very suboptimal way of finding that "E" is the fifth column in an .xlsx file. Can receive a already cached version of the `columns` vector as optional argument.
"""
function find_excel_column_n(column::AbstractString, columns=nothing)
    if isnothing(columns)
        columns = excel_columns_list(max_excel_columns)
    end

    return findall(x->x==column, columns)[1]
end

"""
Return a list with `n_columns` number of elements, containing "A-Z", then "AA-AZ", "BA-BZ", and so on. It's useful to index excel columns, as the fifth element of this list is "E", which is coincidentally the letter for the fifth column in spreadsheet files.
"""
@memoize function excel_columns_list(n_columns=max_excel_columns)
    # please refactor it to a decent form using some kind of ascii table iteration idk
    list_of_columns = String[]
    alphabet = ["", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"] # this is the meme!

    counter_n_columns = 0
    for i in 1:27, j in 2:27
        push!(list_of_columns, alphabet[i]*alphabet[j])
        counter_n_columns = counter_n_columns + 1
        counter_n_columns >= n_columns && break
    end

    return list_of_columns
end

"""
Parses the citation count present in line `i` of the wos_report. By now it assumes that `i` is a valid line.
"""
function citation_count_evol_from_wos_report(wos_report::XLSX.XLSXFile, i::Int)::TimeArray
    wr = wos_report["savedrecs"]
    si = string(i)
    timespan = timespan_from_wos_report(wos_report)
    beginning = timespan[1] |> x->Dates.format(x, "YYYY") |> x->parse(Int, x)
    ending = timespan[2] |> x->Dates.format(x, "YYYY") |> x->parse(Int, x)
    n_years_active = ending - beginning

    dates = Date[]
    citation_count = 0
    citation_counts = Int[]
    ecl = excel_columns_list()
    for j in 22:(22+n_years_active)
        sj = ecl[j]
        ismissing(wr[sj*si]) && break # breaks if the cell is empty on the sheet already
        date = Date(wr[sj*"11"])
        citation_count = citation_count + Int(wr[sj*si])
        push!(dates, date)
        push!(citation_counts, citation_count)
    end

    ta = TimeArray(dates, citation_counts)

    return ta
end

"""
    publications_from_wos_report(wos_report::XLSX.XLSXFile)::Vector{Publication}

Tries to parse the publications contained in the `wos_report`.
"""
function publications_from_wos_report(wos_report::XLSX.XLSXFile)::Vector{Publication}
    wr = wos_report["savedrecs"]
    pubs = Publication[]
    ecl = excel_columns_list()
    start_line = 12
    start_column = 22

    for i in start_line:max_excel_lines
        si = string(i)
        ismissing(wr["A"*si]) && break # break is the line is missing, should mean that the file is over
        pub = Publication()
        pub.wosrep_title               = wr["A"*si]
        pub.wosrep_date                = Date(string(Int(wr["H"*si])), "YYYY")
        pub.wosrep_citation_count_evol = citation_count_evol_from_wos_report(wos_report, i)

        push!(pubs, pub)
    end

    return pubs
end

function researcher_from_wos_report(wos_report::XLSX.XLSXFile)::Researcher
    researcher = Researcher()
    
    researcher.abstracts = publications_from_wos_report(wos_report)
    researcher.wosrep_timespan = timespan_from_wos_report(wos_report)
    researcher.wosrep_name = wos_report["savedrecs"]["A1"]
    researcher.wosrep_hindex = wos_report["savedrecs"]["B9"]
    researcher.wosrep_citation_count = wos_report["savedrecs"]["B7"]
    
    return researcher
end

function hevolution_wos_report(filepath)
    wos_report = load_wos_report(filepath)

    researcher = researcher_from_wos_report(wos_report)
    @show values(researcher.abstracts[2].wosrep_citation_count_evol[end])
    @show researcher.abstracts[2].wosrep_title

    #publications(wos_report)

end

