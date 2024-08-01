function main_hevolution()
    settings = ArgParseSettings(
        description = "hevolution (stands for H-Index Evolution) is a web scrapper and metrics calculator for academic data. It supports scrapping Google Scholar (via SerpApi) and Scopus databases. After scrapping the data, the researcher's H-Index is calculated in function of time, and files containing the acquired information are placed in the directory it was called.",
        epilog = "IMPORTANT: Always check if the --name provided returns the profile for the researcher in question in a scholar.google.com query. If it's not the case, provide a --query that does. In this case, --name will be only used to title the plot and the log files.",
        commands_are_required = true,
        version = "0.0.1",
        add_version = true,
        add_help = true
    )

    @add_arg_table! settings begin
        "--name", "-n"
            help = """Name of the researcher in question in the format "FIRSTNAME LASTNAME". """
            #help = "Name of the researcher to be searched for. Provide it using quotes when more than one word is passed. ATTENTION: the name passed should return the researcher profile as the first search result when searched for in Google Scholar. Check for this before using. If needed, the --affiliation option can be used to further narrow down the search."
            required = true
        "--query", "-q"
            help = "Ignore NAME and search Google Scholar using QUERY. NAME is still required to plot."
        "--local-database-only", "-l"
            help = "Run without performing queries to external APIs"
            action = :store_true
        "--prize", "-p"
            help = "Add a vertical line in the plot on the given YEAR with caption PRIZE_NAME"
            nargs = 2
            metavar = ["YEAR", "PRIZE_NAME"]
            action = :append_arg
    end

    parsed_args = parse_args(settings)

    if parsed_args["query"] |> isnothing
        # use the name as query string
        hevolution(
            parsed_args["name"],
            parsed_args["name"],
            parsed_args["local-database-only"],
            parsed_args["prize"]
        )
    else
        # use query as query string
        hevolution(
            parsed_args["name"],
            parsed_args["query"],
            parsed_args["local-database-only"],
            parsed_args["prize"]
        ) 
    end

    return 0 # EXIT POINT
end

function hevolution(
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

function addprizes!(plt, prizes)
    _prizes = _parse_prizes(prizes)
    if length(_prizes) == 0
        return nothing
    end

    for prize in _prizes
        vline!(plt, [dateof(prize)], label=nameof(prize))
    end
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

function _parse_prizes(prizes)
    if length(prizes) == 0
        return nothing
    end

    _prizes = Prize[]
    for prize in prizes
        push!(_prizes, Prize(prize[2], prize[1]))
    end

    return _prizes
end

function format_xticks!(plt)
    @show xticks(plt)
    _xticks_v = xticks(plt)[1][1]
    _xticks_d = xticks(plt)[1][2]

    _xticks_d = _xticks_d .|> Date .|> x->Dates.format(x, "YYYY")

    plot!(plt, xticks=(_xticks_v, _xticks_d))

    return nothing
end
