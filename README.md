# ResearchMetrics.jl

Collection of tools to evaluate H-Indexes in respect to time using Google Scholar, Scopus and Web of Science data.

# hevolution

## Instalation

First of all, install [Julia](https://julialang.org/).

That being done, clone this repository to a folder and `cd` into the newly created directory:

```
git clone https://github.com/isaaclelias/ResearchMetrics.jl
cd ResearchMetrics.jl
```

## Using Web of Science Report

To use this approach, one must have the XLSX file provided by Web of Science reporting the number of citations each of the researcher's publications received per year. After that, place the file inside the ResearchMetrics.jl folder and run the following command substituting `NAME`, `YEAR` and `PRIZE_NAME`:

`./hevolution --from-wos-report file.xlsx --name "NAME" --prize YEAR "PRIZE_NAME"`

## Using Google Scholar

Create a file named `Secrets.jl` and include the SerpApi key in the following format:

```
serpapi = "KEY"
```

With the key properly set, just call the program with:

```
./hevolution --name NAME [--prize YEAR PRIZE_NAME]
```

And afterwads the results will be placed inside the `results` folder.
