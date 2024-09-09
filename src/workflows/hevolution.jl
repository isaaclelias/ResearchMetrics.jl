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
        "--from-gscholar"
            action = :store_true
        "--from-scopus-and-gscholar"
            action = :store_true
        "--from-wos-report"
            action = :store_true
        "file"
    end

    parsed_args = parse_args(settings)

    if parsed_args["from-scopus-and-gscholar"]
        println("Please use --from-google-scholar or --from-wos-report, this option is just too bad.")
    elseif parsed_args["from-gscholar"]
        if parsed_args["query"] |> isnothing
            # use the name as query string
            hevolution_gscholar(
                parsed_args["name"],
                parsed_args["name"],
                parsed_args["local-database-only"],
                parsed_args["prize"]
            )
        else
            # use query as query string
            hevolution_gscholar(
                parsed_args["name"],
                parsed_args["query"],
                parsed_args["local-database-only"],
                parsed_args["prize"]
            ) 
        end
    elseif parsed_args["from-wos-report"]
        hevolution_wos_report(parsed_args["file"])
    end
    return 0 # EXIT POINT
end


