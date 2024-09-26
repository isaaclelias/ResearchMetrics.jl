function hevolution_gscholar(
    name::AbstractString,
    query::AbstractString,
    local_only::Bool,
    prizes
)
    prompt_to_set_scopus_key()

    # TODO
    name_log = replace(name, " "=>"") # Remove all the spaces from NAME
    mkpath("results/"*name_log)
    cd("results/"*name_log) # let's do everything inside the researchers folder

    mkpath("resources/extern/") # create folder to store the queries

    # set up logging
    log_path = "logs/hevolution_"*name_log*"_"*Dates.format(now(), "yyyy-mm-dd_HH-MM")*".log"
    mkpath(dirname(log_path))
    touch(log_path)
    log_io = open(log_path, "w+")
    logger = TeeLogger(ConsoleLogger(stdout, Logging.Info),
                       SimpleLogger(log_io, Logging.Debug))
    global_logger(logger)
    @info "Logging" log_path

    researcher = Researcher(; name = name, user_gscholar_query=query)

    @info "Searching Google Scholar Profiles" researcher.name researcher.user_gscholar_query
    set_serpapi_google_scholar_profiles!(researcher)
    @info "Summary for Google Scholar Profiles search" researcher.gscholar_name researcher.gscholar_affiliations researcher.gscholar_link

    @info "Searching Google Scholar Author"
    set_serpapi_google_scholar_author!(researcher, progress_bar=true)#, progress_bar=true)
    n_publications, n_publications_with_date, n_publications_with_cite_id, n_publications_that_failed = summary_set_serpapi_google_scholar_author(researcher)
    @info "Summary for Google Scholar Author search" n_publications n_publications_with_date n_publications_with_cite_id n_publications_that_failed

    @info "Searching Google Scholar Cite"
    set_serpapi_google_scholar_cite_2!(researcher)#, progress_bar=true)
    delete_inconsistent_citations!(researcher)
    n_citations, n_citations_with_date, n_citations_that_failed = summary_set_serpapi_google_scholar_cite(researcher)
    @info "Summary for Google Scholar Cite search" n_citations n_citations_with_date n_citations_that_failed

    plt = plot_hindex(researcher)
    addprizes!(plt, prizes)
    format_xticks!(plt)
    _save_plot(plt)

    df_p = dataframe_publications(researcher)
    CSV.write("publications.csv", df_p)

    df_c = dataframe_citations(researcher)
    CSV.write("citations.csv", df_c)

    cd("..")
    cd("..")
    return researcher
end

function summary_set_serpapi_google_scholar_author(r)
    pub_r = publications(r)

    n_publications = length(pub_r)

    n_publications_with_date = count(
        x->!(isnothing(date(x)) || ismissing(date(x))),
        pub_r
    )
    
    n_publications_with_cite_id = count(
        x->!(isnothing(x.scholar_citesid) || ismissing(x.scholar_citesid)),
        pub_r
    )

    n_publications_that_failed = count(
        x->!(isnothing(x.success_set_serpapi_google_scholar_author) || x.success_set_serpapi_google_scholar_author == true),
        pub_r
    )

    return n_publications, n_publications_with_date, n_publications_with_cite_id, n_publications_that_failed
end

function summary_set_serpapi_google_scholar_cite(r)
    cit_r = citations(r)
    
    n_citations = length(cit_r)

    n_citations_with_date = count(
        x->!(isnothing(date(x)) || ismissing(date(x))),
        cit_r
    )
    
    n_citations_that_failed = count(
        x->!(isnothing(x.success_set_serpapi_google_scholar_cite) || x.success_set_serpapi_google_scholar_cite == true),
        cit_r
    )

    return n_citations, n_citations_with_date, n_citations_that_failed
end

function plot_hindex(r::Researcher)
    hindex_r = hindex(r)
    plt = plot(hindex_r, linetype=:steppre, title=r.name*"'s H-Index evolution", label="H-Index")
    return plt
end

function _save_plot(plt)
    savefig(plt, "plot.png")
end

function wait_for_key(prompt)
  println(stdout, prompt)
	read(stdin, 1);
	while bytesavailable(stdin)>0
      read(stdin, Char)
  end

	return nothing
end

function format_name(r::Researcher)
    nam = r.name
end

