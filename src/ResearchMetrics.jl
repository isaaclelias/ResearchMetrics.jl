"""
Provides functions to bulk query scientific database for authors and analyse their h-indexes.

Issues:
- Scopus API only allows 2 requests/second. This will take forever.

Tasks:
- Get data from output/extern before querying scopus
- Write LOTS of documentation
"""
module ResearchMetrics

using HTTP
using JSON
using TimeSeries
using Dates
using SHA
using ProgressBars


include("secrets.jl")
include("Publication.jl")
include("Prize.jl")
include("Researcher.jl")
include("local.jl")
include("scopus.jl")
include("serpapi.jl")
include("hindex.jl")

end #module
