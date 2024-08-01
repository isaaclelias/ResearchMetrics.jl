# ResearchMetrics.jl

Fetch science databases and analyse research metrics. The package can fetch data from Scopus and Google Scholar and evaluate the H-Index evolution on time for a given researcher.

# hevolution

## Instalation and usage

First of all, install [Julia](https://julialang.org/).

That being done, clone this repository to a folder and `cd` into the newly created directory:

```
git clone https://github.com/isaaclelias/ResearchMetrics.jl
cd ResearchMetrics.jl
```

Create a file named `Secrets.jl` and include the SerpApi key in the following format:

```
serpapi = "KEY"
```

With the key properly set, just call the program with:

```
./hevolution --name NAME [--prize YEAR PRIZE_NAME]
```

And afterwads the results will be placed inside the `results` folder.
