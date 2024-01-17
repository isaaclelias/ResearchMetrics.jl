# ResearchMetrics

[![Build Status](https://github.com/isaaclelias/ResearchMetrics.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/isaaclelias/ResearchMetrics.jl/actions/workflows/CI.yml?query=branch%3Amain)

A toolbox to gather and analyse research metrics.

## Basic workflow

To evaluate the h-index time evolution for a given researcher, first we need to define our researcher by doing:

```julia
researcher = Researcher("Hommelhoff", # Surname
                        "Universität Erlangen-Nürnberg", # University
                        prizes = [Prize("Gottfried Wilhelm Leibniz Prize", "2022-01-01")]) # Prizes (optional)
```

Now we can use the different information sources to set information on our researcher.

```julia
setScopusAuthorSearch!(researcher)
```

`setScopusAuthorSearch` sets information such as Scopus AuthID and Affiliation ID.

Having these IDs set, we can request another API to provide us the publications under researcher's name. One API that returns this information is Scopus Search.

```julia
setScopusSearch!(author)
```

will include all publications listed in Scopus for that author.

To gather data enough to calculate h-index evolution in time, one should perform

```julia
setScopusAuthorSearch!(researcher)
setScopusSearch!(researcher, progress_bar=true)
mappublications(x -> setScopusAbstractRetrieval!(x), researcher, progress_bar=true)
mappublications(x -> setSerpapiGScholarCite!(x), researcher, progress_bar=true)
mapcitations(x -> setScopusAbstractRetrieval!(x), researcher, progress_bar=true)
```

After that, lets plot it

```julia
function plothindexevolution(researcher::Researcher)
    # What to plot
    indication_date = dateof(prizes(researcher)[1])-Year(2)
    h_index = hindex(researcher)
    fit_start_date = first(findwhen(hindex(researchers[1])[:A] .> 5))
    h_index_before = h_index |> (y -> from(y, fit_start_date)) |> (y->to(y, indication_date))
    h_index_after = from(h_index, indication_date)
    x_h_index_before = float(Dates.value.(timestamp(h_index_before)))
    x_h_index_after = float(Dates.value.(timestamp(h_index_after)))
    y_h_index_before = float(values(h_index_before))
    y_h_index_after = float(values(h_index_after))
    fit_h_index_before = curve_fit(LinearFit, x_h_index_before, y_h_index_before)
    fit_h_index_after = curve_fit(LinearFit, x_h_index_after, y_h_index_after)
    lastname = researcher.lastname
    save_date = Dates.format(now(), "YYYY-mm-dd_HH-MM")
    # Plots
    plot(h_index, linetype=:steppre, label="h-index", title = "$lastname's h-index evolution")
    vline!([dateof(prizes(researcher)[1])-nomination_offset], linestyle=:dash, label = "Indication for prize")
    plot!(x_h_index_before, fit_h_index_before.(x_h_index_before), label="Linear fit before indication")
    plot!(x_h_index_after, fit_h_index_after.(x_h_index_after), label="Linear fit after indication")
    #savefig("output/hindex_$(lastname)_$(save_date).png")
end 
```

![](docs/img/hindex_Hommelhoff_2023-11-02_09-58.png)

## Currently suported API's

The following API's are currently suported.

- Scopus Abstract Retrieval
- Scopus Author Retrieval
- Scopus Author Search
- SerpAPI Google Scholar
- SerpAPI Google Scholar Cite

*NOTE: one must have proper keys to use these API's.* The key can be set with

```julia
setScopusAPIKey(API_KEY)
```

## Installation

```
pgk> add https://github.com/isaaclelias/ResearchMetrics.jl
```


