using HTTP
using JSON
using TimeSeries
using Dates
using SHA

"""
Provides functions to bulk query scientific database for authors and analyse their h-indexes.

Issues:
- Scopus API only allows 2 requests/second. This will take forever.

Tasks:
- Get data from output/extern before querying scopus
- Write LOTS of documentation
"""
module ResearchMetrics

include("secrets.jl")
include("abstract.jl")
include("author.jl")
include("scopus.jl")
include("scholar.jl")
include("hindex.jl")

end #module
